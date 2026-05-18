# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Lua/Playdate SDK starter template with Nix-based development environment. It provides pre-configured tooling for Lua development including linting, formatting, testing, and CI/CD targeting the Playdate handheld console.

## Development Environment

This project uses Nix flakes for reproducible development environments. If you have direnv installed, the environment activates automatically via `.envrc`. Otherwise, enter manually:

```bash
nix develop
```

The Playdate SDK is provided via a community Nix flake (`RegularTetragon/playdate-sdk-flake`). It requires `allowUnfree = true`. The flake provides `pdc`, `PlaydateSimulator`, and `pdutil` on `PATH`. A local `.PlaydateSDK/` directory is created automatically for Simulator state.

The dev shell provides:
- Playdate SDK (`pdc`, `PlaydateSimulator`, `pdutil`)
- LuaJIT (Lua runtime for local testing)
- lua-language-server (LSP)
- lux (modern Lua package manager with integrated fmt/lint/check)
- luacheck (Lua linter)
- selene (Modern Lua linter)
- busted (Test framework)
- stylua (Code formatter)
- age (encryption)
- Pre-commit hooks (automatically enabled)
- Custom scripts: `version`, `test`, `build`, `clean`, `sim`, `watch-sim`

## Playdate SDK Essentials

### Hardware Constraints
- Screen: 400x240 pixels, 1-bit (black and white only)
- Frame rate: 30 fps default, 50 fps max
- Input: D-pad, A/B buttons, crank (analog rotary), accelerometer
- Memory: Limited — avoid excessive allocations

