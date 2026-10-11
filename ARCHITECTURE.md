# Architecture

## Runtime structure

`scenes/main.tscn` starts `RumbleGame`, which creates the environment, lighting, arena, fixed camera, effects, event manager, and UI. Geometry and materials are generated procedurally. The physics tick is 60 Hz and the renderer is Godot's GL Compatibility backend.

| Script | Responsibility |
|---|---|
| `scripts/game/game_manager.gd` | States, crew spawning, round transition, survivor settlement, HUD updates |
| `scripts/game/round_manager.gd` | Scores and first-to-three match resolution |
| `scripts/player/player_controller.gd` | Character movement, attacks, grab tether, carry/throw, elimination and character animation |
| `scripts/multiplayer/input_router.gd` | Per-source physical keyboard and gamepad sampling; action press edges |
| `scripts/ai/bot_controller.gd` | Committed action plans, prop seeking/throws, imperfect aim, edge avoidance |
| `scripts/arena/arena.gd` | Roofs, collision, skyline, spawn points, prop reset, safe-position queries |
| `scripts/objects/physics_object.gd` | Rigid-body props, carrying, throwing and impact knockback |
| `scripts/events/event_manager.gd` | Warning, timed activation, wind/slip/collapse, cleanup |
| `scripts/game/camera_controller.gd` | Fixed angled view and impact shake |
| `scripts/game/effects.gd` | Procedural impact fragments and generated PCM tones |
| `scripts/ui/ui_manager.gd` | Menus, setup validation, countdown, HUD, announcements, results |

Combat and grabbing live in the player script for this small project. They are implemented systems, but not separate `CombatController` or `GrabSystem` classes. Split them only if future mechanics justify the additional coordination.

## Input and physics flow

Each active fighter samples its assigned source or CPU. Test input can replace sampling through `input_override`. Movement is `Vector2(x, z)`: right is positive x and down is positive z, matching the camera's orientation. Input uses physical keys rather than shared project actions, allowing two keyboard layouts to operate independently. Gamepad movement applies a 20% radial dead zone. Jump, punch, shove, and grab trigger on press edges; static history is keyed by slot and device and cleared between rounds.

Fighters are `CharacterBody3D` nodes with capsule collision. Ground acceleration and deceleration approach a target velocity, with reduced air control. Gravity changes vertical velocity. A separate knockback vector is added during `move_and_slide()` and decays afterward, so ordinary walking cannot immediately erase an impact. Wind accumulates into motion; slippery movement reduces acceleration. Stun temporarily suppresses voluntary movement and attacks.

Attack checks scan living fighters by distance and facing direction. A hit releases affected grabs, adds horizontal knockback, lifts vertical velocity, and applies stun. The player emits an `impact` signal for visual/audio feedback and camera shake. Crossing y = −8 releases held targets, disables collisions and visibility, and emits `knocked_out`.

## Grabs and throwable objects

A fighter records a single held opponent or prop. Opponent grabbing sets reciprocal `grabbed_target` / `grabbed_by` references. The grabbed fighter receives a damped pull toward a point 1.05 units ahead of the holder; this approximates a constraint without a physics joint between kinematic bodies. Grabs expire around 2.2 seconds, break if stretched past 3 units, and escape faster when jump/punch is pressed. Receiving a hit releases both sides. Grab or Shove while holding starts a timed throw animation. `release_hold(true)` remains the immediate low-level physical release used at the animation release point. Hits, target escape, elimination, and round/menu cleanup cancel pending throws.

Props are `RigidBody3D` nodes with shape-appropriate collision, bounce, friction, and continuous collision detection. Pickup freezes their simulation and disables collision while the holder positions them above/in front of the character. Release restores collision and simulation. Throws assign velocity and activate a short danger timer; contact with another fighter applies knockback and consumes the damaging hit. This avoids unstable joints, self-collision explosions, and unlimited repeated damage from one thrown prop. The trade-off is that carried objects do not physically collide with scenery until released.

## States and fair results

`RumbleGame` uses `MENU`, `COUNTDOWN`, `PLAYING`, `RESULTS`, and `WINNER`. UI signals request start, next round/replay, and menu return. Countdown disables fighter input until play starts. While playing, a round resolves only after zero or one survivor persists for 0.6 seconds, permitting near-simultaneous falls to settle.

`RumbleRounds.resolve()` returns −2 to continue with multiple survivors, −1 for a draw, or the winning index and increments that fighter's score. `champion()` finds a score of at least three. Round start releases old holds, removes old fighters, clears input history, restores roofs, replaces props, creates fresh fighters, and starts a new countdown. Match replay also resets scores. Menu return stops events and clears fighters.

## Event lifecycle

`RumbleEvents` owns the event clock and exposes `wind` and `slippery` to the manager. After 20 seconds it randomly chooses a hazard, emits a text warning, and waits 2.5 seconds. Activation lasts 5.5 seconds. Collapse additionally tints and shakes one side roof before disabling its collision. Cleanup clears force/sliding and restores that roof's position, appearance, visibility, and collision. Stopping events during transitions uses the same cleanup path.

The slippery mechanic reduces character acceleration and temporarily duplicates prop materials with reduced friction; original materials restore at cleanup. Wind chooses a direction at warning time and shows a matching directional text arrow, then accumulates into external player momentum. Environment effects are intentionally lightweight and require visual playtesting for readability.

## Verification boundary

`tests/test_match.gd` tests score resolution without a running arena. `tests/test_gameplay.gd` instantiates the main scene and exercises movement with injected actions, direct combat, grabs, props, hazard activation/reset, elimination, complete match resolution, replay, and menu cleanup. Headless editor import checks script/resource compatibility. These checks cannot establish actual simultaneous keyboard rollover, controller mapping on physical hardware, audio quality, visual readability, or whether friends find the mechanics fun. Use the manual checklist in the README for those checks.

## Browser delivery

`npm run build` exports the same game through the `Web` preset to `dist/game/index.html` and copies `web/` to the static site root. The outer page creates a same-origin iframe on demand. Its custom engine shell reports `rooftop-ready` after engine startup or `rooftop-error` on failure; the outer page checks the message origin and source before updating launch status.

The export uses single-threaded WebAssembly and WebGL 2. Native Quit is hidden in web builds, and setup explains browser gamepad discovery. Vercel runs the build from source using `vercel.json`; no backend or environment secrets are required. Keep generated binaries out of Git. See `memory/DECISIONS.md` for the browser-first decision.


## CPU intent and mistakes

Bots sample world positions at decision points, commit to a short approach or aim, then reassess. Full movement speed remains available; pauses, preparation, recovery, missed aim, and prop interaction give actions a readable rhythm. They use normal player actions for grabbing, attacking, and throwing, and do not inspect future or current human input. Tests check decision behavior and physical prop interaction rather than reduced speed.
