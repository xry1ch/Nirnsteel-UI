# NirnsteelUI

The **Damage Done Minigame** is available under **Damage Numbers** in the addon settings. Enable it, then use **Preview Minigame** to try a sequence of rapid hits, critical impacts, milestones, and the final peak score. It works independently of floating damage numbers.

- Player and pet damage, including damage-over-time ticks, build the chain. Nearby hits share a floating delta; every hit still counts toward the score.
- The underline shows the remaining chain time. By default, damage holds for 1.25 seconds after the last hit, then drains over 1.5 seconds. A hit during the drain rescues the chain; a fully expired chain starts fresh.
- **DPS** uses damage and elapsed time across the active chain, including rescued pauses, with a one-second minimum denominator. The drain is an arcade effect; this is not an encounter damage meter.
- Adjust **Combo Grace Period**, **Impact Animation Intensity**, scale, and facing in settings. Separate toggles control the combo timer, Damage Done / DPS label, hit count, and peak label. Zero intensity keeps simple fades. Real damage clears simulated preview points.

Run `tests/damage_minigame_regression.lua` from the addon root with Lua 5.1+ or Fengari to check scoring, timing, feedback, preview isolation, and cleanup. Exact fonts, textures, and audio require an ESO client check.
