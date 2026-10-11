# Decisions

## Browser-first release (2026-10-11)

Export the existing Godot game to single-threaded WebAssembly with the Compatibility renderer. This preserves the game's tested physics, rules, CPU opponents, and local multiplayer controls. A static HTML launch page embeds the exported game. Vercel builds the export from source and serves `dist/`; no game server is required.

Keep native Godot play available for development. Browser-first means desktop browsers with keyboard or controllers; touch controls and online multiplayer are outside this release.

Sources: [Godot web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [Vercel configuration](https://vercel.com/docs/project-configuration/vercel-json).


## First visual polish (2026-10-11)

The screenshot showed excessive empty sky, tiny fighters, and letterboxing at narrower browser widths. Reduce the orthographic span from 20 to 15 units while fitting at least 24 horizontal units to keep satellite roofs visible. Let the viewport expand with its container and keep the browser embed at 16:10, including below the responsive breakpoint.

Improve current art through suit/face detail, roof seams, architectural trim, quieter skyline colors, linear tonemapping, and 2x MSAA. Batch facade/city windows to keep the browser scene lightweight. Keep physical arena bounds and combat unchanged during this focused visual pass; larger playable maps belong to the proposed content upgrade.
