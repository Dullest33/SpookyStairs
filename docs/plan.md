# Spooky Stairs — Technical Plan (Stage 3)

Source of truth for design: `docs/spec.md`. This file says how to build it.
Claude Code: read this whole file before any milestone. Update `docs/progress.md` when a milestone is done.

---

## 1. Rojo file tree

```text
spooky-stairs/
├── default.project.json
├── selene.toml / stylua.toml
├── docs/            spec.md, plan.md, progress.md, lessons.md
└── src/
    ├── server/                                  → ServerScriptService.Server
    │   ├── init.server.luau                      Boots all services in order, then calls :Start() on each
    │   └── Services/
    │       ├── DataService.luau                  Profile load/save, session lock, autosave 60 s, migrations
    │       ├── PartyService.luau                 Lobby elevator queue, parties of 1–4, starts runs
    │       ├── FloorGenerator.luau               Seeded room selection + placement of candy, hides, door, monster slot
    │       ├── RunManager.luau                   One Run object per party: floor, hearts, revives, checkpoints
    │       ├── MonsterDirector.luau              Runs monster state machines (signal → act → leave)
    │       ├── Monsters/                         One module per monster, same interface (see §6)
    │       │   ├── SockGoblin.luau
    │       │   ├── GiggleGhost.luau
    │       │   ├── PortraitPeepers.luau
    │       │   ├── PumpkinRolly.luau
    │       │   ├── BatButler.luau
    │       │   ├── SnoringGiant.luau
    │       │   ├── VacuumMaid.luau
    │       │   └── MrDrippy.luau
    │       ├── PuzzleService.luau                Counting / pattern puzzle state + answer checking
    │       ├── RewardService.luau                ONLY place candy and cards are granted; golden rolls
    │       ├── ShopService.luau                  Candy purchases + game pass ownership
    │       ├── BadgeService.luau                 Awards badges (rooftop, card book)
    │       └── RemoteGuard.luau                  Shared validation + per-player rate limiting
    ├── client/                                   → StarterPlayer.StarterPlayerScripts.Client
    │   ├── init.client.luau                      Boots all controllers
    │   └── Controllers/
    │       ├── InputController.luau              Keyboard/gamepad/touch → intents (flashlight, interact, crouch)
    │       ├── FlashlightController.luau         Beam visuals, battery ring; sends SetFlashlight
    │       ├── InteractController.luau           ProximityPrompts for doors, hides, revives, puzzles
    │       ├── FeedbackController.luau           All juice: pop numbers, particles, sounds, shake, tweens
    │       ├── HUDController.luau                Hearts, floor, candy, battery, guidance arrow
    │       ├── GuidanceController.luau           Exit glow, firefly trail after 15 s idle
    │       ├── MonsterFxController.luau          Client-side signals (flicker, sounds) from MonsterEvent
    │       ├── CardBookController.luau           Card book UI + new-card reveal
    │       ├── ShopController.luau               Vending machine / lobby shop UI
    │       └── SettingsController.luau           Less Spooky toggle
    └── shared/                                   → ReplicatedStorage.Shared
        ├── Config.luau                           All tuning numbers in one place
        ├── Types.luau                            Exported types (Profile, RunState, MonsterDef, RoomDef…)
        ├── MonsterDefs.luau                      Per-monster data: first floor, signal, timings, card id
        ├── RoomDefs.luau                         Per-template data: floor range, sockets, weight
        ├── Remotes.luau                          Creates/fetches every RemoteEvent by name (single list)
        └── Util/
            ├── Signal.luau                       Tiny signal class
            ├── Trove.luau                        Cleanup helper for per-run/per-floor objects
            └── SeededRandom.luau                 Wrapper around Random.new(seed)
```

**Built by hand in Studio (not in Rojo):** `ServerStorage.RoomTemplates` (16 room Models), `ServerStorage.MonsterModels` (8 rigs), `ReplicatedStorage.Assets` (Candy, Door, Wardrobe, Bed, particles, sounds), the Lobby and Rooftop in `Workspace`. Keep `default.project.json` from overwriting these (`$ignoreUnknownInstances: true`).