### Entry Point
The game entry point is `source/main.lua`. Playdate uses `import "filename"` (not Lua's `require`) to include files. All imported files are compiled into `.pdz` bytecode.

### Game Loop
Playdate uses a single callback for the game loop:
```lua
function playdate.update()
    -- ALL per-frame logic and drawing happens here
    -- There is no separate draw callback
end
```

### Key API Namespaces
- `playdate.graphics.*` — Drawing, sprites, images, text, fonts, tilemaps
- `playdate.display.*` — Screen properties, refresh rate, scaling
- `playdate.sound.*` — Audio playback, synthesis, effects
- `playdate.timer.*` / `playdate.frameTimer.*` — Timers
- `playdate.file.*` — Filesystem
- `playdate.datastore.*` — Save data serialization
- `playdate.geometry.*` — Points, rects, polygons
- `playdate.ui.*` — UI components (grid views, crank indicator)

### CoreLibs
Optional utility modules shipped with the SDK, imported via:
```lua
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/object"    -- class() OOP system
import "CoreLibs/easing"
```

### Lua Extensions on Playdate
- Compound assignment operators: `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `<<=`, `>>=`, `&=`, `|=`, `^=`
- Extra table functions: `table.indexOfElement()`, `table.getsize()`, `table.create()`, `table.shallowcopy()`, `table.deepcopy()`
- `import` statement (replaces `require`)
- `class()` function for OOP (from CoreLibs/object)

### pdxinfo Metadata
Game metadata goes in `source/pdxinfo`:
```
name=My Game
author=Developer Name
description=A Playdate game
bundleID=com.developer.mygame
version=1.0
buildNumber=100
imagePath=images/launcher
```

## Common Commands

### Building and Running
```bash
# Build source/ into a .pdx bundle
build

# Build with custom output name
build -o mygame.pdx

# Strip debug info for release
build -s -o mygame.pdx

# Run in the Playdate Simulator
sim

# Watch and auto-rebuild + restart Simulator
watch-sim
```

### Lux (Package Manager & Tooling)
```bash
# Install dependencies from lux.toml
lx install

# Format Lua files
lx fmt

# Lint Lua files
lx lint

# Type check (EmmyLua/LuaCATS annotations)
lx check

# Run a Lua script
lx run script.lua
```

### Linting
```bash
# Run both linters
luacheck .
selene .

# Via lux
lx lint

# Check formatting without modifying
nix fmt -- --check .
```

### Formatting
```bash
# Format all files in the project
nix fmt

# Via lux
lx fmt

# Format specific Lua files
stylua **/*.lua

# Check formatting without modifying
stylua --check .
```

### Testing
```bash
# Run tests (looks for spec/, test/, or tests/ directory)
test

# Run specific test file
busted spec/mytest_spec.lua

# Run with pattern matching
busted --pattern=_spec.lua
```

### Cleaning
```bash
# Remove build artifacts (.pdx directories, luac.out, etc.)
clean
```

### Nix Commands
```bash
# Run all checks (formatting, pre-commit hooks)
nix flake check

# Update dependencies
nix flake update

# Check Lua version
version
```

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on push and PR:

1. **Nix Checks** - Validates flake configuration
2. **Formatting** - Ensures code is formatted correctly
3. **Pre-commit Hooks** - Runs all configured hooks
4. **Lua Linting** - Runs luacheck and selene
5. **Tests** - Runs busted test suite (if tests exist)

The workflow uses Nix for reproducible builds.

## Pre-commit Hooks

Pre-commit hooks run automatically in the dev shell and in CI. Hooks include:

- `stylua` - Lua code formatting
- `luacheck` - Lua static analysis
- `selene` - Modern Lua linting
- `nixfmt-rfc-style` - Nix formatting
- `convco` - Conventional commit message validation
- `trufflehog` - Secret scanning
- `ripsecrets` - Additional secret detection
- `check-yaml` - YAML validation
- `shellcheck` - Shell script linting
- `deadnix` - Detect unused Nix code

## Linting Configuration

### luacheck (.luacheckrc)
- Standard: `luajit` with Playdate globals (`playdate`, `import`, `class`, `Object`)
- Ignores:
  - Code 122: Setting read-only field of global variable (needed for Playdate callbacks)
  - Code 212: Unused argument (common in callbacks where `_arg_name` is clearer than `_`)
  - Code 631: Line too long (for cases like long URLs)

### selene (selene.toml)
- Standard: `lua51` with Playdate globals declared
- Allows mixed tables, multiple statements (common in game code)

### stylua (stylua.toml)
- Column width: 120 characters
- Indent width: 4 spaces
- Unix line endings
- Auto-prefer double quotes
- Always use call parentheses
- Never collapse simple statements

### lua-language-server (.luarc.json)
- Recognizes Playdate globals (`import`, `class`, `Object`)
- Disables unavailable builtins (`io`, `os`, `package`)
- Supports compound assignment operators (`+=`, `-=`, etc.)

## Testing with Busted

Busted looks for tests in `spec/`, `test/`, or `tests/` directories. Test files should follow the pattern `*_spec.lua`.

Example test structure:
```lua
describe("My module", function()
  it("should do something", function()
    assert.equals(2, 1 + 1)
  end)
end)
```

Note: Tests run on LuaJIT, not the Playdate runtime. Playdate-specific APIs need to be mocked or stubbed in tests.

Run tests with the `test` command or directly with `busted`.

## Nix Configuration Structure

The Nix setup is modularized in the `nix/` directory:

- **devshells.nix** - Defines the development shell environment and packages
- **pre-commit.nix** - Configures all pre-commit hooks and exclusions
- **treefmt.nix** - Configures formatting tools (stylua, nixfmt, deadnix)
- **scripts.nix** - Custom shell scripts (version, test, build, clean, sim, watch-sim)

The main `flake.nix` orchestrates these modules and provides:
- `devShells.default` - The development environment
- `checks.formatting` - CI formatting validation
- `checks.pre-commit-check` - CI pre-commit hook validation
- `formatter` - The default formatter (treefmt wrapper)

## Starting a New Project

To start building a Playdate game:

1. Create a `source/` directory with `main.lua`
2. Define the `playdate.update()` callback (all game logic and drawing here)
3. Create `source/pdxinfo` with game metadata (name, bundleID, etc.)
4. Build with `build` command (compiles via `pdc`)
5. Test in the Playdate Simulator
6. Create tests in `spec/` directory (optional, runs on LuaJIT)
7. Build distributable with `build -s` for release

For Playdate-specific conventions:
- `source/main.lua` - Entry point with `playdate.update()` callback
- `source/pdxinfo` - Game metadata file
- `source/images/` - Game art (1-bit PNGs)
- `source/sounds/` - Audio files
- Type annotations use `---@type` and `---@param` for LSP support
- Use `import "file"` instead of `require("file")`

## Building and Distribution

The `build` script compiles source code via `pdc` into a `.pdx` bundle:

```bash
build                  # Creates game.pdx from source/
build -o name.pdx      # Custom output name
build -s -o name.pdx   # Stripped release build
```

To distribute:
- **Web sideload**: Upload `.pdx` (zipped) at play.date/account/sideload/
- **USB via Simulator**: Connect device, upload from Simulator
- **Data Disk mode**: Mount device as USB drive, copy to Games/ folder
- **Catalog**: Submit to Panic's official storefront
- **itch.io**: Community distribution

## Game Programming Patterns Reference

Source: https://gameprogrammingpatterns.com — use these patterns when designing game systems in Lua for Playdate.

---

### Design Patterns Revisited

#### Command
**Intent:** Encapsulate a request as an object to support undo, queuing, logging, and replay.

**Structure:**
- **Base Command** — interface with `execute()` (and optionally `undo()`)
- **Concrete Commands** — store actor/receiver + parameters, implement the action
- **Invoker** — triggers commands without knowing their details
- **Receiver** — the object that actually performs the work

**When to use:**
- Configurable input mapping (decouple button → action at runtime)
- Undo/redo (store command history, reverse state changes)
- Action queuing/replay/networked games (serialize command streams)
- Deferred execution (separate creation from execution)

**Trade-offs:**
- Good: excellent decoupling, enables undo/replay, composable and testable
- Bad: extra classes/complexity; careful state management needed for undo; memory overhead from many instances

**Notes:** For undo, store only what changed — not full snapshots. In Lua, closures can replace explicit command objects. Pair with Null Object to avoid nil checks on unbound commands.

---

#### Flyweight
**Intent:** Share common (intrinsic) state across many objects to reduce memory usage.

**Structure:**
- **Intrinsic state** — shared, context-free data (image, terrain properties); lives in one flyweight object
- **Extrinsic state** — per-instance unique data (position, state flags); stays with individual instances
- Many lightweight instances each hold a reference to one shared flyweight

**When to use:**
- Many similar objects consuming significant memory
- Much of an object's state is identical across instances
- Objects can remain immutable
- Memory efficiency is critical (Playdate has limited RAM)

**Trade-offs:**
- Good: dramatically reduces memory; essential on constrained hardware like Playdate
- Bad: pointer indirection can cause cache misses; adds complexity; requires careful lifetime management

**Notes:** Keep flyweight objects immutable to prevent side effects. On Playdate, share image tables and sprite sheets rather than loading duplicates.

---

#### Observer
**Intent:** Let one piece of code announce events without caring who receives them.

**Structure:**
- **Observer interface** — `onNotify()` contract for receivers
- **Subject** — maintains observer list; registers/unregisters; fires notifications
- **Concrete Observers** — implement the interface and react to events

**When to use:**
- Multiple unrelated systems react to the same event (physics → achievements, audio)
- Decoupling notification source from receivers
- Observers may be added/removed dynamically
- Teams developing subsystems independently

**Trade-offs:**
- Good: loose coupling; dynamic registration; no allocation during notification
- Bad: synchronous — slow observers block the subject; "lapsed listener" memory leaks if not unregistered; hard to trace runtime behaviour statically

**Notes:** In Lua, use function tables or callbacks instead of interface classes. Always unregister observers when entities are destroyed.

---

#### Prototype
**Intent:** Spawn new objects by cloning an existing instance as a template.

**Structure:**
- Base class with abstract `clone()` method
- Concrete implementations copy both class and internal state
- Spawner holds a prototype and calls `clone()` to produce new objects

**When to use:**
- Multiple similar objects with shared attributes
- Cloning is cheaper than constructing from scratch
- Object state variation matters (different stats per monster type)

**Trade-offs:**
- Good: eliminates redundant spawner classes; clones preserve both type and state
- Bad: still requires `clone()` in each subclass; deep vs. shallow clone semantics can be tricky; often superseded by data-driven type systems

**Notes:** More useful for data modelling (JSON prototype chains) than classic OOP hierarchies in modern game engines. In Lua, table copying or metatables handle this naturally. On Playdate, use `table.deepcopy()` (built-in extension).

---

#### Singleton
**Intent:** Ensure a class has one instance and provide a global point of access to it.

**Structure:**
- Private constructor
- Static instance variable
- Public static accessor (`instance()`)

**When to use:** Rarely. Only when the system genuinely must not have multiple instances AND global access is truly necessary.

**Trade-offs:**
- Good: lazy init; deferred runtime setup; supports polymorphism via subclassing
- Bad: global state complicates reasoning; encourages tight coupling; lazy init causes timing stutters in games; bakes in single-instance assumption at every call site

**Notes:** The book strongly discourages this pattern. Prefer passing instances as parameters, accessing via a parent `Game` object, or using the Service Locator pattern instead. In Lua, module-level tables already act as singletons — don't over-engineer.

---

#### State
**Intent:** Allow an object to alter its behaviour when its internal state changes; the object appears to change its class.

**Structure:**
- **State interface** — virtual methods for state-varying behaviour (`handleInput()`, `update()`)
- **Concrete State classes** — each encapsulates its own behaviour and relevant data
- **Context object** — holds a reference to current state and delegates calls to it

**When to use:**
- Behaviour fundamentally depends on internal conditions (standing/jumping/ducking)
- Possible states form a small, well-defined set
- You want to eliminate sprawling if/else chains across multiple boolean flags

**Trade-offs:**
- Good: prevents invalid state combos; centralises state-specific code; makes transitions explicit
- Bad: more classes; FSMs don't scale to complex logic alone; state objects need instantiation/memory management

**Notes:** Use static instances when states carry no data; create instances when state needs fields (e.g. `chargeTime`). Extend with hierarchical FSMs, concurrent FSMs, or pushdown automata (stack) for complex cases. In Lua, represent states as tables with method fields.

---

### Sequencing Patterns

#### Double Buffer
**Intent:** Cause a series of sequential operations to appear instantaneous or simultaneous.

**Structure:**
- Two buffers: **current** (read) and **next** (write)
- All reads come from current; all writes go to next
- An atomic swap makes next the new current

**When to use:**
- State is modified incrementally AND may be read during modification
- You need to hide work-in-progress from external code
- Preventing torn reads (e.g. rendering half-drawn frame)

**Trade-offs:**
- Pointer swap: extremely fast, but external code can't hold persistent buffer references; data is two frames old
- Data copy: fresher (one frame old) but slower swap; better for small distributed state
- Memory cost: always two full copies of buffered state

**Notes:** Playdate handles the graphics double buffer automatically via `playdate.graphics`. Apply this manually for game state that is read while being written (e.g. cellular automata, physics state).

---

#### Game Loop
**Intent:** Decouple the progression of game time from user input and processor speed.

**Structure:**
1. **Process input** — non-blocking capture of user actions
2. **Update** — advance simulation (AI, physics) by elapsed time
3. **Render** — display current state

**When to use:** Every game needs this. Playdate provides `playdate.update()` as the single loop callback (called at the configured refresh rate, default 30fps).

**Approaches:**
| Variant | Summary | Risk |
|---------|---------|------|
| Fixed step, no sync | Simplest; speed varies with hardware | N/A on Playdate (fixed hardware) |
| Fixed step + sleep | Caps FPS; power-efficient | Default Playdate behavior |
| Variable time step | Adaptive but non-deterministic | Physics instability from float errors |
| **Fixed update + variable render** | Recommended for complex physics | More complex; needs interpolation |

**Notes:** Playdate calls `playdate.update()` at a fixed rate (configurable via `playdate.display.setRefreshRate()`). Since the hardware is fixed, frame timing is predictable. Use `playdate.getElapsedTime()` or frame timers for time-sensitive logic.

---

#### Update Method
**Intent:** Simulate a collection of independent objects by telling each to process one frame of behaviour at a time.

**Structure:**
- Abstract `Entity` with virtual `update()` method
- Concrete entities implement their own per-frame logic
- `World` iterates the entity collection and calls `update()` each frame

**When to use:**
- Multiple independent objects need simultaneous-seeming simulation
- Each object's behaviour is largely self-contained
- Objects must simulate continuously over time (not turn-based)

**Trade-offs:**
- Good: clean separation of per-entity logic; easy to add/remove entities
- Bad: requires explicit state storage between frames (flags, FSM); updates are sequential not truly concurrent; collection modification during iteration is hazardous

**Notes:** Guard against modifying the entity list mid-iteration — defer adds/removes or iterate a copy. On Playdate, the sprite system (`playdate.graphics.sprite`) already implements this pattern — sprites with `:update()` methods are called automatically via `playdate.graphics.sprite.update()`.

---

### Behavioral Patterns

#### Bytecode
**Intent:** Give behaviour the flexibility of data by encoding it as instructions for a virtual machine.

**Structure:**
- **Instruction set** — enum of available operations
- **Bytecode stream** — contiguous byte array; each byte is an opcode, followed by optional operands
- **Virtual Machine** — instruction pointer, value stack, dispatch loop
- Stack-based: instructions pop parameters from stack, push results back

**When to use:**
- Behaviour needs rapid iteration without recompilation
- Content must be separated from engine code
- User-created content requires sandboxing (mods, spells)
- Non-technical creators define behaviour via higher-level tools

**Trade-offs:**
- Good: compact memory; linear execution = cache friendly; safe sandboxing; content updates without patching
- Bad: slower than native code; requires building compiler tooling and debugger support; scope creep is a real risk

**Notes:** Stack-based VMs are simplest to implement. Define the instruction set conservatively — adding instructions is easy, removing them breaks content. On Playdate, Lua itself serves as the scripting layer — consider data-driven approaches (JSON/table configs) over custom VMs.

---

#### Subclass Sandbox
**Intent:** Define behaviour in a subclass using a set of operations provided by its base class.

**Structure:**
- **Base class** — abstract sandbox method + protected helper methods for all external interactions
- **Provided operations** — non-virtual protected methods encapsulating system calls
- **Subclasses** — override the sandbox method using only the base class helpers

**When to use:**
- Many subclasses need similar capabilities
- Significant overlap in what subclasses need to do
- You want to centralise coupling to external systems in one place

**Trade-offs:**
- Good: centralises coupling; reduces duplication; easier to enforce invariants
- Bad: base class grows large over time (brittle base class problem); base becomes coupled to every system any subclass needs

**Notes:** Extract groups of related operations into helper objects rather than cramming everything into the base. In Lua, use a shared module of utility functions that all "power" implementations require, rather than inheritance. On Playdate, `CoreLibs/object` provides the `class()` system for this.

---

#### Type Object
**Intent:** Allow the flexible creation of new "classes" by making each instance of a type class represent a different type of object.

**Structure:**
- **Type Object** (e.g. `Breed`) — holds shared data/behaviour for all instances of that type
- **Typed Object** (e.g. `Monster`) — individual instance holding a reference to its type object; delegates type queries to it

**When to use:**
- Types need to be defined in data files, not compiled code
- Hundreds of variations without hundreds of subclasses
- Non-programmers (designers) should modify types without recompilation
- Types may be unknown at development time or downloaded as content

**Trade-offs:**
- Good: eliminates subclass explosion; runtime type definition via config; simplifies tuning
- Bad: manual memory management of type objects; complex procedural behaviour is harder; forwarding code if types aren't public; inheritance chains slow attribute lookup

**Notes:** In Lua, this maps naturally to prototype-based tables: a monster table delegates unknown keys to its breed table via `__index`. This is idiomatic Lua OOP. On Playdate, use `playdate.datastore` or JSON files to define type data externally.

---

### Decoupling Patterns

#### Component
**Intent:** Allow a single entity to span multiple domains without coupling the domains to each other.

**Structure:**
- **Container object** — lightweight; holds references to components; owns lifecycle
- **Component classes** — each encapsulates one domain (physics, rendering, input, audio)
- **Shared state** — pan-domain data (position) lives in the container for inter-component access

**When to use:**
- A class touches multiple domains you want isolated
- A single class has grown unwieldy
- You need flexible capability composition without deep inheritance hierarchies

**Trade-offs:**
- Good: eliminates domain coupling; composition over inheritance; supports runtime flexibility; team scalability
- Bad: more objects to manage; memory overhead; inter-component communication needs design; pointer chasing can hurt cache (but can also improve it with SoA layout)

**Inter-component communication options:**
1. **Shared container state** — components read/write parent fields; simple but muddy
2. **Direct references** — components hold sibling pointers; fast but reintroduces coupling
3. **Messaging** — mediator (container) routes messages; decoupled but complex

**Notes:** Playdate games benefit from this pattern. Typical components: `TransformComponent`, `SpriteComponent`, `ColliderComponent`, `AIComponent`. In Lua, implement as tables stored in an entity table. Playdate's sprite system already provides a component-like structure for rendering.

---

#### Event Queue
**Intent:** Decouple when a message or event is sent from when it is processed.

**Structure:**
- **Ring buffer** — fixed array with head/tail indices (modulo wrapping)
- **Message objects** — capture all parameters at send-time
- **Enqueue** — appends to tail; returns immediately
- **Dequeue/update** — processes from head at a convenient time

**When to use:**
- Processing must happen on a different frame than the request
- Multiple requests can be batched or deduplicated
- Receiver needs control over processing pace
- Avoiding blocking the caller during expensive operations

**Trade-offs:**
- Good: non-blocking senders; enables aggregation; receiver controls pace
- Bad: sender loses control and can't get a response; world state may change before processing; feedback loop risk; global queues become hidden dependencies

**Notes:** Capture enough data in the message at send-time — world state will change. Avoid sending events while handling events to prevent feedback loops. On Playdate, useful for audio requests, deferred AI decisions, or cross-system notifications.

---

#### Service Locator
**Intent:** Provide a global point of access to a service without coupling users to the concrete class that implements it.

**Structure:**
- **Service interface** — abstract class defining the API
- **Concrete providers** — implementations (real, null, logging decorator)
- **Locator** — static registry; `locate()` returns the registered provider

**When to use:**
- Systems that permeate the codebase (audio, logging, input)
- Services that are fundamentally singular
- Systems that shouldn't be part of a module's public API
- Use sparingly — prefer passing dependencies explicitly when feasible

**Trade-offs:**
- Good: decouples clients from implementations; enables runtime swapping; decorator pattern applies cleanly
- Bad: dependencies become implicit; temporal coupling (must register before use); all call sites must handle missing service; minor runtime lookup cost

**Notes:** Favour external registration + Null Object fallback during development. In Lua, a global module table acting as the locator is idiomatic, but document what must be registered and when.

---

### Optimization Patterns

#### Data Locality
**Intent:** Accelerate memory access by arranging data to take advantage of CPU caching.

**Structure:**
- **Contiguous component arrays** — flat arrays per component type instead of arrays of pointers to scattered objects
- **Packed/active data** — active objects at the front; swap inactive to end; iterate without branches
- **Hot/cold splitting** — separate frequently-accessed fields from rarely-used ones into different structs

**When to use:**
- Profiling shows cache misses are causing slowdowns
- Tight loops process large datasets repeatedly
- Do NOT apply speculatively — profile first

**Trade-offs:**
- Good: dramatic gains (author reports 50x in some cases); simpler loops; fewer branches
- Bad: sacrifices abstraction and encapsulation; fewer interfaces/virtual methods; complex code; polymorphic types in packed arrays are tricky; moving objects invalidates raw pointers

**Notes:** Replace pointer indirection with direct array access. Use indices/IDs instead of raw pointers when objects may move. In Lua on Playdate, this matters less due to the VM overhead, but grouping related data in arrays still helps reduce GC pressure. Use `table.create()` to pre-allocate arrays.

---

#### Dirty Flag
**Intent:** Avoid unnecessary work by deferring it until the result is needed.

**Structure:**
- **Primary data** — the source state that changes (e.g. local transform)
- **Derived data** — computed value dependent on primary (e.g. world transform)
- **Dirty flag** — boolean; set true when primary changes; cleared after recompute

**When to use:**
- Primary data changes frequently but derived data is needed infrequently
- The computation is expensive (matrix math, I/O, serialisation)
- Incremental updates aren't feasible

**Trade-offs:**
- Good: avoids redundant calculations; skips work if result is never needed; minimal memory overhead
- Bad: must set flag on every primary change or stale data corrupts state; deferred work can cause visible pauses; memory for cached data; risk of losing work if process crashes before flush

**Notes:** Encapsulate behind a single mutation interface to ensure the flag is always set. In hierarchical structures (scene graphs), propagate dirtiness during traversal rather than cascading recursively. On Playdate, the sprite system uses dirty rects internally — sprites only redraw when marked dirty via `:markDirty()` or `:setNeedsDisplay()`.

---

#### Object Pool
**Intent:** Improve performance and memory use by reusing objects from a fixed pool instead of allocating and freeing them individually.

**Structure:**
- **Pool** — fixed-size array of pre-allocated objects
- **Objects** — expose `inUse()` state; fully reset on reuse
- **Free list** (optimisation) — linked list threaded through unused object memory for O(1) acquisition

**When to use:**
- Frequent creation/destruction in tight loops (particles, bullets, sound effects)
- Objects are uniform in size
- Memory allocation is slow or fragmentation is a concern
- Objects encapsulate expensive resources (connections, handles)

**Trade-offs:**
- Good: eliminates fragmentation; faster than repeated alloc/free; predictable memory
- Bad: pool size must be tuned (oversizing wastes memory); hard limit on concurrent objects; all slots sized for largest object; stale data bugs if not reset properly; conflicts with GC (objects never truly freed)

**Pool exhaustion strategies:** prevent overflow via sizing; silently skip creation; forcibly recycle least-important object; grow dynamically.

**Notes:** In Lua, the GC handles allocation, so the main benefit is reducing GC pressure and avoiding table churn. Pre-allocate a table of reusable objects and reset fields on reuse rather than creating new tables. On Playdate this is especially important due to limited memory — pool bullets, particles, and frequently spawned entities.

---

#### Spatial Partition
**Intent:** Efficiently locate objects by storing them in a data structure organised by their positions.

**Structure:**
- **Grid** (simplest) — 2D array of cells; each cell holds a linked list of objects within that region
- **Objects** — store position + prev/next pointers for their cell's list
- **Update** — on move, remove from old cell, insert into new cell

**When to use:**
- Repeated "what objects are near X?" queries per frame
- Physics collision detection
- Range-based combat, audio positioning, proximity checks
- Large numbers of objects (small counts don't need it)

**Trade-offs:**
- Flat grid: simple, fast for moving objects, wastes memory on empty regions
- Hierarchical (quadtree, k-d tree): adapts to density, complex updates, better for static scenes
- Object-independent partitions: accept incremental updates but may become unbalanced
- Adaptive partitions: balanced queries but require rebuilds on change

**Notes:** The core gain is reducing O(n^2) pairwise checks to comparisons within neighbouring cells only. Handle edge cases where query radius exceeds cell size by checking adjacent cells. Doubly-linked lists enable fast removal/insertion on move. On Playdate (400x240 screen), a simple grid works well for collision broadphase before expensive narrow-phase checks. Playdate's sprite system also provides `playdate.graphics.sprite.querySpritesInRect()` and collision response built-in.
