#!/usr/bin/env python3
"""Keep shell startup quiet while preserving manual word-of-the-day calls."""

from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

from test_completions import BASH, PROMPT, ROOT, Shell


class StartupCardTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="wotd-startup-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)

    def shell(self, array=False, repeated_source=False, trailing_separator=False):
        rcfile = self.directory / "rc.bash"
        hook = shlex.quote(str(ROOT / "customizations/wotd.bash"))
        configuration = r'''
unset WOTD_SHOWN_TTY
wotd() { printf 'CARD\n'; }
_existing_hook() { printf 'EXISTING\n'; }
PS1='__TEST_PROMPT__> '
'''
        command = "_existing_hook;" if trailing_separator else "_existing_hook"
        configuration += ("PROMPT_COMMAND=(_existing_hook)\n" if array else
                          f"PROMPT_COMMAND={shlex.quote(command)}\n")
        # Startup discovers optional customization files rather than requiring one.
        source = f"if [[ -f {hook} ]]; then source {hook}; fi\n"
        configuration += source
        if repeated_source:
            configuration += source
        configuration += "printf 'STARTUP_FINISHED\\n'\n"
        rcfile.write_text(configuration)
        shell = Shell(rcfile, self.directory)
        self.addCleanup(shell.close)
        return shell

    def test_startup_does_not_show_a_card_or_change_existing_prompt_hooks(self):
        for array in (False, True):
            with self.subTest(array=array):
                output = self.shell(array=array).startup_output
                self.assertNotIn(b"CARD", output)
                self.assertLess(output.index(b"STARTUP_FINISHED"), output.index(b"EXISTING"))
                self.assertLess(output.index(b"EXISTING"), output.index(PROMPT))

    def test_a_trailing_prompt_separator_is_preserved(self):
        output = self.shell(trailing_separator=True).startup_output
        self.assertNotIn(b"syntax error", output)
        self.assertNotIn(b"CARD", output)
        self.assertIn(b"EXISTING", output)

    def test_later_prompts_do_not_show_a_card(self):
        shell = self.shell()
        self.assertNotIn(b"CARD", shell.startup_output)
        self.assertNotIn(b"CARD", shell.run("true"))

    def test_manual_wotd_calls_still_work(self):
        shell = self.shell()
        self.assertNotIn(b"CARD", shell.startup_output)
        self.assertEqual(shell.run("wotd").count(b"CARD\r\n"), 1)

    def test_non_terminal_output_preserves_the_prompt_command(self):
        hook = shlex.quote(str(ROOT / "customizations/wotd.bash"))
        result = subprocess.run(
            [BASH, "--noprofile", "--norc", "-ic",
             "PROMPT_COMMAND=existing; wotd() { printf 'CARD'; }; "
             f"if [[ -f {hook} ]]; then source {hook}; fi; "
             "printf '%s' \"$PROMPT_COMMAND\""],
            capture_output=True, text=True, timeout=10, check=True)
        self.assertEqual(result.stdout, "existing")

    def test_repeated_sourcing_does_not_show_a_card(self):
        for array in (False, True):
            with self.subTest(array=array):
                shell = self.shell(array=array, repeated_source=True)
                self.assertNotIn(b"CARD", shell.startup_output)


if __name__ == "__main__":
    unittest.main()
