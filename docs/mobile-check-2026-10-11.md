# Mobile readiness check — 2026-10-11

Original audit result: browser loading worked; touch-only gameplay was absent. See the subsequent fix below.

## Verification

Tested the real Godot WebGL export, not a placeholder, in Chromium with touch events, a 390×844 portrait viewport, an 844×390 landscape viewport, and device pixel ratio 2. Tested the local build and the public production deployment at https://rooftop-rumble-lake.vercel.app.

- Portrait launch shows the rotation instruction; landscape hides it.
- The WebAssembly/WebGL game loads and reaches its title menu.
- Fullscreen works in this Chromium emulation; touch taps open crew setup and start a match.
- The embedded game is taller than the available landscape phone viewport, so the page scrolls/clips before fullscreen. Fullscreen also retains the wrapper header/footer, leaving limited room for the game.
- Menus are desktop-scaled and action targets/text are small on the phone-sized display.
- No virtual joystick or touch Jump/Attack/Grab/Throw controls exist. The input router still samples only keyboard and gamepad input; starting a match by touch does not provide touch control of the fighter.

## Menu bug found and fixed

A touch menu transition produced a Godot `can_process` error because controls were detached during their active button event. Menu and HUD cleanup now hide old controls and defer deletion, preserving scene-tree membership until event dispatch finishes. The local and hosted real-game mobile retries had no engine errors after the fix; all 25 integrated gameplay checks and GitHub CI passed. Vercel confirmed the fixed deployment ready before the hosted retry.

## Remaining work

Implement the shared touch input layer and mobile menus/HUD, then the viewport-filling game shell and camera framing from the approved orientation design. Test physical Android Chrome and iPhone Safari for sustained performance, input comfort, orientation changes, backgrounding, and browser-specific fullscreen behavior. Chromium emulation cannot establish those hardware/browser results.

The broader game-first/mobile implementation remains proposed in `docs/superpowers/specs/2026-10-11-game-first-mobile-steam-design.md`.


## Subsequent mobile gameplay fix

Phone screenshots confirmed that setup still assigned a keyboard and no touch controls appeared. The game now defaults to Touchscreen, provides a floating joystick plus Jump/Punch/Grab/Throw, and uses independent finger ownership. Action presses are latched through physics updates. Phone gameplay fills the viewport, menus use larger responsive dimensions, and visibility/orientation transitions reset input and pause the game.

The automated mobile input suite passes 33 checks, including real movement, jump, prop pickup/physical throw, cancellation, short taps, and round/menu/elimination cleanup. Physical phone QA remains required.
