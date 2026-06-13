# Profile: Miami Phase 0 release baseline - 2026-06-13

Secondary-platform capture for issue
[#53](https://github.com/duolahypercho/gta-vi-caliber/issues/53). This does not
replace the required RTX 3060-class capture.

# Deterministic performance profile

- **Commit:** `86719f91bd64412150036b0fa27aed2cf1355810`
- **Build:** release export
- **Godot:** 4.6.3-stable (official)
- **OS:** macOS 26.2.0
- **CPU:** Apple M3 Pro (12 logical cores)
- **GPU:** Apple Apple M3 Pro (Apple9)
- **RAM:** 18.0 GB
- **Renderer:** metal / forward_plus
- **Scene:** `res://scenes/world/miami.tscn`
- **Route:** `miami_district_loop_v1`
- **Resolution:** 1920x1080
- **Quality / AA:** medium / taa
- **Time of day:** 17.50 (cycle paused)
- **VSync requested / observed:** disabled / disabled
- **Warmup / measured frames:** 180 / 900
- **Seed:** 530600
- **Command:** `/tmp/gta_caliber_phase0_release/GTA-VI-caliber.app/Contents/MacOS/GTA-VI-caliber --resolution 1920x1080 -- --benchmark`

## Subsystems

- **Districts:** on
- **Backdrop:** on
- **Shadows:** on
- **Post Processing:** on
- **Crowds:** on
- **Traffic:** on
- **Ocean:** on
- **Imported Prop Packs:** on

## Metrics

| Metric | Value |
| --- | ---: |
| Startup to scene ready | 6925.31 ms |
| Average wall frame | 18.32 ms / 54.6 FPS |
| Wall p50 | 20.18 ms / 49.5 FPS |
| Wall p95 | 31.48 ms / 31.8 FPS |
| Wall p99 | 34.91 ms / 28.6 FPS |
| Worst wall frame | 36.95 ms / 27.1 FPS |
| 1% low | 27.7 FPS |
| Render CPU p50 / p95 / p99 / worst | 1.01 / 2.65 / 3.59 / 5.10 ms |
| Render GPU p50 / p95 / p99 / worst | 0.00 / 0.00 / 0.00 / 0.00 ms |
| Physics p50 / p95 / p99 / worst | 16.79 / 21.19 / 21.19 / 21.19 ms |
| Script/main residual p50 / p95 / p99 / worst | 2.81 / 16.92 / 20.12 / 28.06 ms |
| Draw calls p50 / p95 / peak | 1202 / 5843 / 9678 |
| Primitives p50 / p95 / peak | 34960783 / 58645844 / 59934603 |
| Objects p50 / p95 / peak | 2032 / 7687 / 12672 |
| Peak video memory | 1840 MB |
| Streaming hitch peak | 0.00 ms (0 residency changes) |

Script/main residual is an estimate: wall frame time minus measured render CPU and physics.
Zero GPU timings mean the active backend does not expose timestamps; they are not zero cost.

## Reading

- The secondary platform misses the 16.6 ms target at p50 and reaches 31.48 ms
  at p95. Phase 0 establishes evidence; it does not claim the lockdown target.
- Metal returned no GPU timestamps, so this capture cannot attribute the
  remaining frame cost between GPU work and unmeasured main-thread work.
- Peak draw calls remain 9,678 and peak video memory is 1,840 MB.
- The route recorded no residency changes because the current Miami load radius
  keeps all five districts resident. The startup measurement includes their
  synchronous construction.
- An all-subsystems-off release smoke completed at 120 FPS with 83 peak draw
  calls, confirming the A/B path can isolate the world systems.
