# Spooky Stairs — progress

Claude Code ticks a milestone and adds notes after `/build-milestone`. You tick "Playtested" after playing it yourself.

| # | Milestone | Built | Playtested | Notes |
|---|---|---|---|---|
| M1 | Skeleton + DataService + RemoteGuard | [x] | [x] | 2026-10-14. Config/Types/Remotes, Signal/Trove/SeededRandom, DataService (session lock, retries, autosave, BindToClose), RemoteGuard (token bucket + Check helpers), minimal RewardService.GrantCandy, Studio-only `/candy` test command (DevCommands.luau, not in plan tree). No client controllers yet. |
| M2 | Endless floors (solo, greybox rooms) | [x] | [ ] | 2026-10-14. FloorGenerator (contract check, seeded weighted pick, no repeats, overlap/heading/drift rejection, fallback StraightHall), RunManager (solo run per player in its own lane, 3 rooms max, entrance seal behind, RequestOpenDoor via RemoteGuard, bestFloor/floorsCleared/runs stats), RoomDefs, InteractController (door prompt), HUDController (floor badge). Greybox templates via `tools/BuildGreyboxRooms.luau`. Studio `/skip` command. Runs start at floor 1 (checkpoint resume is M4); doors stop at floor 50 (rooftop is M8). Placement rules simulated offline: 2000 seeds x 50 floors, 0 overlaps, 0 fallbacks, max drift 420 studs. |
| M3 | Candy + HUD + basic feedback | [ ] | [ ] | |
| M4 | Sock Goblin, Giggle Ghost, hiding, hearts, Safe Suite 10 | [ ] | [ ] | |
| M5 | Flashlight + Portrait Peepers + Bat Butler | [ ] | [ ] | |
| M6 | Rolly, Snoring Giant, Vacuum Maid, Mr. Drippy | [ ] | [ ] | |
| M7 | Puzzle rooms | [ ] | [ ] | |
| M8 | Cards, shop, floors to 50, rooftop, badges | [ ] | [ ] | |
| M9 | Party play + revives | [ ] | [ ] | |
| M10 | Juice + onboarding (Stage 5) | [ ] | [ ] | |
| M11 | Polish, passes, Stage 6 review, kid playtest | [ ] | [ ] | |

## Hand-built in Studio (checklist)
- [ ] 3 greybox room templates (for M2): run `tools/BuildGreyboxRooms.luau` in the Command Bar, then save. Then all 16
- [ ] Optional: `ReplicatedStorage.Assets.Door` Model (PrimaryPart = door panel, pivot = door centre, facing like Exit). Until then a greybox orange door is used
- [ ] Lobby + elevator
- [ ] Safe Suite room
- [ ] 8 monster rigs
- [ ] Rooftop party
- [ ] Sounds + card images

## Open issues
- `.claude/` kit folder (skills `/build-milestone`, `/playtest`, lint hook, reviewer agent) mentioned in README is not in the repo; M1 was linted by hand. Copy it in from the starter kit.
- No Luau type checker (luau-lsp) installed, so `--!strict` errors only show in Studio's Script Analysis. Check it after syncing.

## Ideas for later
