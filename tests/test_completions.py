#!/usr/bin/env python3
"""Exercise the first completion request through an interactive Bash terminal."""

import errno
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import signal
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")
PROMPT = b"__TEST_PROMPT__> "


class Shell:
    def __init__(self, rcfile, directory):
        environment = os.environ.copy()
        environment.update(HOME=str(directory), HISTFILE="/dev/null",
                           INPUTRC="/dev/null", TERM="xterm-256color")
        environment.pop("BASH_ENV", None)
        environment.pop("SHELLOPTS", None)
        self.pid, self.terminal = pty.fork()
        if self.pid == 0:
            os.chdir(directory)
            os.execve(BASH, [BASH, "--noprofile", "--rcfile", str(rcfile), "-i"], environment)
        self.received = b""
        try:
            self.read_until(PROMPT)
        except Exception:
            self.close()
            raise

    def read_until(self, marker, timeout=10):
        deadline = time.monotonic() + timeout
        while marker not in self.received and time.monotonic() < deadline:
            readable, _, _ = select.select([self.terminal], [], [], 0.1)
            if readable:
                try:
                    chunk = os.read(self.terminal, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                self.received += chunk
        if marker not in self.received:
            raise AssertionError(f"Missing {marker!r}; terminal output: {self.received!r}")
        end = self.received.index(marker) + len(marker)
        result, self.received = self.received[:end], self.received[end:]
        return result

    def run(self, command):
        os.write(self.terminal, command.encode() + b"; printf '\\036COMMAND_DONE\\037'\n")
        result = self.read_until(b"\x1eCOMMAND_DONE\x1f")
        self.read_until(PROMPT)
        return result

    def complete(self, line, key=b"\t"):
        os.write(self.terminal, line.encode() + key + b"\x07")
        result = self.read_until(b"\x1f")
        os.write(self.terminal, b"\x15")
        return result.split(b"\x1eLINE:")[-1].removesuffix(b"\x1f").decode()

    def close(self):
        try:
            os.write(self.terminal, b"\x15exit\n")
        except OSError:
            pass
        # macOS can hold a process in terminal teardown until output is drained.
        for _ in range(2):
            deadline = time.monotonic() + 2
            while time.monotonic() < deadline:
                if select.select([self.terminal], [], [], 0.05)[0]:
                    try:
                        os.read(self.terminal, 65536)
                    except OSError:
                        pass
                pid, _ = os.waitpid(self.pid, os.WNOHANG)
                if pid:
                    os.close(self.terminal)
                    return
            os.killpg(self.pid, signal.SIGKILL)
        raise AssertionError("Test shell did not exit")


class CompletionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="bash-completions-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.log = self.directory / "loads"
        self.core = self.directory / "core.bash"
        self.fuzzy = self.directory / "fuzzy.bash"
        self.core.write_text('''
BASH_COMPLETION_VERSINFO=(test)
printf 'core\\n' >>"$HOME/loads"
_fixture_complete() { COMPREPLY=(completed); }
complete -F _fixture_complete probe
''')
        self.fuzzy.write_text('''
[[ ${BASH_COMPLETION_VERSINFO[0]} == test ]] || return 1
printf 'fzf\\n' >>"$HOME/loads"
_fixture_fuzzy() { COMPREPLY=(selected); }
complete -F _fixture_fuzzy fuzzy
''')

    def shell(self, mode="emacs", real=False, missing=False):
        rcfile = self.directory / "rc.bash"
        scripts = ["functions/_exists.bash", "customizations/completions.bash"]
        if real:
            scripts.extend(["customizations/fzf.bash", "aliases"])
        configuration = "\n".join(f"source {shlex.quote(str(ROOT / path))}" for path in scripts)
        if real:
            # In a real shell, deferred aliases exist before the first Tab press.
            configuration += "\n_deferred_aliases"
        if not real:
            core = self.directory / "missing" if missing else self.core
            fuzzy = self.directory / "missing" if missing else self.fuzzy
            configuration += f"\n_bashrc_completion_file={shlex.quote(str(core))}"
            configuration += f"\n_bashrc_fzf_completion_file={shlex.quote(str(fuzzy))}"
        configuration += f"\nset -o {mode}\n"
        configuration += r'''
set -o noclobber
PROMPT_COMMAND=
PS1='__TEST_PROMPT__> '
_report_line() { printf '\036LINE:%s\037' "$READLINE_LINE"; }
bind -m emacs-standard -x '"\C-g": _report_line'
bind -m vi-insert -x '"\C-g": _report_line'
'''
        rcfile.write_text(configuration)
        shell = Shell(rcfile, self.directory)
        self.addCleanup(shell.close)
        return shell

    def test_completion_libraries_are_not_loaded_during_startup(self):
        shell = self.shell()
        output = shell.run("printf '\\036CORE:%s\\037' \"${BASH_COMPLETION_VERSINFO:-absent}\"")
        self.assertIn(b"\x1eCORE:absent\x1f", output)
        self.assertFalse(self.log.exists())

    def test_the_first_tab_completes_in_both_editing_modes(self):
        for mode in ("emacs", "vi"):
            with self.subTest(mode=mode):
                self.log.unlink(missing_ok=True)
                shell = self.shell(mode=mode)
                self.assertEqual(shell.complete("probe com"), "probe completed ")
                self.assertEqual(self.log.read_text(), "core\nfzf\n")
                self.assertEqual(shell.complete("probe com"), "probe completed ")
                self.assertEqual(self.log.read_text(), "core\nfzf\n")

    def test_fuzzy_handlers_are_available_on_the_first_request(self):
        shell = self.shell()
        self.assertEqual(shell.complete("fuzzy sel"), "fuzzy selected ")
        self.assertEqual(self.log.read_text(), "core\nfzf\n")

    def test_missing_optional_packages_preserve_filename_completion(self):
        (self.directory / "fixture-file").touch()
        shell = self.shell(missing=True)
        self.assertEqual(shell.complete("cat fixture-f"), "cat fixture-file ")
        self.assertEqual(shell.complete("cat fixture-f"), "cat fixture-file ")

    def test_existing_command_handlers_work_without_loading_libraries(self):
        shell = self.shell()
        shell.run("complete -W already existing")
        self.assertEqual(shell.complete("existing al"), "existing already ")
        self.assertFalse(self.log.exists())

    def require_installed_completion_packages(self):
        if sys.platform == "darwin":
            core = Path("/opt/homebrew/etc/profile.d/bash_completion.sh")
            fuzzy = Path("/opt/homebrew/opt/fzf/shell/completion.bash")
        else:
            core = Path("/usr/share/bash-completion/bash_completion")
            fuzzy = Path("/usr/share/fzf/completion.bash")
        if not core.is_file() or not fuzzy.is_file():
            self.skipTest("bash-completion and fzf must be installed for integration tests")

    def test_installed_git_completion_works_on_the_first_tab(self):
        self.require_installed_completion_packages()
        shell = self.shell(real=True)
        before = shell.run("bind -m emacs-standard -X")
        self.assertIn(b"fzf-file-widget", before)
        self.assertIn(b"__fzf_history__", before)
        self.assertEqual(shell.complete("git checkou"), "git checkout ")
        after = shell.run("complete -p git; printf '\\036LOADER:%s\\037' \"$_fzf_completion_loader\"")
        self.assertIn(b"_fzf_path_completion", after)
        self.assertRegex(after, b"\x1eLOADER:(_comp_load|__load_completion|_completion_loader)\x1f")

    def test_fzf_file_binding_works_before_completion_libraries_load(self):
        self.require_installed_completion_packages()
        shell = self.shell(real=True)
        shell.run("fzf() { printf '%s\\n' fixture-file; }")
        self.assertEqual(shell.complete("cat ", key=b"\x14"), "cat fixture-file ")
        state = shell.run("printf '\\036CORE:%s\\037' \"${BASH_COMPLETION_VERSINFO:-absent}\"")
        self.assertIn(b"\x1eCORE:absent\x1f", state)

    def test_installed_fuzzy_path_completion_works_on_the_first_tab(self):
        self.require_installed_completion_packages()
        shell = self.shell(real=True)
        shell.run("_fzf_comprun() { printf '%s\\n' fixture-file; }; "
                  "_fzf_compgen_path() { printf '%s\\n' fixture-file; }")
        self.assertEqual(shell.complete("cat **"), "cat fixture-file ")


if __name__ == "__main__":
    unittest.main()
