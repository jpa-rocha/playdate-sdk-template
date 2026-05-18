# playdate-sdk-template

A Lua/Playdate SDK starter template with a fully declarative, Nix-based development environment. Clone it, run `nix develop`, and every tool listed below is available immediately — no manual installs, no version conflicts, reproducible across machines.

## Requirements

- [Nix](https://nixos.org/download) with flakes enabled
- [direnv](https://direnv.net/) (optional — activates the shell automatically on `cd`)
- `nixpkgs.config.allowUnfree = true` (the Playdate SDK is proprietary)

## Quick start

```bash
# Clone and enter
git clone https://github.com/jpa-rocha/playdate-sdk-template my-game
cd my-game

# Enter the dev shell (direnv does this automatically if installed)
nix develop

# Create the source directory and entry point
mkdir -p source
cat > source/main.lua << 'EOF'
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

function playdate.update()
    gfx.clear(gfx.kColorWhite)
    gfx.drawTextAligned("Hello, Playdate!", 200, 120, kTextAlignment.center)
end
EOF

# Build and run in Simulator
build
sim              # or: PlaydateSimulator game.pdx
```

---

## Development environment

The dev shell is defined in `flake.nix` and the `nix/` modules. Every tool is pinned to a specific nixpkgs revision via `flake.lock`, so the environment is identical for every developer and in CI.

### Runtime and framework

| Tool | Version source | Purpose |
|------|---------------|---------|
| [LuaJIT](https://luajit.org/) | nixpkgs-unstable | Lua runtime (JIT-compiled) for local testing |
| [Playdate SDK](https://play.date/dev/) | [playdate-sdk-flake](https://github.com/RegularTetragon/playdate-sdk-flake) | `pdc` compiler, Simulator, and device tools |

The Playdate SDK is provided via a community Nix flake. It requires `allowUnfree = true` since the SDK is proprietary. The flake's `pdwrapper` automatically creates a local `.PlaydateSDK/` directory (gitignored) that the Simulator needs for writable state.

### Package management

| Tool | Purpose |
|------|---------|
| [lux-cli](https://github.com/lumen-oss/lux) | Modern Lua package manager — `lx add`, `lx install`, `lx fmt`, `lx lint` |
| [lux-lua](https://github.com/lumen-oss/lux) | C library component of lux; wired into `buildInputs` so `pkg-config` can locate it |

`lux-lua` is placed in `buildInputs` and `pkg-config` in `nativeBuildInputs` so that lux can find the library headers and link flags automatically when entering the shell.

### Editor support

| Tool | Purpose |
|------|---------|
| [lua-language-server](https://github.com/LuaLS/lua-language-server) | Full LSP: completions, type checking, go-to-definition |
| [ldoc](https://github.com/lunarmodules/LDoc) | Generates HTML documentation from LuaDoc/EmmyLua annotations |

The workspace is configured in `.luarc.json` with:
- Playdate-specific globals (`import`, `class`, `Object`) declared via `diagnostics.globals`
- Standard library modules disabled (`io`, `os`, `package`) since Playdate's sandbox doesn't provide them
- Compound assignment operators (`+=`, `-=`, etc.) recognized via `runtime.nonstandardSymbol`
- `diagnostics.unusedLocalExclude: ["_*"]` — respects the `_var` convention for intentionally unused locals
- `type.weakNilCheck: false` and `type.weakUnionCheck: false` — treats `T | nil` strictly so nil cannot silently flow through union types

For full Playdate API type definitions, add [playdate-luacats](https://github.com/notpeter/playdate-luacats) to `workspace.library` in `.luarc.json`.

### Linting

Two linters run in parallel — they catch different classes of issues.

| Tool | Config | What it catches |
|------|--------|----------------|
| [luacheck](https://github.com/mpeterv/luacheck) | `.luacheckrc` | Undefined globals, unused variables, shadowing, style issues |
| [selene](https://github.com/Kampfkarren/selene) | `selene.toml` | Modern static analysis |

Both run as pre-commit hooks and as a dedicated CI job.

**luacheck** uses `std = "luajit"` with Playdate globals (`playdate`, `import`, `class`, `Object`) declared explicitly. The following codes are suppressed intentionally:

- `122` — setting read-only global field (needed for Playdate callback assignment e.g. `playdate.update = ...`)
- `212` — unused argument (common in callback signatures)
- `631` — line too long (allowed for URLs and similar)

If your game defines custom globals, declare them explicitly in `.luacheckrc` with `globals = {"MyGlobal"}` rather than suppressing `113` globally.

**selene** uses `std = "lua51"` with Playdate globals declared. Stylistic allowances are kept (`mixed_table`, `multiple_statements`) since these are common in game code, but undefined globals and incorrect API usage will produce warnings.

### Formatting

| Tool | Config | Scope |
|------|--------|-------|
| [stylua](https://github.com/JohnnyMorganz/StyLua) | `stylua.toml` | Lua files |
| [nixfmt](https://github.com/NixOS/nixfmt) | RFC style | Nix files |
| [deadnix](https://github.com/astro/deadnix) | — | Removes unused Nix bindings |

All three are orchestrated by [treefmt](https://github.com/numtide/treefmt-nix) and run together via `nix fmt`. The stylua configuration uses 4-space indentation, 120-column width, double quotes, and never collapses simple statements onto one line.

### Testing

| Tool | Config | Purpose |
|------|--------|---------|
| [busted](https://lunarmodules.github.io/busted/) | `.busted` | BDD-style test framework |
| [luacov](https://github.com/lunarmodules/luacov) | `.luacov` | Line-level coverage reporting |
| [watchexec](https://github.com/watchexec/watchexec) | — | `watch` re-runs tests on `.lua` change; `watch-sim` rebuilds and restarts the Simulator on source or asset changes |

**busted** is configured in `.busted` to:
- Look for files matching `*_spec.lua`
- Resolve modules from `./source/` (matching the Playdate source directory convention)
- Use `utfTerminal` output for readable diffs on failure

Note: busted tests run on LuaJIT, not the Playdate runtime. Playdate-specific APIs (`playdate.*`) need to be mocked or stubbed in tests.

**luacov** is configured in `.luacov` to exclude test directories (`spec/`, `test/`, `tests/`, `lua_modules/`) from the report so coverage numbers reflect only production code.

### Secrets management

| Tool | Purpose |
|------|---------|
| [age](https://github.com/FiloSottile/age) | Encryption |

### Changelog

| Tool | Config | Purpose |
|------|--------|---------|
| [git-cliff](https://git-cliff.org/) | `cliff.toml` | Generates `CHANGELOG.md` from conventional commits |

**cliff.toml** is configured to group commits into sections by type and emit a dated header per version tag. Commits that don't follow the conventional format are filtered out of the changelog silently.

### Security scanning

| Tool | When it runs | What it scans |
|------|-------------|--------------|
| [trufflehog](https://github.com/trufflesecurity/trufflehog) | Pre-commit | Secrets and credentials in staged files |
| [ripsecrets](https://github.com/sirwart/ripsecrets) | Pre-commit | Secrets via regex patterns (complements trufflehog) |
| [semgrep](https://semgrep.dev/) | CI | Lua static security analysis using the `p/lua` ruleset |
| [osv-scanner](https://github.com/google/osv-scanner) | CI | Known CVEs in dependency lockfiles |
| [typos](https://github.com/crate-ci/typos) | Pre-commit | Typos in source code and documentation |

---

## Pre-commit hooks

Hooks run automatically on every `git commit`. They are defined in `nix/pre-commit.nix` and managed by [git-hooks.nix](https://github.com/cachix/git-hooks.nix).

| Hook | Scope | Blocks commit on failure |
|------|-------|--------------------------|
| `stylua --check` | `*.lua` | Yes |
| `luacheck` | `*.lua` | Yes |
| `selene` | `*.lua` | Yes |
| `nixfmt-rfc-style` | `*.nix` | Yes |
| `deadnix` | `*.nix` | Yes |
| `check-yaml` | `*.yaml`, `*.yml` | Yes |
| `shellcheck` | shell scripts | Yes |
| `trufflehog` | all files | Yes |
| `ripsecrets` | all files | Yes |
| `typos` | all files | Yes |
| `convco` | commit message | Yes |

Hooks are excluded from `flake.lock` to avoid noise on dependency updates.

---

## CI/CD

### Continuous integration (`ci.yml`)

Runs on every push and pull request to `main`/`master`. All jobs are independent and run in parallel.

| Job | Trigger | Steps |
|-----|---------|-------|
| **Nix Checks** | always | `nix flake check --all-systems` — validates flake structure and all system outputs |
| **Formatting** | always | `nix fmt -- --check .` — fails if any file is not formatted |
| **Pre-commit Hooks** | always | `pre-commit run --all-files` — runs the full hook suite against the tree |
| **Lua Linting** | always | `luacheck .` then `selene .` — both must pass |
| **Tests** | if test dir exists | `busted` via the `test` wrapper script |
| **Coverage** | if test dir exists | `busted --coverage` + `luacov` — prints full report to CI log |
| **Semgrep** | always | `semgrep --config p/lua --error .` — fails on any finding |
| **OSV Scan** | always | `osv-scanner --recursive .` — scans lockfiles for known CVEs |

### Release workflow (`release.yml`)

Triggered by pushing a version tag (`v*`). Runs as a single job with `contents: write` permission.

```
push tag v1.2.3
    │
    ├── luacheck + selene
    ├── busted (if tests exist)
    ├── pdc -s source/ game-v1.2.3.pdx
    ├── zip game-v1.2.3.pdx.zip
    ├── git cliff --current → RELEASE_NOTES.md
    └── GitHub Release
            ├── body: RELEASE_NOTES.md (commits since last tag)
            └── asset: game-v1.2.3.pdx.zip
```

The changelog in each release body is generated by `git cliff --current`, which collects all conventional commits since the previous version tag and groups them by type.

---

## Commands reference

### Game

```bash
build                            # Compile source/ into game.pdx
build -o mygame.pdx              # Custom output name
build -d source -o mygame.pdx    # Explicit source directory
build -s                         # Strip debug info for release
sim                              # Open game.pdx in the Playdate Simulator
sim mygame.pdx                   # Open specific .pdx in Simulator
watch-sim                        # Rebuild and restart Simulator on file change
watch-sim source mygame.pdx      # Watch specific directory with custom output
```

### Testing

```bash
test                             # Run test suite
test --pattern=_spec.lua         # Run matching files only
coverage                         # Run tests + print luacov report
watch                            # Re-run busted automatically on .lua file change
```

### Linting and formatting

```bash
luacheck .                       # Static analysis
selene .                         # Modern linter
nix fmt                          # Format all Lua and Nix files
nix fmt -- --check .             # Check formatting without modifying
lx fmt                           # Format via lux
lx lint                          # Lint via lux
```

### Building

```bash
build                            # Create game.pdx from source/
build -o mygame.pdx              # Custom output name
build -s -o mygame.pdx           # Release build (stripped)
clean                            # Remove .pdx directories and build artifacts
```

### Packages

```bash
lx install                       # Install dependencies from lux.toml
lx add <package>                 # Add a dependency
lx remove <package>              # Remove a dependency
```

### Changelog

```bash
git cliff                        # Preview full changelog
git cliff -o CHANGELOG.md        # Write to file
git cliff --current              # Commits since last tag only
git cliff --tag v1.0.0           # Generate for a specific tag
```

### Documentation

```bash
docs                             # Generate doc/ from source/ using ldoc
docs path/to/dir                 # Generate from a specific directory
```

### Utilities

```bash
version                          # Print Lua version
```

---

## Project structure

```
my-game/
├── source/
│   ├── main.lua          # Entry point (playdate.update)
│   ├── pdxinfo           # Game metadata (name, author, bundleID, etc.)
│   └── images/
│       ├── card.png      # 350x155 launcher card
│       ├── icon.png      # 32x32 launcher icon
│       └── launchImage.png  # 400x240 splash screen
├── spec/                 # Test files (*_spec.lua)
├── nix/
│   ├── devshells.nix     # Dev shell packages and build inputs
│   ├── pre-commit.nix    # Pre-commit hook definitions
│   ├── scripts.nix       # Custom shell scripts (test, build, coverage, watch, …)
│   └── treefmt.nix       # Formatter configuration
├── .github/
│   └── workflows/
│       ├── ci.yml        # Continuous integration
│       └── release.yml   # Tag-triggered release
├── .busted               # busted test runner config
├── .luacov               # luacov coverage config
├── .luacheckrc           # luacheck config
├── .luarc.json           # lua-language-server config
├── cliff.toml            # git-cliff changelog config
├── selene.toml           # selene linter config
├── stylua.toml           # stylua formatter config
└── flake.nix             # Dev environment, checks, formatter
```

---

## Commit conventions

[Conventional Commits](https://www.conventionalcommits.org/) are enforced by the `convco` pre-commit hook. Valid types:

| Type | Used for |
|------|---------|
| `feat` | New features |
| `fix` | Bug fixes |
| `perf` | Performance improvements |
| `refactor` | Code changes that neither fix a bug nor add a feature |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Maintenance (deps, config, tooling) |
| `ci` | CI/CD changes |
| `wip` | Work in progress |

Non-conforming messages are rejected at commit time. `git cliff` reads these types to group and format the changelog automatically.

---

## Playdate hardware specs

| Spec | Value |
|------|-------|
| Resolution | 400 x 240 pixels |
| Color depth | 1-bit (black and white) |
| Default refresh rate | 30 fps |
| Maximum refresh rate | 50 fps |
| Input | D-pad, A/B buttons, crank (analog rotary), accelerometer |
| Display scale modes | 1x, 2x, 4x, 8x |

---

## Distribution

```bash
build -s -o mygame.pdx           # Create a release build (stripped)
```

A `.pdx` is a directory bundle containing compiled Lua bytecode, images, sounds, and metadata.

| Method | How |
|--------|-----|
| Web sideload | Upload `.pdx` (or zipped `.pdx`) at [play.date/account/sideload](https://play.date/account/sideload/) |
| USB via Simulator | Connect device, open `.pdx` in Simulator, Device > "Upload Game to Device" |
| Data Disk mode | Reboot to Data Disk, mount USB volume, copy `.pdx` to `Games/` folder |
| Catalog | Submit to Panic's official storefront (requires approval) |
| itch.io | Community distribution; users sideload the `.pdx` themselves |

Pushing a `v*` tag triggers the release workflow which builds, zips, and attaches the `.pdx.zip` to a GitHub release automatically.
