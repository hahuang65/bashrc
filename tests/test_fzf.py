#!/usr/bin/env python3
"""Check the directory candidates supplied to fzf's Alt+C picker."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")


class DirectoryPickerTests(unittest.TestCase):
    def test_alt_c_keeps_config_and_projects_but_prunes_clutter(self):
        with tempfile.TemporaryDirectory(prefix="fzf directories ") as temporary:
            directory = Path(temporary)
            for path in (
                "projects/My App/src", ".config/nvim/lua",
                ".git/objects", ".local/share", ".cache/downloads",
                "projects/.hidden/nested", ".config/.hidden/nested",
                "projects/node_modules/package", "projects/__pycache__/nested",
                "projects/cache/nested", "projects/Caches/nested",
                ".config/nvim/cache/nested",
            ):
                (directory / path).mkdir(parents=True, exist_ok=True)
            (directory / "projects/README").touch()
            environment = os.environ.copy()
            environment.pop("BASH_ENV", None)
            environment.pop("FZF_ALT_C_COMMAND", None)
            result = subprocess.run(
                [BASH, "--noprofile", "--norc", "-c", '''
OSTYPE=test
source "$1"
bash --noprofile --norc -c "${FZF_ALT_C_COMMAND:?Alt+C needs filtered candidates}"
''', "bash", str(ROOT / "customizations/fzf.bash")],
                cwd=directory, env=environment, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(set(result.stdout.splitlines()), {
                "./projects", "./projects/My App", "./projects/My App/src",
                "./.config", "./.config/nvim", "./.config/nvim/lua",
            })


if __name__ == "__main__":
    unittest.main()
