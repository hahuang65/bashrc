# Research: Bashrc Startup Speed Optimization

## Baseline

Total startup time: **~0.5s** (measured 0.505s, 0.516s, 0.528s across 3 runs).

### Per-file breakdown (from BENCHMARK=1)

| File | Time (s) | Notes |
|------|----------|-------|
| `mise.bash` | 0.201 | `eval "$(mise activate bash)"` — fork + eval |
| `aliases` | 0.170 | 11+ `hash` lookups via `exists`/`alias_available` |
| `completions.bash` | 0.060 | bash-completion@2 alone takes 0.179s standalone |
| `direnv.bash` | 0.045 | `eval "$(direnv hook bash)"` — fork + eval |
| `fzf.bash` | 0.036 | Sources 2 files (completion + key-bindings) |
| `grep.bash` | 0.035 | 2x `$(uname)` subshell forks |
| `darwin.bash` | 0.021 | 1x `$(uname)` subshell fork |
| `linux.bash` | 0.016 | 1x `$(uname)` subshell fork |
| Everything else | ~0.003 | Negligible |

## Architecture

```
bash_profile → bashrc → initialize()
  ├── PATH setup
  ├── ~/.secrets.sh
  ├── functions/_*.bash (helpers like `exists`)
  ├── functions/[!_]*.bash (diff, marks, psk, pss, sshs)
  ├── aliases
  ├── customizations/*.bash (excluding direnv.bash)
  │   ├── blesh.bash (guarded by ENABLE_BLESH=1, no-op normally)
  │   ├── claude.bash (just exports ENABLE_LSP_TOOL=1)
  │   ├── colors.bash (just exports CLICOLOR=1)
  │   ├── completions.bash (bash-completion@2 + aws_completer + bind)
  │   ├── darwin.bash (PATH + SSH_AUTH_SOCK, guarded by uname)
  │   ├── editor.bash (exists nvim check, exports EDITOR/VISUAL)
  │   ├── eof.bash (set -o ignoreeof)
  │   ├── fzf.bash (exports + sources fzf shell integration)
  │   ├── git.bash (__git_files override)
  │   ├── go.bash (GOPATH + PATH)
  │   ├── grep.bash (GREP_COLOR, guarded by uname)
  │   ├── history.bash (shopt + PROMPT_COMMAND + HIST*)
  │   ├── linux.bash (alias open=xdg-open, guarded by uname)
  │   ├── mise.bash (eval "$(mise activate bash)")
  │   ├── ov.bash (exports pager vars if ov exists)
  │   ├── prompt.bash (eval "$(starship init bash)" or fallback)
  │   └── redirection.bash (set -o noclobber)
  └── customizations/direnv.bash (last — eval "$(direnv hook bash)")
```

## Root Causes of Slowness

### 1. `$(uname)` subshell forks — 10 calls across 6 files

Every `$(uname)` spawns a subshell + forks the `uname` binary. Found in:
- `aliases` (1x)
- `completions.bash` (2x)
- `darwin.bash` (1x)
- `fzf.bash` (2x)
- `grep.bash` (2x)
- `linux.bash` (1x)
- `mise.bash` (1x)

**Solution**: Bash has `$OSTYPE` built-in (`darwin*` on macOS, `linux-gnu` on Linux). Zero-cost, no fork. Or cache `uname` once.

### 2. `eval "$(mise activate bash)"` — 0.201s

Forks `mise`, captures its ~96-line output, then evals it. The mise output sets up a `PROMPT_COMMAND` hook that calls `mise hook-env` on every prompt. The `mise activate bash` command itself takes ~0.032s but the eval overhead in the benchmark context is higher.

**Options**:
- **`--shims` mode**: `eval "$(mise activate bash --shims)"` just adds `~/.local/share/mise/shims` to PATH. Near-zero cost. Loses automatic env switching on `cd`, but `direnv` already handles that.
- **Pre-cache**: Generate output to a file, source that file. Regenerate on mise upgrades.

