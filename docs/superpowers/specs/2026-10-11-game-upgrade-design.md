# Rooftop Rumble — graphics and gameplay upgrade

Status: broader design awaiting user review. Colorful cartoon action is selected. A separately requested first visual pass improves camera framing and current arena/fighter detail; maps, throws, powers, and campaign remain proposed.

## Goal

Make the browser game look and feel like a colorful action game: expressive characters, physical animated throws, distinct maps, hero powers, and a playable solo progression. Preserve the existing local party mode and browser export.

## Recommended direction and alternatives

Use colorful cartoon action: rounded heroes, readable silhouettes, saturated accents, softer lighting, detailed rooftop props, and punchy effects. Favor art direction and animation over expensive rendering effects.

A neon cyberpunk direction could use stronger contrasts, signs, and luminous power trails, but needs more care to keep fighters readable. More realistic urban art would need a larger asset pipeline and animation effort; it is a later alternative. The user selected colorful cartoon action.

## Deliverable 1: visual style and animated interaction

- Replace plain colored block fighters with four recognizable procedural designs, facial features, gloves, boots, and hero-specific accessories. Keep player-slot indicators distinct from hero identity.
- Add idle breathing, a legged run cycle, jump/landing poses, directional punch, carrying pose, throw anticipation, release, and recovery.
- Build textured-looking geometry through material contrast and modeled detail: crate slats, barrel bands, vents, roof tiles, edge markings, windows, signs, cables, and skyline layers.
- Use controlled lighting and roughness to avoid the current washed-out bright surfaces. Keep the Compatibility renderer and single-thread web export.
- Add readable power rings/trails, throw trails, impact rings, and bounded camera shake. Pool or cap short-lived effects.
- Refresh the browser artwork from the actual new game after verification.

### Easier grab and throw

Keyboard 1: WASD move, Space jump/escape, F punch, E grab/throw, Q power.
Keyboard 2: arrows move, Shift jump/escape, K punch, Enter grab/throw, O power.
Gamepad: left stick move, bottom face button jump, left face button punch, top face button grab/throw, right shoulder power.

Keep G/L/right-face-button as shove when empty-handed and throw when holding, so existing players retain their controls. Escape still returns to the menu.

1. Face a nearby prop or opponent; tap Grab to pick up or catch them.
2. While holding, movement aims the throw; a ground arrow shows its direction.
3. Tap the same button again to throw. The HUD explicitly changes from GRAB to THROW.
4. Play a roughly 0.18-second wind-up, visibly moving hands and held object backward/upward; release once at the animation's release point.
5. Propel the real rigid body along an upward arc, add spin, then let physics handle flight, collisions, and bounce. Follow through for roughly 0.2 seconds.

Lock aim at throw initiation for a readable committed action. Do not use a decorative projectile disconnected from the carried object. Keep a narrow forward pickup cone and prioritize props when distances are close to reduce accidental fighter grabs.

Getting hit, elimination, target escape, menu return, or a round reset cancels pending throws and cleans up reciprocal hold references. A cancelled throw cannot release a deleted object or award delayed damage. Repeated input during wind-up cannot duplicate a release. Existing automatic grab escape remains.

## Deliverable 2: three maps

| Map | Visual identity | Gameplay layout |
| --- | --- | --- |
| Skyline Terrace | Sunny city, warm roof tiles, vents, planted corners | Wide rectangular central roof with three satellite roofs; easiest starting arena |
| Neon Junction | Night skyline, luminous signs, purple/teal paint | Two joined decks with a broad central bridge, open edges, and side platforms |
| Foundry Heights | Sunset industrial skyline, steel panels, orange warning lights | Larger industrial deck with central obstacles and narrower outer landing roofs |

Maps must change collision geometry, prop placements, and safe spawn positions, not only background colors. Every map supplies safe regions, spawn points, prop locations, palette, and collapsible platforms. Environmental hazards use each map's original materials when restoring a platform.

Keep all layouts visible with the overview camera. Scene rebuild happens between rounds or when selecting a map; it stops hazards, releases holds, and removes old fighters/props first. Bot edge avoidance must recognize every safe region, including bridges.

## Deliverable 3: four selectable heroes and powers

All heroes remain available immediately in party mode and solo character selection. Separate appearance/ability from player input and slot color. Each power has a visible cooldown meter and can trigger only while alive, active, unstunned, and off cooldown.

