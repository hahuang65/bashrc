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
FZF = shutil.which("fzf")


class DirectoryPickerTests(unittest.TestCase):
    def candidates(self, directory, home):
        environment = os.environ.copy()
        environment["HOME"] = str(home)
        environment.pop("BASH_ENV", None)
        environment.pop("FZF_ALT_C_COMMAND", None)
        result = subprocess.run(
            [BASH, "--noprofile", "--norc", "-c", '''
OSTYPE=test
source "$1"
bash --noprofile --norc -c "${FZF_ALT_C_COMMAND:?Alt+C needs filtered candidates}"
''', "bash", str(ROOT / "customizations/fzf.bash")],
            cwd=directory, env=environment, capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return set(result.stdout.splitlines())

    def test_alt_c_keeps_config_dotfiles_and_projects_but_prunes_clutter(self):
        with tempfile.TemporaryDirectory(prefix="fzf directories ") as temporary:
            directory = Path(temporary)
            for path in (
                "projects/My App/src", ".config/nvim/lua",
                ".dotfiles/bashrc/customizations", ".dotfiles/.git/objects",
                ".dotfiles/node_modules/package",
                ".git/objects", ".local/share", ".cache/downloads",
                "projects/.hidden/nested", ".config/.hidden/nested",
                "projects/node_modules/package", "projects/__pycache__/nested",
                "projects/cache/nested", "projects/Caches/nested",
                ".config/nvim/cache/nested", "Hoth/bash/archive",
                "Library/Application Support/Firefox/Profiles/default/storage",
                "Library/Application Support/Dash/DocSets/Bash",
                "Library/Application Support/cache/nested",
                "Library/Preferences/nested", "Library/Developer/nested",
                "projects/Library/ordinary",
            ):
                (directory / path).mkdir(parents=True, exist_ok=True)
            (directory / "projects/README").touch()
            self.assertEqual(self.candidates(directory, directory), {
                "./projects", "./projects/My App", "./projects/My App/src",
                "./.config", "./.config/nvim", "./.config/nvim/lua",
                "./.dotfiles", "./.dotfiles/bashrc",
                "./.dotfiles/bashrc/customizations",
                "./Library", "./Library/Application Support",
                "./Library/Application Support/Firefox",
                "./Library/Application Support/Dash",
                "./projects/Library", "./projects/Library/ordinary",
            })

    def test_library_limits_apply_when_search_starts_inside_library(self):
        with tempfile.TemporaryDirectory(prefix="fzf library ") as temporary:
            home = Path(temporary)
            library = home / "Library"
            support = library / "Application Support"
            app = support / "Firefox"
            (app / "Profiles/default/storage").mkdir(parents=True)
            preferences = library / "Preferences"
            (preferences / "nested").mkdir(parents=True)
            for directory, expected in (
                (library, {"./Application Support", "./Application Support/Firefox"}),
                (support, {"./Firefox"}), (app, set()), (preferences, set()),
            ):
                with self.subTest(directory=directory):
                    self.assertEqual(self.candidates(directory, home), expected)

    def test_library_limits_apply_through_a_differently_named_symlink(self):
        with tempfile.TemporaryDirectory(prefix="fzf library alias ") as temporary:
            home = Path(temporary)
            library = home / "Library"
            (library / "Application Support/Firefox/Profiles/default").mkdir(parents=True)
            (library / "Preferences/nested").mkdir(parents=True)
            alias = home / "App data"
            alias.symlink_to(library, target_is_directory=True)
            self.assertEqual(self.candidates(home, home), {
                f"./{name}{suffix}"
                for name in ("Library", "App data")
                for suffix in ("", "/Application Support", "/Application Support/Firefox")
            })
            self.assertEqual(self.candidates(alias, home), {
                "./Application Support", "./Application Support/Firefox",
            })

    def test_library_limits_apply_to_aliases_of_descendants(self):
        with tempfile.TemporaryDirectory(prefix="fzf descendant aliases ") as temporary:
            home = Path(temporary)
            library = home / "Library"
            support = library / "Application Support"
            app = support / "Firefox"
            deep = app / "Profiles/default"
            deep.mkdir(parents=True)
            preferences = library / "Preferences"
            (preferences / "nested").mkdir(parents=True)
            project = home / "project"
            project.mkdir()
            for name, target in (
                ("PreferencesLink", preferences), ("SupportLink", support),
                ("FirefoxLink", app), ("DeepLink", deep),
            ):
                (project / name).symlink_to(target, target_is_directory=True)
            (project / "Library/ordinary").mkdir(parents=True)
            self.assertEqual(self.candidates(project, home), {
                "./SupportLink", "./SupportLink/Firefox", "./FirefoxLink",
                "./Library", "./Library/ordinary",
            })

    def test_root_origin_preserves_library_limits(self):
        with tempfile.TemporaryDirectory(prefix="fzf root fixture ") as temporary:
            root = Path(temporary)
            library = root / "Users/example/Library"
            (library / "Application Support/Firefox/Profiles/default").mkdir(parents=True)
            (library / "Preferences/nested").mkdir(parents=True)
            environment = os.environ.copy()
            environment.pop("BASH_ENV", None)
            # Seed the physical traversal at / while reading only this fixture.
            result = subprocess.run(
                [BASH, "--noprofile", "--norc", "-c", r'''
OSTYPE=test
source "$1"
shopt -s dotglob nullglob
library=/Users/example/Library
support="$library/Application Support"
newline=$'\n'
_bashrc_fzf_walk . / -1 "$newline"
''', "bash", str(ROOT / "customizations/fzf.bash")],
                cwd=root, env=environment, capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(set(result.stdout.splitlines()), {
                "./Users", "./Users/example", "./Users/example/Library",
                "./Users/example/Library/Application Support",
                "./Users/example/Library/Application Support/Firefox",
            })

    def test_unrelated_symlinks_work_without_following_cycles(self):
        with tempfile.TemporaryDirectory(prefix="fzf safe aliases ") as temporary:
            home = Path(temporary)
            target = home / "projects/alpha"
            (target / "src").mkdir(parents=True)
            (home / "Shortcut").symlink_to(target, target_is_directory=True)
            (target / "Back").symlink_to(home, target_is_directory=True)
            self.assertEqual(self.candidates(home, home), {
                "./projects", "./projects/alpha", "./projects/alpha/src",
                "./Shortcut", "./Shortcut/src",
            })

    def test_missing_library_or_application_support_is_safe(self):
        with tempfile.TemporaryDirectory(prefix="fzf missing library ") as temporary:
            home = Path(temporary)
            (home / "projects/bash").mkdir(parents=True)
            expected = {"./projects", "./projects/bash"}
            self.assertEqual(self.candidates(home, home), expected)
            library = home / "Library"
            (library / "Preferences/nested").mkdir(parents=True)
            self.assertEqual(self.candidates(home, home), expected | {"./Library"})
            self.assertEqual(self.candidates(library, home), set())

    @unittest.skipUnless(FZF, "fzf must be installed to test matching")
    def test_alt_c_fuzzy_matches_across_full_paths(self):
        environment = os.environ.copy()
        for name in ("BASH_ENV", "FZF_DEFAULT_OPTS_FILE"):
            environment.pop(name, None)
        result = subprocess.run(
            [BASH, "--noprofile", "--norc", "-c", '''
OSTYPE=test
source "$1"
FZF_DEFAULT_OPTS="$FZF_ALT_C_OPTS" "$2" --scheme=path --filter=bsh
''', "bash", str(ROOT / "customizations/fzf.bash"), FZF],
            input="./projects/bash/archive\n./.config/bash/completions\n"
                  "./.dotfiles/bashrc\n./projects/My bash tools\n./projects/other\n",
            env=environment, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(set(result.stdout.splitlines()), {
            "./projects/bash/archive", "./.config/bash/completions",
            "./.dotfiles/bashrc", "./projects/My bash tools",
        })


if __name__ == "__main__":
    unittest.main()
