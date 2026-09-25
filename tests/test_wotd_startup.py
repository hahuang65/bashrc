#!/usr/bin/env python3
"""Verify the startup card is the final output before the first prompt."""

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

    def shell(self, array=False, already_shown=False, repeated_source=False,
              trailing_separator=False):
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
        if already_shown:
            configuration += 'export WOTD_SHOWN_TTY="$(tty)"\n'
        configuration += f"source {hook}\n"
        if repeated_source:
            configuration += f"source {hook}\n"
        configuration += "printf 'STARTUP_FINISHED\\n'\n"
        rcfile.write_text(configuration)
        shell = Shell(rcfile, self.directory)
        self.addCleanup(shell.close)
        return shell

    def test_card_follows_all_startup_and_existing_prompt_hooks(self):
        for array in (False, True):
            with self.subTest(array=array):
                output = self.shell(array=array).startup_output
                self.assertLess(output.index(b"STARTUP_FINISHED"), output.index(b"EXISTING"))
                self.assertLess(output.index(b"EXISTING"), output.index(b"CARD"))
                self.assertIn(b"CARD\r\n", output)
                self.assertLess(output.index(b"CARD"), output.index(PROMPT))

    def test_a_trailing_prompt_separator_is_valid(self):
        output = self.shell(trailing_separator=True).startup_output
        self.assertNotIn(b"syntax error", output)
        self.assertLess(output.index(b"EXISTING"), output.index(b"CARD"))

    def test_card_is_not_repeated_on_later_prompts(self):
        shell = self.shell()
        self.assertEqual(shell.startup_output.count(b"CARD"), 1)
        self.assertNotIn(b"CARD", shell.run("true"))

    def test_an_existing_terminal_marker_suppresses_the_card(self):
        shell = self.shell(already_shown=True)
        self.assertNotIn(b"CARD", shell.startup_output)
        self.assertIn(b"EXISTING", shell.startup_output)

    def test_non_terminal_output_does_not_register_or_print_a_card(self):
        hook = shlex.quote(str(ROOT / "customizations/wotd.bash"))
        result = subprocess.run(
            [BASH, "--noprofile", "--norc", "-ic",
             "PROMPT_COMMAND=existing; wotd() { printf 'CARD'; }; "
             f"source {hook}; printf '%s' \"$PROMPT_COMMAND\""],
            capture_output=True, text=True, timeout=10, check=True)
        self.assertEqual(result.stdout, "existing")

    def test_sourcing_twice_does_not_repeat_the_card(self):
        for array in (False, True):
            with self.subTest(array=array):
                shell = self.shell(array=array, repeated_source=True)
                self.assertEqual(shell.startup_output.count(b"CARD"), 1)


if __name__ == "__main__":
    unittest.main()