**Room template contract (every room Model must have):**
- `PrimaryPart` = `Entrance` (a 1-stud invisible part at the door you came in through)
- `Exit` part (where the next room's Entrance snaps to; its door goes here)
- `Sockets` folder with Attachment-holding parts named `Candy`, `Hide`, `MonsterSpawn`, `Alcove` (optional), `PuzzleProp` (puzzle rooms)
- Attributes: `TemplateId` (string), `MinFloor`, `MaxFloor` (numbers)

---

## 2. Data model

DataStore name `SpookyStairs_v1`, key `Player_<UserId>`.

```luau
export type Profile = {
	version: number,              -- schema version, currently 1
	candy: number,
	bestFloor: number,
	checkpointFloor: number,      -- 0 | 10 | 20 | 30 | 40
	flashlightLevel: number,      -- 1..3
	perks: { [string]: boolean },
	cards: { [string]: { normal: boolean, golden: boolean } },
	cosmetics: { [string]: boolean },
	midnightUnlocked: boolean,
	settings: { lessSpooky: boolean },
	stats: { runs: number, floorsCleared: number, timesScared: number },
}

DEFAULT_PROFILE = {
	version = 1, candy = 0, bestFloor = 0, checkpointFloor = 0, flashlightLevel = 1,
	perks = {}, cards = {}, cosmetics = {}, midnightUnlocked = false,
	settings = { lessSpooky = false },
	stats = { runs = 0, floorsCleared = 0, timesScared = 0 },
}
```

Rules:
- `DataService` uses `UpdateAsync` with a session lock (`lockJobId`, `lockTime`); lock older than 5 min is stealable.
- All reads/writes wrapped in `pcall`, 3 retries with backoff (1 s, 2 s, 4 s). If load fails: kick with a friendly message, never play on a blank profile (prevents overwriting good data).
- Autosave every 60 s, on checkpoint, on purchase, on `PlayerRemoving`, and in `game:BindToClose` (parallel saves, wait up to 25 s).
- `migrate(profile)` fills missing fields from `DEFAULT_PROFILE` and bumps `version` — runs on every load.
- Candy is clamped to `0..Config.MaxCandy` (999,999) on every write.

---

## 3. Network map

All remotes created in `shared/Remotes.luau`. Every client→server handler goes through `RemoteGuard.wrap(name, rateLimitPerSec, validator, handler)`, which drops the call (and logs once) on type failure or rate-limit breach.

| Remote | Dir | Payload | Server validation | Rate limit |
|---|---|---|---|---|
| `RequestOpenDoor` | C→S | — | Player in a run, alive, within 10 studs of current room's exit door, door not already opening | 2/s |
| `RequestHide` | C→S | `spotId: string` | Spot belongs to player's current room, within 6 studs, unoccupied, player not already hidden | 4/s |
| `RequestUnhide` | C→S | — | Player is hidden | 4/s |
| `SetFlashlight` | C→S | `on: boolean` | Boolean; battery > 0 to turn on | 5/s |
| `RequestCollect` | C→S | `candyId: string` | Candy exists in current/next room, not taken, within 8 studs | 15/s |
| `RequestRevive` | C→S | `targetUserId: number` | Same run, target scared (ghost state), within 8 studs, reviver not scared | 2/s |
| `SubmitPuzzle` | C→S | `answer: number \| {number}` | Player in puzzle room, puzzle unsolved, answer shape matches puzzle type, max 3 wrong tries per 10 s | 2/s |
| `SetCrouch` | C→S | `on: boolean` | Boolean | 5/s |
| `RequestPurchase` | C→S | `itemId: string` | Item in `Config.Shop`, not owned (or stackable), enough candy, player in lobby or Safe Suite | 2/s |
| `SetSetting` | C→S | `key: string, value: boolean` | Key in allowed list (`lessSpooky`) | 2/s |
| `RequestQueue` / `LeaveQueue` | C→S | — | Player in lobby | 2/s |
| `StateSync` | S→C | full player view (hearts, floor, candy, battery, partyIds) | — | on change |
| `FloorChanged` | S→C | `floor, roomTemplateId` | — | — |
| `MonsterEvent` | S→C | `monsterId, phase ("signal"/"act"/"leave"), data` | — | — |
| `RewardGranted` | S→C | `kind ("candy"/"card"/"golden"/"badge"), amount/id` | — | — |
| `PlayerScared` | S→C | `userId` | — | — |

**Never sent from the client:** candy amounts, floor numbers, hit results, prices, card ids.

**Flashlight battery:** simulated on the server (drains `Config.BatteryDrainPerSec` while on, recharges in Safe Suites and from battery pickups). Client shows a predicted ring and corrects on `StateSync`.

---

## 4. Build order (each milestone is playable on its own)

| # | Milestone | Done when |
|---|---|---|
| **M1** | Skeleton: Rojo project, Config/Types/Remotes, DataService, RemoteGuard, boot scripts | Join → profile loads, candy test-command adds 10, rejoin → candy persists |
| **M2** | Endless floors: FloorGenerator + RunManager (solo), 3 test rooms (greybox), doors, floor counter | Walk through 30+ random rooms; only 3 floors exist at once; no gaps or overlaps |
| **M3** | Candy + HUD: candy sockets, RequestCollect, RewardService, HUDController, basic FeedbackController (pop + sound) | Collecting feels good; candy saves; HUD readable on phone emulator |
| **M4** | First two monsters + hiding: MonsterDirector, Monster interface, Sock Goblin, Giggle Ghost, wardrobes, hearts, scared-silly, Safe Suite checkpoint at 10 | Hiding works, getting caught is funny not scary, checkpoint resume works after rejoin |
| **M5** | Flashlight: battery, FlashlightController, Portrait Peepers + Bat Butler | Flashlight is useful and readable on touch |
| **M6** | Remaining monsters: Pumpkin Rolly, Snoring Giant (crouch), Vacuum Maid (chase), Mr. Drippy | Each monster telegraphs ≥2 s before acting; all beatable on phone |
| **M7** | Puzzles: PuzzleService, counting + pattern rooms | ~1 in 6 floors is a puzzle; wrong answers never trap the player |
| **M8** | Progression: Monster Cards + golden rolls, CardBook UI, shop (flashlight levels, perks), floors to 50, rooftop, badges, Midnight Mode flag | Full 0→50 run possible for a free player |
| **M9** | Party play: PartyService elevator, shared doors with 8 s window, high-five revive, +10% party candy | 2–4 players complete floors together; no one gets left behind |
| **M10** | Juice + onboarding pass (Stage 5): full juice table, no-text tutorial, Less Spooky toggle, guidance trail | Spec §4 juice table fully hooked up; a new player reaches door 3 in < 30 s |
| **M11** | Polish + ship: game passes (cosmetic), performance pass, Stage 6 review, kid playtest fixes | Checklist all PASS; verdict SHIP |

**Halloween cut (if needed by Oct 28):** ship M1–M8 solo + M10, with 30 floors and 6 monsters. M9 (party) ships as the first update.

---

## 5. Risks and how the plan handles them

| Risk | Prevention |
|---|---|
| **Exploits** (fly to exit, spam collect, fake revives) | Server checks distance + room membership on every remote; RemoteGuard rate limits; server decides catches; candy only in RewardService |
| **Data loss** | Session locking, retries, refuse to play on failed load, BindToClose saves, version + migrate |
| **Performance on phones** | Max 3 rooms loaded; Trove cleans each floor; particles pooled; `Config.LowEnd` halves particles when frame time is high; StreamingEnabled on |
| **Rooms overlapping / dead ends** | Every template has Entrance/Exit contract; generator rejects a template whose bounding box intersects the previous two rooms (try next); a fallback straight hallway always fits |
| **Too scary for kids** | 2-second minimum signal in every monster's `signal` phase (asserted in MonsterDirector); Less Spooky toggle; scare sounds capped below music |
| **Players stuck** (puzzle, hidden forever, soft-lock) | Puzzle allows unlimited tries with cooldown; auto-unhide after 20 s; `/stuck` button in settings teleports to current room entrance |
| **Rojo overwriting hand-built assets** | Assets live in ServerStorage/ReplicatedStorage.Assets with `$ignoreUnknownInstances: true` |

---

## 6. Interfaces Claude Code must follow

**Service module shape**
```luau
local Service = {}
function Service:Init() end   -- create state, connect remotes (no yielding on other services)
function Service:Start() end  -- may use other services
return Service
```

**Monster module shape**
```luau
export type MonsterModule = {
	id: string,
	-- called by MonsterDirector; must spend >= Config.MinSignalSeconds in signal phase
	run: (ctx: MonsterContext) -> (),   -- ctx has room, players, rng, fire(phase, data), scare(player), isHidden(player), isLit(player, target)
}
```

**Config is the only place for numbers.** No magic numbers in services (prices, timings, distances, chances all in `Config.luau`).
