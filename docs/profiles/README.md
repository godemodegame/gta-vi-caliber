# Performance profiles

Profiles in this directory must come from an exported release build. Editor
captures are useful while developing the harness but are not baseline evidence.

Export a platform release, then run the deterministic Miami route:

```bash
BENCHMARK_BIN=/absolute/path/to/release-executable tools/benchmark.sh
```

The launcher pins the scene, 1920x1080 resolution, Medium quality, TAA, time of
day, VSync state, random seed, warmup, sample count, and camera route. Override
one input explicitly when investigating it, for example:

```bash
BENCHMARK_BIN=/absolute/path/to/release-executable \
	tools/benchmark.sh --without shadows,post-processing
```

Available subsystem switches are `districts`, `backdrop`, `shadows`,
`post-processing`, `crowds`, `traffic`, `ocean`, and `imported-prop-packs`.
Commit the generated Markdown report unchanged, then add a short interpretation
that distinguishes measured results from unsupported counters.

The acceptance platform is RTX 3060-class hardware at 1920x1080 Medium. macOS
captures are secondary results and cannot close that target-hardware gate.
