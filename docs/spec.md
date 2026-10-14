# Game Spec: Spooky Stairs

Oct 14, 2026 · @Yuk

Spooky Stairs is a funny-spooky climb through 50 randomly built floors of a haunted hotel for ages 9–12, scoped as a 2-week MVP to launch around October 28 and stay live year-round.

## 1. Pitch

- **One sentence:** You are a brave kid who climbs the haunted Gloomwood Grand Hotel to reach the rooftop Halloween party before the Clock Ghost strikes midnight.
- **Target age band:** 9–12
- **Genre skeleton:** room-by-room survival climb (inspired by Doors' structure only)
- **The twist that makes it ours:** the monsters are *pranksters*, not killers. Get caught and you're "scared silly" (a funny cartoon reaction) and lose some candy, never a death screen. Every monster has a goofy weakness you can use against it, and each one you outsmart goes into your **Monster Card Book**.
- **How it differs from Doors:** bright storybook-spooky art instead of dark realism, humor instead of dread, puzzles that use counting and patterns, co-op revives, and a collection meta-game.
- **Fun formula score:** clarity 5, juice 4, progress 4, social 4, theme 5 = **22/25**

## 2. Core loop

- **Core verb:** open the next door.
- **Loop:** enter a room → spot the danger or the puzzle → grab candy → find the glowing door → open it → next floor (about 20–40 seconds per floor).

**First 30 seconds:**

1. 0 s: Player spawns in the hotel lobby. A friendly ghost bellhop waves; a big glowing elevator has a pulsing arrow above it.
2. 5 s: Player walks into the elevator. Doors close with a *ding*, lights flicker purple, and the floor counter rolls to **1**.
3. 10 s: Floor 1 is a hallway with 5 candies lined up toward a glowing door. Each candy pops with a sound and a +1.
4. 18 s: Player opens door 2. A Sock Goblin peeks out of a laundry basket, giggles, and waddles away (no danger yet, just a teaser).
5. 25 s: Floor 2 shows the first wardrobe with a sparkle icon. A Giggle Ghost floats past outside the window as the lights dim, showing "lights flicker = hide" with no text.
6. 30 s: Player reaches door 3 and earns their first Monster Card ("You spotted: Sock Goblin!"), with a card-flip animation and confetti.

## 3. Progression

- **Short loop (seconds):** grab candy (3–8 per floor), open a door, dodge or outsmart a monster.
- **Medium loop (minutes):** reach a checkpoint every 10 floors (a cozy "Safe Suite" with a vending machine), spend candy on upgrades, unlock a new monster card.
- **Long loop (days):** complete the Monster Card Book (8 monsters × normal and golden variants), beat your best floor, reach the rooftop party, then unlock **Midnight Mode** (harder, with new rooms and double candy).
- **Currency:** one only, **Candy**. It buys flashlight upgrades, run perks (bought in the lobby or a Safe Suite), and lobby cosmetics. No second currency in the MVP.
- **Fail state:** losing all 3 **Courage hearts** sends you back to your last Safe Suite checkpoint with half the candy from that stretch. Floors and cards are never lost.

**Unlock table** (pacing: something new every 2–3 minutes in the first 15 minutes)

| When (about) | Requirement | Reward |
| --- | --- | --- |
| 0:30 | Reach floor 3 | First Monster Card: Sock Goblin |
| 2:00 | Reach floor 5 | Giggle Ghost card + first hiding wardrobe |
| 4:00 | Reach floor 10 | Safe Suite 1: vending machine, checkpoint saved |
| 5:00 | 50 candy | Flashlight level 2 (wider beam, scares Portrait Peepers faster) |
| 7:00 | Reach floor 15 | First puzzle room (count the pumpkins to open the lock) |
| 9:00 | Reach floor 20 | Safe Suite 2 + Snoring Giant card |
| 11:00 | 150 candy | Perk: Lucky Socks (Sock Goblin can't slow you once per run) |
| 13:00 | Reach floor 25 | Vacuum Maid chase hallway + her card |
| 15:00 | Reach floor 30 | Safe Suite 3 + lobby trophy for your best floor |
| \~20:00 | Reach floor 40 | Safe Suite 4 + Mr. Drippy card |
| \~25:00 | Reach floor 50 | Rooftop party: fireworks, badge, "Stair Master" title, Midnight Mode unlocked |
| Day 2+ | 400 candy | Flashlight level 3 (beam flickers rainbow, finds hidden candy) |
| Day 2+ | Find golden variants (5% chance per monster) | Golden cards and a shiny lobby name tag |
| Day 3+ | All 8 normal cards | Card Book reward: Ghost Buddy pet that follows you (cosmetic) |

## 4. Juice plan

| Player action | Sound | Particles | UI / numbers | Camera |
| --- | --- | --- | --- | --- |
| Grab candy | Rising "pop" pitch on combos | Wrapper sparkle burst | +1 floats up; counter bounces | none |
| Open door | Creak + spooky organ chord | Dust puff, door number glows | Floor counter rolls up | Slight push forward |
| Hide in wardrobe | Muffled thump | none | Screen edges darken, "safe" eye icon | Peek view through door slats |
| Monster passes by | Signature silly sound (giggle, snore, slurp) | Monster's trail effect | Danger meter wiggles | Gentle shake |
| Scared silly (caught) | Cartoon "boing" + monster laugh | Confetti of candy flying out | Heart cracks with a bounce; "-candy" | Quick zoom, then fade to wardrobe |
| Shine flashlight on a monster | Zap + monster yelp | Sparkles | Monster card glows if new | none |
| Solve puzzle | Chime arpeggio | Lock bursts into bats | "Smart!" stamp | none |
| Reach Safe Suite | Warm jingle, fireplace crackle | Floating hearts | Checkpoint banner, hearts refill | Slow pan of the room |
| New Monster Card | Card flip whoosh + fanfare | Confetti | Full-screen card reveal (tap to dismiss) | none |
| Golden variant | Extra-shiny chime | Gold rain | "GOLDEN!" banner | Shake |
| Revive a friend | High-five slap | Star burst between players | Friend's heart refills | none |
| Reach rooftop | Fireworks, party music | Fireworks | Badge + title reveal | Sweeping skyline shot |

## 5. UI and readability

- **HUD (5 items max):** Courage hearts (top left), floor number (top centre), candy count (top right), flashlight battery ring (bottom right), small guidance arrow toward the glowing door.
- **Guidance:** the exit door always glows orange; a firefly trail appears if the player hasn't moved toward it for 15 seconds.
- **No-text teaching:** danger is always shown by a signal before the monster arrives (lights flicker, music changes, the monster's own sound), and the safe answer is always lit with a sparkle (wardrobe, bed, or flashlight icon).
- **Mobile controls:** default thumbstick + jump, plus two big buttons: Flashlight (bottom right, at least 80×80 px scaled) and Interact/Hide (appears contextually above it). UI uses UIScale and UIAspectRatioConstraint; nothing important within 10% of screen edges (notches).
- **Colour language:** orange = go/exit, purple = danger coming, green = safe, gold = rare.

## 6. Social

- **Party elevator:** 1–4 players ride up together; solo is fully supported and balanced (party runs get +10% candy each, not harder monsters).
- **High-five revive:** a scared-silly player becomes a little wobbly ghost for 10 seconds; any teammate who walks up and taps Interact revives them with 1 heart. Rewards helping, not racing ahead.
- **Shared doors:** any player can open the next door, but the floor only advances for players inside the room within 8 seconds, with a countdown bubble, so no one gets left behind or stuck.
- **Lobby fun:** emote wheel (wave, dance, scared pose), best-floor trophies on display, Monster Card Book stand everyone can browse.
- **Anti-griefing:** players can't block doors (no collision between players), can't steal candy from each other, can't hold doors shut, and can leave a party any time from a Safe Suite.

## 7. Monetization

- **Game passes (cosmetic only):** Glow Costume Pack (glowing skeleton/pumpkin/ghost outfits), Flashlight Colours (rainbow, green slime, galaxy), VIP lobby lounge with a candy fountain (cosmetic seating area).
- **Developer products:** none at MVP. If added later: cosmetic items only. No revives, hearts or skips for Robux.
- **What a free player can fully achieve:** everything that matters. All 50 floors, Midnight Mode, all 8 monster cards (normal and golden), all three flashlight levels and every perk via candy.
- **Not allowed:** paid random items, paid continues, timers pushing purchases, or prompts during a scary moment.

## 8. Safety

- **Player-written text:** none in the MVP. No custom names, signs or notes. Chat uses Roblox's default TextChatService with its built-in filtering.
- **Maturity questionnaire:** answer honestly. Expected: mild fear (cartoon monsters, light suspense), no violence, no blood, no crude humour. Confirm the resulting label on the Creator Hub matches "spooky, not scary" before launch.
- **Never appears:** blood, gore, skulls with realism, death or dying words, weapons, screaming faces, sudden loud screamer jumpscares, darkness the player can't light, real-world scary figures, or anything that mocks a player.
- **Scare rules:** every monster is telegraphed by a signal at least 2 seconds before it acts; scare sounds stay below music volume peaks; a "Less Spooky" toggle in settings brightens rooms and replaces monster sounds with silly ones.

## 9. Session design

- **Target session:** 15–25 minutes (lobby + one run to the next 1–2 Safe Suites).
- **Natural stopping points:** every Safe Suite (every 10 floors) shows a "Checkpoint saved!" banner and a calm room with a door back to the lobby.
- **Leaving is free:** quitting mid-run keeps all candy and cards earned so far; next time you start from your highest Safe Suite.
- **Learning element:** puzzle rooms use counting (count the pumpkins, enter the number), patterns (repeat the candle-light sequence) and colour matching (match portrait frames). About 1 in 6 floors is a puzzle room.
- **Save data (DataStore key `Player_<UserId>`):**

```text
{
  version: 1,
  candy: number,
  bestFloor: number,
  checkpointFloor: number,   -- 0, 10, 20, 30, 40
  flashlightLevel: number,   -- 1..3
  perks: { [perkId]: boolean },
  cards: { [monsterId]: { normal: boolean, golden: boolean } },
  cosmetics: { [itemId]: boolean },
  midnightUnlocked: boolean,
  settings: { lessSpooky: boolean }
}
```

## 10. World and art

- **Setting:** the Gloomwood Grand Hotel, a crooked storybook hotel on a hill where the ghosts throw a rooftop Halloween party every night.
- **Palette and mood:** deep purple and teal walls, warm orange lamp glow, green for safe spots, gold for rare things. Cozy-spooky like a Halloween picture book: chunky shapes, soft lighting, never pitch black.
- **Areas:** Lobby (hub), Floors 1–9 Guest Wing, 10–19 Library and Kitchens, 20–29 Ballroom and Laundry, 30–39 Attic Halls, 40–49 Clock Tower, 50 Rooftop Party.

**Monsters (8 for MVP)**

| Monster | First floor | What it does | Signal | How to beat it |
| --- | --- | --- | --- | --- |
| Sock Goblin | 3 | Steals your shoes so you slip and slide for 5 s | Giggle from a laundry basket | Jump over its dash |
| Giggle Ghost | 5 | Floats through the floor tickling anyone in the open | Lights flicker purple | Hide in a wardrobe or under a bed |
| Portrait Peepers | 8 | Painted eyes follow you; they creep closer when you look away | Frames creak | Keep your flashlight on them while you walk |
| Pumpkin Rolly | 12 | Giant pumpkin rolls down long hallways | Thumping drumbeat | Duck into a side alcove |
| Bat Butler | 16 | Swoops in to snatch candy | Flapping + tiny bell | Flash him with your flashlight |
| Snoring Giant | 20 | Sleeps in the room; wakes on loud steps | Snoring | Walk slowly (crouch button) past him |
| Vacuum Maid | 25 | Chases you down a hallway sucking up everything | Vacuum whine rising | Run, grab speed candy, slam the door |
| Mr. Drippy | 40 | Leaves slime puddles that stick you in place | Slurp sound, green glow | Follow the clean path; flashlight dries puddles |

**Room templates (16 for MVP):** straight hallway, L-hallway, guest bedroom (bed + wardrobe), double bedroom, bathroom, library (book stacks), kitchen, dining hall, ballroom, laundry room, linen closet corridor, portrait gallery, attic crawl, clock room, puzzle room A (counting), puzzle room B (pattern). The generator picks templates by floor range, never repeats the same template twice in a row, and places candy, hiding spots and one monster event per floor.

**Asset list**

- Models: 16 room templates (built in Studio), 8 monsters (simple chunky rigs), doors with numbers, wardrobes, beds, candy, flashlight, Safe Suite, lobby, rooftop.
- Sounds: 8 monster signature sounds, door creak, candy pop scale, chime, fanfare, music for lobby, run (3 intensity layers) and rooftop. Use Roblox's licensed audio library or original sound.
- UI: hearts, candy icon, battery ring, 16 monster card images (normal + golden), badges.
- Source: everything original or from the Creator Store with scripts removed and checked.

## 11. Technical architecture

The server owns everything that matters: it builds floors from a per-run seed, decides when monsters act and who they catch, and awards all candy and cards. Clients only render effects and send input. Stage 3 will expand this into a full Rojo file tree and build order.

**Server services (ModuleScripts in `src/server`)**

- `DataService`: load/save with pcall, retries, session locking and autosave every 60 s; schema from section 9.
- `PartyService`: lobby elevator queue, party of 1–4, teleport into a run.
- `FloorGenerator`: seeded random choice of room templates per floor range; places candy, hiding spots, door and the floor's monster event.
- `RunManager`: tracks floor, hearts, revives, checkpoint saves, scared-silly and Safe Suite logic.
- `MonsterDirector`: runs each monster's state machine (signal → act → leave) on the server; checks hiding and flashlight state.
- `RewardService`: the only place candy and cards are granted; golden variant rolls (5%).
- `ShopService`: candy purchases (flashlight levels, perks) with server-side price checks; game pass ownership via MarketplaceService.

**Client controllers (`src/client`)**

- `FeedbackController` (all juice), `HUDController`, `FlashlightController` (input + beam visuals), `GuidanceController` (glow and firefly trail), `CardBookUI`, `SettingsUI` (Less Spooky).

**Shared (`src/shared`)**

- `Config` (prices, pacing, monster tuning), `MonsterDefs`, `RoomDefs`, `Types`.

**Remotes (all validated on the server)**

| Remote | Direction | Payload | Server checks |
| --- | --- | --- | --- |
| `RequestOpenDoor` | client → server | none | Player is in the room and near the door; cooldown 1 s |
| `RequestHide` | client → server | hidingSpot | Spot exists in current room, within 6 studs, not occupied |
| `SetFlashlight` | client → server | on: boolean | Battery > 0; rate-limit 5/s |
| `RequestCollect` | client → server | candyId | Candy exists, not taken, player within 8 studs |
| `RequestRevive` | client → server | targetUserId | Same party, target is scared, within 8 studs |
| `RequestPurchase` | client → server | itemId | Item exists, enough candy, not already owned |
| `FloorChanged`, `MonsterEvent`, `RewardGranted`, `StateSync` | server → client | event data | Server-sent only |

**Performance:** only the current floor, the next floor and one behind exist at a time (older floors are destroyed); effects are pooled; particle counts drop on low-end devices.

## 12. Success metrics

- Time to first fun: under 30 s (first candy pop by 10 s, first door by 20 s)
- Floor 10 reached by at least 60% of new players
- Average session: 15+ minutes
- Day-1 return rate: 20%+ (adjust once real data comes in)
- Kid playtest: 3 of 3 kids want to "go again" after their first run; no kid says it was too scary

## Later (not in the 2-week MVP)

- Floors 51–100 and a second hotel (Haunted Cruise Ship or Spooky School)
- Weekly "Mystery Floor" with a limited monster card
- More monsters and room templates (aim for 30+ rooms)
- Pet Ghost Buddies with small helper abilities (cosmetic first)
- Seasonal reskins after Halloween: Winter Hotel, Easter egg hunt floors
- Leaderboards for fastest Safe Suite times

## 8-pillar self-check

| Pillar | How the spec meets it |
| --- | --- |
| 1. One-verb core loop | "Open the next door"; first candy, door and card all inside 30 s with no text. |
| 2. Three loops of progress | Candy and doors (seconds), Safe Suites and upgrades (minutes), Card Book, rooftop and Midnight Mode (days). |
| 3. Juice and feedback | Juice table covers every player action, with sound, particles, UI and camera. |
| 4. Readable at a glance | 5-item HUD, colour language, orange glowing exit, monsters always telegraphed by a signal. |
| 5. Better with friends | Party elevator, high-five revives, +10% party candy, shared doors with no one left behind. |
| 6. Fair and honest | Only cosmetics for Robux; free players get everything that affects play; no paid randomness. |
| 7. Safe by design | No player text, cartoon-only scares, 2-second warnings, Less Spooky toggle, honest maturity answers. |
| 8. Healthy sessions | Safe Suite every 10 floors, leaving loses nothing, puzzle rooms add counting and patterns. |

**Weakest pillar to watch:** 5 (social). The co-op is a bonus rather than the core, so check in playtests that friends actually help each other. If not, add a two-player door puzzle every 10 floors.
