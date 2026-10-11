# Rooftop Rumble — game-first browser, mobile, and Steam roadmap

Status: proposed design for review. This document changes no game code and creates no Steam app or paid account.

## Direction

Keep one Godot gameplay project for browser and native desktop releases. Present it as a game from the first screen: a viewport-filling arena, compact menus, readable characters, and controls appropriate to the device. Colorful cartoon action remains the selected art direction.

Interpret “square map” as a physically square primary arena, initially 18 × 18 world units, rather than forcing the browser canvas into a square. The user confirmed landscape-first mobile play. Keep portrait menus accessible and suggest rotating for combat.

## Small addition completed

The current browser launcher now shows a rotating-phone prompt when launched on a portrait touch device: “Rotate your phone to play.” It hides when the device becomes landscape and offers Continue in portrait so menus remain accessible. A subsequent phone-playability fix implements touch controls, automatic touch player selection, mobile menu scaling, and viewport-filling mobile play. The square arena, dynamic camera, character/content, and Steam phases remain proposed.

## Current gaps verified in source

- The primary roof is 14 × 10; collision, paint, facade, spawns, props, and safe areas use separate constants.
- The camera fits a fixed 24-unit horizontal span, showing extra skyline even when combat is concentrated.
- The browser has a long hero section, rules, controls, and a framed game area; the native game repeats controls in menus.
- Menus have a fixed 630-pixel minimum panel width and score cards are sized for desktop.
- The input router only handles keyboard and gamepads. No mobile touch source exists.
- Characters have procedural body/head pieces and animated arms; legs and expressive body poses need further work.
- Only the Web export preset exists. Native release presets, platform release QA, and Steam packaging are not configured.

## Phase 1: game-first presentation, square arena, closer camera

### Browser and menus

- Replace the marketing layout with a game canvas filling the available browser viewport. No page scroll during play.
- Start with the arena behind a compact title/menu: Play, Local Party, Settings, and Help. A mobile tap activates audio and requests fullscreen when supported.
- Put rules and detailed control text in Help. Keep gameplay HUD to player identity, round score, countdown, and a short contextual hint.
- Use small Pause, Sound, and Fullscreen controls. Show loading progress and a short retry message only while needed.
- Keep true browser fullscreen as a user-triggered action; fall back to the full viewport when unsupported. Do not promise automatic fullscreen or forced rotation.
- Scale menus to the actual viewport and safe margins. Use controller focus navigation and touch-sized buttons throughout setup and results.

### Square physical arena

- Start with an 18 × 18 primary fighting surface and intentionally placed satellite roofs/gaps.
- Define map dimensions once, then derive floor collision, bot safe areas, markings, facade, spawn points, props, obstacles, and satellite placement from that definition.
- Preserve falling and gap jumping as deliberate mechanics. Use visually clear edges and consistent obstacle collision shapes.
- Reposition eight props so every spawn has access to a nearby prop and the center stays navigable.
- Recheck natural CPU plans, pickup reach, and edge avoidance on the new geometry.

### Action-focused camera

- Frame living fighters and relevant nearby interaction space, instead of permanently fitting every distant rooftop and building.
- Smoothly track the combat center and zoom closer when fighters cluster. Expand when living fighters separate so nobody is unfairly hidden.
- Reserve a margin for edges, upcoming landing space, character height, and the bottom touch-control region.
- Keep a falling fighter visible briefly, then exclude deeply fallen/eliminated actors from the framing calculation so a fall does not pull the camera away from combat.
- Use a wider arena overview in menus and transitions. Allow a compact camera-distance option and reduced camera shake.
- Do not crop away a fighter's safe landing area merely to achieve a closer look. Four-player separation may require a wider view than solo play.

Acceptance: the title, setup, match, pause, and results all work without page scrolling; the square arena's colliders and safe positions agree; camera projection tests keep active fighters and edge context visible at desktop and phone landscape sizes.

## Phase 2: mobile touch controls and performance

### Controls

- Left thumb: floating analogue joystick with a dead zone and bounded movement magnitude.
- Right thumb: Jump, Attack, and contextual Grab / Throw. While holding, the button label changes to Throw and uses the existing timed animation.
- Default mobile game: one touch-controlled human with CPU opponents. Keep controller/keyboard support when connected; do not require multiple touch players on one phone.
- Use a Godot touch CanvasLayer shared with future native mobile builds, rather than a separate HTML gameplay implementation.
- Feed touch movement/held buttons through the same action-pulse rules as keyboard/controller input. Preserve legacy sampler behavior and test callers.
- Track finger IDs independently. A joystick finger must not become an action finger; releasing Jump must not stop movement.
- Clear held state on cancellation, focus loss, backgrounding, rotation, pause/menu entry, and round reset. Holding Grab must not produce repeated pickup/throws.
- Replace keyboard-specific world hints for touch players. Hide the touch layer in menus and avoid touch events leaking into gameplay behind them.
- Position controls inside safe margins, use translucent backgrounds and large thumb targets, and keep the fighting area visible above them.

### Orientation and quality

- Confirmed: landscape-first combat, with accessible portrait menus and a small rotate suggestion. The app must remain usable if orientation locking is unavailable.
- Support viewport resizing and browser toolbar changes without stretching controls, clipping menus, or leaving stuck movement.
- Introduce Auto / Low / High visual settings. Scale shadows, particle counts, decorative detail, antialiasing, and rendering resolution based on measured device performance.
- Initial performance goals: stable 60 FPS on tested desktop hardware and at least 30 FPS on declared supported midrange phones. These are acceptance targets, not current guarantees.
- Keep HUD text sharp when reducing 3D resolution. Measure browser frame time, input latency, load time, memory, and thermal slowdown on physical devices.
- Test iPhone Safari and Android Chrome over HTTPS. Desktop touch emulation proves interaction logic only, not phone GPU performance or comfort.
- Consider installable PWA support after the initial touch experience passes; handle update/cache behavior explicitly.

