extends RefCounted
## Pure benchmark configuration and statistics coverage.


func test_disabled_subsystems_accept_commas_and_hyphens() -> bool:
	var disabled := BenchmarkConfig.parse_disabled("districts,post-processing,ocean")
	return (
		disabled.has("districts")
		and disabled.has("post_processing")
		and disabled.has("ocean")
		and not disabled.has("traffic")
	)


func test_all_disables_every_benchmark_subsystem() -> bool:
	var disabled := BenchmarkConfig.parse_disabled("all")
	return disabled.size() == BenchmarkConfig.SUBSYSTEMS.size()


func test_resolution_parser_rejects_invalid_sizes() -> bool:
	var fallback := Vector2i(1920, 1080)
	return (
		BenchmarkConfig.parse_resolution("2560x1440", fallback) == Vector2i(2560, 1440)
		and BenchmarkConfig.parse_resolution("wide", fallback) == fallback
		and BenchmarkConfig.parse_resolution("0x1080", fallback) == fallback
	)


func test_disabled_shadows_reach_the_sky_controller() -> bool:
	var root := Node3D.new()
	var sky := SkyController.new()
	sky.name = "SkyController"
	root.add_child(sky)
	var config := BenchmarkConfig.new()
	config.disabled_subsystems = {"shadows": true}
	config.apply_before_ready(root)
	var ok := not sky.shadows_enabled and sky.day_length_seconds == 0.0
	root.free()
	return ok


func test_metrics_capture_percentiles_and_one_percent_low() -> bool:
	var samples := PackedFloat64Array([10.0, 12.0, 14.0, 16.0, 100.0])
	var summary := BenchmarkMetrics.summarize(samples)
	return (
		is_equal_approx(float(summary["mean"]), 30.4)
		and float(summary["p50"]) == 14.0
		and float(summary["p95"]) == 100.0
		and is_equal_approx(BenchmarkMetrics.one_percent_low_fps(samples), 10.0)
	)