### 3. `eval "$(direnv hook bash)"` — 0.045s

Forks `direnv`, captures 15 lines of shell code, evals. The output is stable (just a PROMPT_COMMAND hook).

**Solution**: Pre-cache the output. The hook itself is static — it just defines a `_direnv_hook` function and prepends it to PROMPT_COMMAND.

### 4. `bash-completion@2` — 0.060s (0.179s standalone)

Sourced via `completions.bash`. The `bash_completion.sh` wrapper loads the main `bash_completion` script which is heavy (~2400 lines, dynamically discovers completions).

**Solution**: bash-completion@2 supports lazy loading. Modern versions auto-load completions on demand. We can skip the eager source entirely and rely on lazy loading, or defer it.

### 5. `aliases` — 0.170s

The `alias_available` function calls `exists` (which calls `hash`) for each alternative. There are ~11 `exists` calls. `hash` is a bash builtin (fast), but the aggregate cost in the benchmark context is surprisingly high.

**Investigation**: The 0.170s seems disproportionate for builtins. Likely dominated by PATH searches for missing commands. `hash` searches PATH when the command isn't in the hash table. With a long PATH (homebrew + mise + local), each miss is expensive.

**Solution**: No good way to avoid this without losing functionality. Could defer alias setup to first prompt, but aliases are expected immediately.

### 6. FZF shell integration — 0.036s

Sources `completion.bash` and `key-bindings.bash` from homebrew.

**Solution**: FZF supports `--bash` flag in newer versions for integrated init: `eval "$(fzf --bash)"`. But the current approach already avoids `$(brew --prefix)`. Could lazy-load the completions.

### 7. `eval "$(starship init bash)"` in prompt.bash — currently ~0.001s

Shows 0.001s in benchmark but `starship init bash` takes 0.062s standalone. The benchmark may be measuring just the eval of cached output. Worth checking if starship is actually available in benchmark context.

**Note**: starship wasn't found in the benchmark PATH (`exit code 127`), so prompt.bash fell back to the simple PS1. In real usage with starship, this likely adds ~0.05-0.06s.

## Optimization Opportunities (ranked by impact)

1. **Replace `$(uname)` with `$OSTYPE`** — saves ~10 forks, estimated 0.05-0.10s
2. **Use mise `--shims` mode** — saves ~0.15-0.20s (biggest single win)
3. **Pre-cache direnv hook** — saves ~0.04s
4. **Lazy-load bash-completion** — saves ~0.06-0.18s
5. **Pre-cache starship init** — saves ~0.05s (when starship is available)
6. **Defer FZF integration** — saves ~0.03s (minor)
7. **Lazy-load aliases** — saves ~0.17s but introduces complexity

### Approach trade-offs

- **`$OSTYPE` vs cached `uname`**: `$OSTYPE` is built-in, zero-cost, but values differ (`darwin23` vs `Darwin`). Need pattern matching `[[ $OSTYPE == darwin* ]]` instead of string comparison.
- **mise --shims vs full activate**: Shims mode loses `mise hook-env` auto-activation on `cd`. But since `direnv` is already handling per-directory env, this may be acceptable.
- **Pre-caching vs lazy loading**: Pre-caching tool outputs (mise, direnv, starship) saves fork+exec but requires cache invalidation strategy. Lazy loading defers cost to first use.
- **Lazy-loading completions**: bash-completion@2 already supports this internally. We could skip the top-level source and let individual completions load on demand.

## Files that need changes

- `bashrc` — add `$OSTYPE` caching or detect OS once
- `customizations/mise.bash` — switch to --shims or pre-cache
- `customizations/direnv.bash` — pre-cache hook
- `customizations/prompt.bash` — pre-cache starship init
- `customizations/completions.bash` — lazy-load
- `customizations/darwin.bash` — use $OSTYPE
- `customizations/linux.bash` — use $OSTYPE
- `customizations/fzf.bash` — use $OSTYPE
- `customizations/grep.bash` — use $OSTYPE
- `aliases` — use $OSTYPE