Acceptance: a player can move while jumping, grabbing, and throwing with multiple fingers; releasing/canceling/backgrounding clears input; native keyboard/controller tests remain valid; physical phones complete matches with readable HUD and acceptable sustained performance.

## Phase 3: stronger characters and content

- Separate character presentation from the collision capsule and gameplay movement.
- Add articulated legs, shoulders, hands, idle breathing, run cycles, jump anticipation, landing compression, punch preparation, hit reactions, stumble, carrying, and throw follow-through.
- Develop recognizable cartoon silhouettes and accessories; choose a small consistent cast over many recolored models.
- Review authored character models/rigs against the same art direction. Use compact textures, efficient materials, and compatible animation exports when replacing procedural skins.
- Improve shadows, edge contrast, material consistency, prop impacts, dust, and short power/throw trails within mobile quality budgets.
- Then add map/character selection, character powers, and solo levels from the existing proposed content design. These are additional increments, not prerequisites for basic mobile play.
- Keep original/licensed assets and their credits traceable for distribution.

Acceptance: movement and combat poses read clearly at real phone scale, character silhouettes remain distinct, and art improvements do not change collision behavior or break performance targets.

## Browser GPU strategy

The existing Godot 4.5.2 browser build already uses GPU rendering through WebGL 2 and the Compatibility renderer. The documented 4.5 web path does not support WebGPU or Forward+/Mobile rendering. Retain the working renderer and single-thread export; optimize art, batching, visible geometry, shaders, shadows, viewport pixel cost, and payload size first.

Native Steam builds can share the Compatibility presentation initially. Evaluate a separate higher-quality native profile only after measuring a real benefit and accounting for visual differences. Native Android/iOS apps can be considered later if browser performance is insufficient; touch input remains reusable.

Source: [Fullscreen user-gesture requirements](https://developer.mozilla.org/en-US/docs/Web/API/Element/requestFullscreen), [Godot 4.5 web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [renderers](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html).

## Phase 4: native Windows, macOS, and Linux / Steam readiness

### Build and gameplay readiness

- Add Windows x86_64, Linux x86_64, and macOS Universal native export presets using pinned Godot release templates.
- Produce reproducible versioned release artifacts and checksums; keep tools, signing material, and release binaries out of source commits.
- Test clean installation, launch, local saves/settings, fullscreen/windowed modes, pause, audio, and complete matches on every promised OS.
- Require controller-only navigation from launch through setup, gameplay, pause/settings, results, and exit before claiming full controller support.
- Add proper settings/save handling, controller reconnect behavior, input prompts, and accessible options.
- Plan macOS signing/notarization and verify Steam-delivered installs separately. Do not assume successful local launch establishes Windows/Linux or Steam compatibility.
- Include engine and asset licenses/credits in release packaging.

Sources: [Windows export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html), [Linux export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_linux.html), [macOS export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html).

### Steam distribution work

- The owner completes Steamworks identity, banking/tax onboarding and the US$100 per-product Steam Direct fee. No payment or account action is part of this planning work.
- Prepare an actual gameplay trailer, screenshots, logo/capsule art, descriptions, pricing decision, supported OS/system requirements, content survey, and distribution rights/credits.
- Configure platform depots, launch executables, packages, and a private testing branch. Validate the builds delivered through Steam on each OS.
- Use Steam upload tooling; in-game Steamworks API integration is optional. Achievements, cloud saves, and Remote Play Together eligibility are later evaluations.
- Submit store/build review with buffer. Official review guidance says typically 3–5 business days and recommends allowing at least 7 business days.
- Keep Coming Soon public for at least two weeks. Allow at least 30 days after fee payment in the initial schedule and verify the dashboard's actual eligibility date: Steam Direct and onboarding documentation currently disagree (30 versus 21 days).
- Do not announce a release date until platform QA, store/build approval, and eligibility are confirmed. Publishing on Steam does not provide online multiplayer automatically.

Sources: [Steam Direct fee](https://partner.steamgames.com/doc/gettingstarted/appfee), [onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding), [Steam Direct](https://partner.steamgames.com/steamdirect/), [review](https://partner.steamgames.com/doc/store/review_process), [depots](https://partner.steamgames.com/doc/store/application/depots), [SDK](https://partner.steamgames.com/doc/sdk).

## Feature priorities beyond the foundation

1. Character selection and meaningful powers; distinct maps and solo challenges.
2. Better audio feedback, hit/throw readability, and short in-game onboarding rather than long instructions.
3. Rebindable controls and accessibility settings.
4. Online rooms/matchmaking as a separate network design, with authoritative physics, disconnect handling, hosting, and cross-platform testing.
5. Native mobile apps and Steam achievements/cloud features only after the core game feels good.

## Recommended build order and review boundaries

First review/implement Phase 1 (fullscreen presentation + square arena + camera), then Phase 2 (touch controls + physical phone QA). Develop the character art pass alongside measured performance work once framing is settled. Prepare native exports early, but tie the Steam release to a polished, tested playable build rather than to the current prototype.

Maintain the existing browser/GitHub/Vercel flow. Do not rewrite the game in a web-only engine or wrap the website as the Steam desktop product.
