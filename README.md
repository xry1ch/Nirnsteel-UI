# NirnsteelUI

## Minimap

**Settings → Addons → NirnSteel UI → Minimap** provides a player-centered navigation map with a dark steel frame, silver edging, and gold compass accents. It starts enabled as a 280-pixel circle at the bottom right, facing north, and stays visible in combat. It requires no additional libraries beyond the addon's existing LibAddonMenu dependency.

- Switch between circular and rectangular views without losing either shape's dimensions. Choose north-up or smooth camera-heading rotation; markers stay upright.
- Near map borders, the view stops at the texture bounds and the player marker moves with the terrain. Rotated rectangular corners remain covered, with an automatic minimum zoom when needed to fit the viewport. Zone crossings refresh the selected map immediately.
- Battleground objectives display automatically, including flags, Chaos Balls, relics, capture points, and their spawn/return locations. Moving objectives, ownership textures, and aura colors update live using ESO's native objective APIs, independently of the quest and location filters.
- Adjust zoom, dimensions, map/frame opacity, frame colors and thickness, marker/player size, labels, shadow, and combat visibility. Filter group members, quests, discovered wayshrines, locations, and the personal waypoint independently. Quest markers include native search areas and floor/door breadcrumbs.
- Assign **Minimap: Place Waypoint at Cursor** under **Controls → Keybindings → Nirnsteel UI**. It is unbound by default. With ESO's cursor over the minimap, press the assigned key to place a personal waypoint; **right click its marker** removes it. Left click and Ctrl-click do not place waypoints. Hover for zoom and world-map buttons; wheel zoom changes in 0.25× steps. Click-through is optional. Gamepad HUD display is supported; use the full map for controller waypoint placement.
- **Unlock Position** enables dragging anywhere on the map or its header while the cursor is visible, including with click-through enabled. The complete widget stays on screen and its position is saved on release. Unlocking also opens a persistent sample preview while this addon's settings panel is open. **Preview** otherwise lasts 12 seconds. Sample markers cannot create real waypoints. **Reset Position** restores the bottom-right placement; **Reset Minimap Settings** resets only this module.
- **Quest Tracker Vertical Offset** moves the native quest tracker down by 0–600 UI pixels to leave room for a minimap at the top right. It applies immediately, preserves ESO's relative layout, and is saved with the Minimap settings. Zero, module reset, or disabling Minimap restores normal tracker placement; re-enabling restores the saved offset.
- The minimap suspends during menus, full-map browsing, travel, and loading. It never selects the player map while those scenes own the map. Invalid player positions or missing map tiles display an unavailable state and retry. Custom pins from other addons and dedicated siege overlays are outside this version.

Run `tests/minimap_regression.lua` from the addon root with Lua 5.1+ or Fengari. Coverage includes rendered tile/marker alignment through full rotations, clicks on rotated terrain, fixed clipping after moves/resizes, non-square tiles, compass/waypoint arrow bounds, filters, delayed quest data, map ownership, floor changes, scene/combat transitions, preview isolation, settings persistence, and cleanup. `tests/minimap_preview.cjs` captures the real Lua controls and their clipping coordinates for a four-layout diagnostic image using sample terrain; its invocation is documented at the top of that file. Terrain uses native texture rotation and compass arrows rotate their polygon vertices, leaving control and clipping coordinates fixed. The player marker is a standalone arrow without a background ring.

Rectangular frames, compass ticks, and arrow tips use unsmoothed polygon edges so the native renderer preserves their corners. Regression coverage checks frame alignment and shape switching at tall, default, and wide dimensions in both orientations; the diagnostic renderer rejects smoothed sparse contours rather than displaying a misleading straight outline.

Quest search regions use ESO's native halo shader and assisted/unassisted colors, independently of the minimap's gold accent. Duplicate quest conditions retain their search radius. `tests/minimap_quest_area_regression.lua` checks tracking changes, duplicate conditions, area alignment/clipping, filters, and removal; the diagnostic preview only approximates the native shader.

