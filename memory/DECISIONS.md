# Decisions

## Browser-first release (2026-10-11)

Export the existing Godot game to single-threaded WebAssembly with the Compatibility renderer. This preserves the game's tested physics, rules, CPU opponents, and local multiplayer controls. A static HTML launch page embeds the exported game. Vercel builds the export from source and serves `dist/`; no game server is required.

Keep native Godot play available for development. Browser-first means desktop browsers with keyboard or controllers; touch controls and online multiplayer are outside this release.

Sources: [Godot web export](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [Vercel configuration](https://vercel.com/docs/project-configuration/vercel-json).
