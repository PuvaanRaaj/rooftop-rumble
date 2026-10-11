# Decisions

## Browser-first release (2026-10-11)

Export the existing Godot game to single-threaded WebAssembly with the Compatibility renderer. This preserves the game's tested physics, rules, CPU opponents, and local multiplayer controls. A static HTML launch page embeds the exported game. Vercel builds the export from source and serves `dist/`; no game server is required.

Keep native Godot play available for development. Browser-first means desktop browsers with keyboard or controllers; touch controls and online multiplayer are outside this release.

Sources: [Godot web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [Vercel configuration](https://vercel.com/docs/project-configuration/vercel-json).


## First visual polish (2026-10-11)

The screenshot showed excessive empty sky, tiny fighters, and letterboxing at narrower browser widths. Reduce the orthographic span from 20 to 15 units while fitting at least 24 horizontal units to keep satellite roofs visible. Let the viewport expand with its container and keep the browser embed at 16:10, including below the responsive breakpoint.

Improve current art through suit/face detail, roof seams, architectural trim, quieter skyline colors, linear tonemapping, and 2x MSAA. Batch facade/city windows to keep the browser scene lightweight. Keep physical arena bounds and combat unchanged during this focused visual pass; larger playable maps belong to the proposed content upgrade.


## Contextual throws and distinct props (2026-10-11)

Use the existing Grab button for pickup and a second tap for a timed throw; preserve Shove as a throw shortcut. Keep `release_hold(true)` immediate so physics integration and existing callers retain a predictable primitive; `begin_throw()` owns wind-up, locked aim, one release, and follow-through. Release props in front of the fighter to avoid throwing through their collider. Cancel pending actions during hits, escape, elimination, inactive rounds, and menu/reset cleanup.

Differentiate eight props through physical behavior and recognizable modeling: three breakable wooden crates, three rolling metal barrels, and two bouncing beach balls. Shards remain children of the broken crate so arena reset owns all effects and cannot leave debris behind. Guard actual collision callbacks against changing another carried body's physics state during query flushing.


## Beginner CPU pacing (2026-10-11; superseded)

The user found the default CPU overwhelming: it chased at full human speed into contact and attacked every 0.35–0.9 seconds. Give the CPU 50% movement input, two seconds of grace after countdown, 1.4-unit chase stopping distance, retreat below 0.9 units, deliberate in-range reaction delay, and half-second rests after attacks. Keep edge avoidance active during rests and human speed unchanged. Stationary bots face opponents without changing locked throw aim. This is the default; harder difficulty tiers can be added separately.


## Natural decisions at normal speed (2026-10-11)

The user clarified that opponents should make human-like decisions and mistakes, rather than have reduced movement strength. Restore full movement speed and replace chasing with short plans: seek/grab a prop, approach an opponent, prepare one attack, aim/throw, recover, or reposition. Plans remember a sampled position and use small aim errors; wind-up does not track a dodging opponent. Around 55% of decisions prefer an available nearby prop, with some sidestepping/hesitation. Combat still uses the existing player actions and physics. No human input or velocity prediction is used.

Keep attack actions mutually exclusive and cancel/reassess invalid targets or interrupted plans. Preserve throw aim locks and edge checks. Automated dodge and actual pickup/throw tests verify exploitable mistakes and full-speed parity; natural feel still needs human feedback.

AI references must be both valid and inside the scene tree before reading world transforms. Round/menu cleanup can detach a prop before freeing it; validity checks alone do not prevent transform errors.
