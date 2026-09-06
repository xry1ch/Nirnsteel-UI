# NirnsteelUI

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
