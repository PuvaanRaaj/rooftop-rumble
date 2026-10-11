# Rooftop Rumble

## Project Overview

Browser-first local 3D party brawler for 2–4 fighters. Godot 4.5.2 and GDScript implement gameplay; a static HTML page launches a single-threaded WebAssembly export. Vercel serves the generated `dist/` directory.

## Common Commands

- Install: `npm install` (Node.js 22+; `curl` and `unzip` required).
- Build browser release: `npm run build`.
- Serve browser release: `npm run dev` after building.
- Native launch: `godot --path .` or `Launch Rooftop Rumble.command`.
- Import/parse: `godot --headless --path . --editor --import --quit`.
- Rules: `godot --headless --path . --script tests/test_match.gd`.
- Gameplay: `godot --headless --path . --script tests/test_gameplay.gd`.
- Throws: `godot --headless --path . --fixed-fps 60 --script tests/test_throw.gd`.
- Props: `godot --headless --path . --fixed-fps 60 --script tests/test_props.gd`.
- CPU decisions: `godot --headless --path . --fixed-fps 60 --script tests/test_bot_pacing.gd`.
- CPU match: `godot --headless --path . --fixed-fps 60 --script tests/test_bots.gd`.
- Native input: `godot --path . --script tests/test_input.gd`.
- No standalone GDScript linter is configured; import and runtime suites catch engine errors.

## Architecture

- `scenes/main.tscn` starts `scripts/game/game_manager.gd`.
- Game manager coordinates arena, fighters, rounds, hazards, camera, effects, and UI.
- `scripts/player/`, `scripts/ai/`, and `scripts/multiplayer/` implement movement, CPU decisions, and independent local input.
- `web/index.html` embeds `dist/game/index.html`; web build helpers export the Godot project and copy the browser page into `dist/`.
- `export_presets.cfg` defines the single-threaded Web preset; `vercel.json` defines hosting.
- Read `ARCHITECTURE.md` and `GAME_DESIGN.md` for gameplay details.

## Working Style

- Plan before coding for tasks with 3+ steps or architectural impact; re-plan when the approach fails.
- Use subagents for research, exploration, and independent analysis.
- Verify before done: run relevant suites, inspect browser rendering/input, and check engine logs.
- Fix reported bugs autonomously and verify the failing behavior.
- Touch only what is necessary; avoid unrelated refactors.

## Commit Message Format

Use `<type>(<scope>): <subject>`, imperative and at most 72 characters. Types: feat, fix, refactor, chore, docs, test.
Include what changed, why, and rollback steps for nontrivial changes. Add `Risk-Level: low|medium|high` and an `AI-Agent` trailer that identifies the generating model accurately.

## Decisions

Record non-obvious reasons in `memory/DECISIONS.md`.

## Testing Notes

Headless suites skip audio. Native synthetic key events do not prove browser input or physical keyboard rollover. Verify the exported game in an actual WebGL browser before publishing. Physical controllers and human gameplay feel require manual playtesting.
Keep `.tools/`, `.godot/`, `dist/`, `.vercel/`, and environment files out of Git.
