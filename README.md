# Spooky Stairs — Claude Code starter kit

Drop these files into a new folder (or your Rojo repo), then follow the steps.

## 1. One-time setup (≈15 min)

1. **Tools:** Rojo (you have it), plus Selene and StyLua. With Rokit: `rokit add Kampfkarren/selene` and `rokit add JohnnyMorganz/StyLua`.
2. **Spec:** open the "Game Spec: Spooky Stairs" doc in Claude → export as Markdown → save as `docs/spec.md`. (`docs/plan.md` is already here.)
3. **Git:** `git init && git add . && git commit -m "Spooky Stairs kit"`. Commit after every milestone so you can always roll back.
4. **Studio MCP (lets Claude look inside Studio and run playtests):** in Roblox Studio click **⋯ → Manage MCP Servers → Enable Studio as MCP server**, then connect Claude Code using the command or JSON shown on the Creator Hub page "Connect to the Roblox Studio MCP server".
5. **Start:** open a terminal in this folder → `rojo serve` in one tab, `claude` in another. Connect the Rojo plugin in Studio.

## 2. The loop (one milestone per session)

| You type | What happens |
|---|---|
| `/build-milestone` | Claude reads spec + plan + progress, builds the next milestone, lints, builds the place, updates progress |
| `/playtest` | Claude runs a smoke test in Studio through MCP and reports PASS/FAIL |
| *you play it* | 5–10 min in Studio, desktop + phone emulator. Tick "Playtested" in `docs/progress.md` |
| `/clear` | fresh context for the next milestone (keeps quality high) |

After M9: `/juice-pass`. Before release: `/ship-check` (independent reviewer agent), then kid playtest, then **you** publish.

## 3. What's in here

- `CLAUDE.md` — rules Claude Code follows every session
- `docs/plan.md` — Stage 3 technical plan (file tree, data, remotes, milestones, risks)
- `docs/progress.md`, `docs/lessons.md` — memory between sessions
- `.claude/skills/` — `/build-milestone`, `/juice-pass`, `/playtest`, `/ship-check`
- `.claude/agents/roblox-reviewer.md` — read-only Stage 6 critic
- `.claude/settings.json` + `.claude/hooks/lint-luau.sh` — auto-format and lint every edit; blocks `rojo upload`
- `default.project.json`, `selene.toml`, `stylua.toml`

## 4. Reuse for the next game

Copy this kit, swap `docs/spec.md` and `docs/plan.md` (run Stage 3 on the new spec), keep `src/shared/Util`, `DataService`, `RemoteGuard` and `FeedbackController`. Add what you learned to `docs/lessons.md`.
