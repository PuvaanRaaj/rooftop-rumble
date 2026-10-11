# Music, difficulty, and map selection

Implement the requested content through the existing Godot match setup.

1. Add five arena choices with different layouts, palettes, scenery and props. Keep Skyline's existing geometry as the default. Validate safe spawn positions and reset behavior for each map.
2. Add original looping music and distinct pickup/throw sounds with independent music and SFX toggles. Emit sounds only for successful actions; keep audio playback separate from simulation.
3. Add Easy, Medium and Hard CPU profiles. Vary reaction timing, aim error and decision mistakes, keeping player speed and combat physics identical. Preserve the current AI as Medium.
4. Integrate map/difficulty options into the setup menu, retain them on replay, and fit the camera to each arena. Keep phone setup scrollable and touch input intact.
5. Verify native regression suites and the exported browser on a touch viewport, build, commit and push the update.
