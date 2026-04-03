# Roblox Game Factory

## Language
Luau (NOT Lua 5.1). Always write `.luau` files.

## Project Structure
- `src/server/` → ServerScriptService (server-only: data, combat, economy, validation)
- `src/client/scripts/` → StarterPlayerScripts (input, camera, effects)
- `src/client/gui/` → StarterGui (UI components, screens)
- `src/shared/` → ReplicatedStorage.Shared (shared modules, types, constants)
- `Packages/` → ReplicatedStorage.Packages (Wally dependencies, gitignored)
- `assets/` → managed by Asphalt, auto-uploaded to Roblox

## File Naming
- `*.server.luau` = Server Script
- `*.client.luau` = Local Script
- `*.luau` = ModuleScript
- `init.luau` / `init.server.luau` / `init.client.luau` = the script IS the folder (Rojo convention)

## Naming Conventions
- `PascalCase`: classes, services, modules, types, file names
- `camelCase`: local variables, functions, method names
- `UPPER_SNAKE_CASE`: local constants only
- `_camelCase`: private members (underscore prefix)
- Suffix yielding functions with `Async` (e.g., `loadDataAsync()`)

## Code Style (CRITICAL)
- Use `task.spawn()` NOT `coroutine.wrap()`
- Use `task.wait()` NOT `wait()`
- Use `task.delay()` NOT `delay()`
- Set Parent LAST when calling `Instance.new()`
- Use `game:GetService()` for ALL services, never `game.ServiceName`
- Use `UDim2.fromScale()` and `UDim2.fromOffset()` NOT `UDim2.new()`
- Prefer early return over deep nesting
- Sort requires alphabetically
- Use `table.freeze()` for constant tables
- Use `RunService.Heartbeat` over `while true do task.wait() end`
- Clean up connections with Trove — never leave dangling listeners

## Security Rules (CRITICAL — NEVER SKIP)
- NEVER trust the client. Validate ALL RemoteEvent data on server
- NEVER store sensitive data in ReplicatedStorage
- ALWAYS rate-limit remote calls (10 calls/second max per remote)
- ALWAYS type-check remote arguments with `t` library
- ALWAYS do sanity checks: distance, ownership, cooldowns
- Server owns ALL game state (health, currency, inventory, position)
- Client sends INTENTS ("I want to attack"), server validates and executes
- NEVER let client tell server the result ("I dealt 50 damage")

## Architecture Pattern
- Server: services in `src/server/services/` — one module per system (DataService, CombatService, EconomyService)
- Client: controllers in `src/client/controllers/` — one module per system
- Shared: types, constants, network definitions in `src/shared/`
- UI: Fusion components in `src/client/gui/components/`
- Networking: typed remotes via Comm package

## Common Services
```
Players, ReplicatedStorage, ServerScriptService, ServerStorage,
UserInputService (client only), RunService, TweenService,
DataStoreService (server only), HttpService, CollectionService,
MarketplaceService, SoundService, Lighting, BadgeService
```

## Build Commands
```bash
rokit install               # Install toolchain
wally install               # Install packages
rojo serve                  # Start dev sync with Studio
rojo build -o build/game.rbxl  # Build place file
selene src/                 # Lint
stylua src/                 # Format
stylua --check src/         # Format check (CI)
lune run lune/build         # Full build pipeline
lune run tests/runner       # Run tests
asphalt sync                # Upload assets to Roblox
darklua process src/ dist/  # Code processing (dead code, require paths)
```

## Dependencies
- Wally packages defined in `wally.toml`, installed to `Packages/`
- Rokit manages tool versions in `rokit.toml`
- Never copy-paste modules — always use Wally packages

## Performance Rules
- Target: under 10,000 parts in Workspace at any time
- StreamingEnabled = true, MinRadius = 64, TargetRadius = 1024
- Pool frequently spawned objects (bullets, particles, effects)
- Batch RemoteEvent fires (one event with array, not N events)
- Cache `FindFirstChild` results — don't call in hot loops
- Use `workspace:BulkMoveTo()` for batch part movements
- Use `ContentProvider:PreloadAsync()` for critical assets on load
- Keep textures at 512x512 max, prefer 256x256