| Hero | Appearance | Power | Initial tuning |
| --- | --- | --- | --- |
| Bolt | Blue runner with visor and lightning crest | Dash Strike: short forward burst that knocks back each opponent once | 0.25-second dash; 7-second cooldown |
| Atlas | Heavy orange fighter with large gauntlets | Ground Slam: visible expanding impact ring with radial knockback | 2.8-unit radius; 9-second cooldown |
| Ember | Red fighter with flame hair/helmet | Flame Burst: short forward cone that pushes opponents away | 3-unit reach; 8-second cooldown |
| Frost | Teal fighter with icy shoulder fins | Freeze Pulse: radial slow with icy ring and temporary tint | 2.6-unit radius, 2-second slow; 10-second cooldown |

Powers affect existing knockback/movement/status systems. Do not introduce a health bar or damage economy in this update. No power grants indefinite flight, stacks permanent slowdown, or interrupts match cleanup. Initial numbers are tuning defaults, subject to playtest feedback. CPU opponents can use powers with level-dependent timing.

## Deliverable 4: six-level solo campaign

Menu offers Solo Adventure and Local Rumble. Solo flow is hero choice → level select → match → victory/unlock or defeat/retry. Local flow is map + hero/input selection → existing first-to-three match.

| Level | Map | Opponents | Objective |
| --- | --- | --- | --- |
| 1: First Throw | Skyline Terrace | One forgiving CPU | Win one round; show grab/throw and power hints |
| 2: Rooftop Rivals | Skyline Terrace | Two forgiving CPUs | First to two round wins |
| 3: Neon Arrival | Neon Junction | One standard CPU | First to two round wins |
| 4: Junction Jam | Neon Junction | Two standard CPUs | First to two round wins |
| 5: Heavy Industry | Foundry Heights | Two aggressive CPUs | First to three round wins |
| 6: Rooftop Champion | Foundry Heights | Three aggressive CPUs | First to three round wins |

Difficulty changes decision intervals, attack/power frequency, and prop-seeking behavior. CPUs keep the same physics rules as the player and cannot see future inputs. Ensure they can complete matches on every map before claiming difficulty tuning is finished.

Unlock the next level only when the human wins the current match. CPU victory offers Retry and Level Select. Draws replay the round without unlocking. Replay resets scores, cooldowns, holds, statuses, props, and hazards. Finishing level six shows a campaign-complete screen and allows replaying levels.

Persist highest unlocked level using a small versioned save. Validate and clamp loaded values; malformed or unavailable storage falls back to level one with a clear notice. Saving failure must not block play. Keep progress independent from party-mode results and character choice.

## Architecture and boundaries

- Character catalog: hero IDs, names, palettes, visual styles, power IDs, and tuning. Consumed by selection UI, player presentation, and ability logic.
- Arena definitions: map IDs, names, palettes, safe geometry, spawns, and prop locations. Consumed by arena construction, camera framing, hazards, and bots.
- Player presentation: mesh assembly and timed pose animation, driven by gameplay action state.
- Player gameplay: keep `release_hold(true)` as the immediate low-level physical release; add `begin_throw()` for the player-facing animation state and exactly one timed release event. Keep bounded power status/cooldown state.
- Campaign: level definitions, unlock/save validation, and win/lose routing. Uses existing round resolution with a configurable win threshold.
- UI: separate solo and local setup, hero/map previews, contextual interaction hints, power cooldowns, and level results.
- Existing game manager: owns mode, round lifecycle, and cleanup; coordinates the above without embedding catalogs into its physics loop.

Build these as four reviewable increments: visual/throw interaction, maps, heroes/powers, then solo integration. Their interfaces must be agreed before parallel code edits. Supply default hero, map, and mode values for existing callers and tests. Keep browser deployment configuration intact.

## Verification and acceptance

- Existing rules, gameplay, keyboard-input, and CPU suites still pass; update only assertions intentionally changed by animated throwing.
- Throw tests prove held-object animation before release, exactly one release, actual flight/spin/collision impulse, repeated-input rejection, and cancellation on hit/elimination/reset.
- Map tests prove valid grounded spawns, multiple safe regions, actual gaps/bridges, hazard restoration, and no stale props after switching.
- Power tests cover every hero's range/effect, cooldown, repeated-hit prevention, expiration, elimination, and round cleanup.
- Campaign tests cover unlock on human match victory, no unlock on draw/loss, retry, final completion, save reload, invalid saves, and no party-mode leakage.
- Simulated CPU matches finish on all maps without invalid references or engine errors.
- Run the production browser export and inspect Chromium rendering, selection, actual throw animation, powers, solo unlock/retry, and keyboard focus.
- Capture real gameplay screenshots of the three maps and four heroes. Check browser performance during four-fighter powers and hazards; reduce expensive effects if needed.
- Hardware controller feel, sound quality, and whether the new combat feels fun require human playtesting.

## Scope

This update is desktop browser gameplay with existing native development support. Multiplayer remains local to one computer. Online networking, touch controls, purchased asset packs, full ragdolls, long story cinematics, monetization, and live accounts are separate future work.