`tests/minimap_layout_regression.lua` covers drag hit routing over terrain and headers, clipping during movement, screen clamping, position persistence, cancellation on scene/cursor/setting changes, and the quest tracker slider's native anchors, reset, saved defaults, and platform changes.

`tests/minimap_objectives_regression.lua` covers boundary coverage across shapes, rotations and zoom levels, immediate zone transitions, live battleground objective updates, visibility/context filtering, and cleanup. All three minimap suites pass with Fengari. Border rendering and objective artwork still need verification in the ESO client. Objective handling follows the [native map pin manager](https://github.com/esoui/esoui/blob/live/esoui/ingame/map/mappin_manager.lua).

Validation for this change: Lua 5.1 syntax checks and ten regression suites passed, including both minimap suites. The existing `target_frame_regression.lua` readiness-event assertion at line 625 still fails; both that test and `modules/target_frame.lua` are unchanged from the baseline. Live ESO checks remain unverified because computer-use access to the client was denied. In-client acceptance should check dragging from both the map and header, quest tracker placement in keyboard/gamepad mode, rectangular frame corners against terrain edges, actual tile clipping/seams and heading direction in both shapes, zone/interior/floor transitions, group markers, cursor behavior, UI scaling, and repeated world-map opening.

## Damage Done Minigame

The **Damage Done Minigame** is available under **Damage Numbers** in the addon settings. Enable it, then use **Preview Minigame** to try a sequence of rapid hits, critical impacts, milestones, and the final peak score. It works independently of floating damage numbers.

- Player and pet damage, including damage-over-time ticks, build the chain. Nearby hits share a floating delta; every hit still counts toward the score.
- A stamped metal crest and segmented wings echo the PvP streak badge. Gold drains from the outer wing segments toward the center to show remaining chain time; six small inlays mark milestones. Critical hits stamp the crest and eject small faceted sparks. By default, damage holds for 1.25 seconds after the last hit, then drains over 1.5 seconds. A hit during the drain rescues the chain; a fully expired chain starts fresh.
- **DPS** uses damage and elapsed time across the active chain, including rescued pauses, with a one-second minimum denominator. The drain is an arcade effect; this is not an encounter damage meter.
- Adjust **Combo Grace Period**, **Impact Animation Intensity**, scale, and facing in settings. Separate toggles control the combo timer, Damage Done / DPS label, hit count, and peak label. Zero intensity keeps simple fades. Real damage clears simulated preview points.

Run `tests/damage_minigame_regression.lua` from the addon root with Lua 5.1+ or Fengari to check scoring, timing, feedback, preview isolation, and cleanup. Exact fonts, textures, and audio require an ESO client check.

Use **Preview All Tiers** to demonstrate the selected mode's complete progression:

| Tier | Damage Done | DPS | Appearance |
| --- | ---: | ---: | --- |
| Base | Below 100,000 | Below 20,000 | Bronze and gold |
| 1 | 100,000+ | 20,000+ | Pale gold |
| 2 | 250,000+ | 40,000+ | Rich gold |
| 3 | 500,000+ | 60,000+ | Amber |
| 4 | 1,000,000+ | 80,000+ | Orange fire, first armor layer and crest aura |
| 5 | 2,500,000+ | 110,000+ | Crimson, two armor layers, crown and orbiting runes |
| 6 | 5,000,000+ | 140,000+ | White-hot gold, full armor, six orbiting runes and double shockwaves |

Upper-tier milestones unfold the armor and expand the crest in a dedicated transformation. Earned metalwork persists until the chain ends, even during drain. Zero animation intensity preserves the tier's static design while disabling movement and flashes.

**Tier Progression Sounds** is on by default and gives each newly reached tier its own sound in both modes. A hit that skips tiers plays only the highest tier reached. Disable it to keep regular hit sounds, or turn off **Minigame Sounds** to mute all minigame audio. **Preview All Tiers** demonstrates the sound progression as well as the visuals.
