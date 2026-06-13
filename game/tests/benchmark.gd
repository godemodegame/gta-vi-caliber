extends Node
## Deterministic Phase 0 performance harness. The launcher pins the release
## build, scene, resolution, quality, AA, VSync, time of day, route, and seed.
## Results are written as a reviewable Markdown profile.

const ROUTE_NAME := "miami_district_loop_v1"

var _config: BenchmarkConfig
var _scene: Node
var _camera: Camera3D
var _player: Node3D
var _streamer: Node
var _route_points := PackedVector3Array(
	[
		Vector3(172.7, 120.0, -193.5),
		Vector3(-156.4, 42.0, 1239.0),
		Vector3(5899.7, 75.0, -715.8),
		Vector3(6453.3, 125.0, -4702.2),
		Vector3(-504.3, 65.0, -3364.1),
		Vector3(172.7, 42.0, -193.5),
	]
)
var _startup_started_usec: int = 0
var _startup_ms: float = 0.0
var _phase: int = 0
var _frame: int = 0
var _last_resident_signature: String = ""
var _streaming_events: int = 0
var _streaming_hitch_ms: float = 0.0

var _wall_ms := PackedFloat64Array()
var _render_cpu_ms := PackedFloat64Array()
var _render_gpu_ms := PackedFloat64Array()
var _physics_ms := PackedFloat64Array()
var _script_residual_ms := PackedFloat64Array()
var _draw_calls := PackedFloat64Array()
var _primitives := PackedFloat64Array()
var _objects := PackedFloat64Array()
var _vram_bytes := PackedFloat64Array()


func _ready() -> void:
	_startup_started_usec = Time.get_ticks_usec()
	_config = BenchmarkConfig.from_environment()
	if _config.require_release and (OS.has_feature("editor") or OS.has_feature("debug")):
		push_error("benchmark: BENCHMARK_REQUIRE_RELEASE=1 but this is not a release export")
		get_tree().quit(1)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(_config.resolution)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

	var packed := load(_config.scene_path) as PackedScene
	if packed == null:
		push_error("benchmark: failed to load %s" % _config.scene_path)
		get_tree().quit(1)
		return
	_scene = packed.instantiate()
	_config.apply_before_ready(_scene)
	add_child(_scene)
	_apply_render_settings()
	_mount_camera()
	_phase = 1


func _process(delta: float) -> void:
	if _phase == 1:
		if _startup_ms == 0.0:
			_startup_ms = float(Time.get_ticks_usec() - _startup_started_usec) / 1000.0
			print(
				(
					"benchmark: startup %.2f ms; warmup %d frames; measure %d frames"
					% [_startup_ms, _config.warmup_frames, _config.measure_frames]
				)
			)
		_move_route(_frame, _config.warmup_frames)
		_frame += 1
		if _frame >= _config.warmup_frames:
			_phase = 2
			_frame = 0
			_last_resident_signature = _resident_signature()
		return

	if _phase == 2:
		_move_route(_frame, _config.measure_frames)
		_capture_sample(delta)
		_frame += 1
		if _frame >= _config.measure_frames:
			_report()
			_cleanup_and_quit(0)
			return


func _apply_render_settings() -> void:
	var root_viewport := get_tree().root
	root_viewport.scaling_3d_scale = 1.0
	root_viewport.msaa_3d = Viewport.MSAA_DISABLED
	root_viewport.use_taa = false
	root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	match _config.aa_mode:
		"taa":
			root_viewport.use_taa = true
		"msaa2":
			root_viewport.msaa_3d = Viewport.MSAA_2X
		"msaa4":
			root_viewport.msaa_3d = Viewport.MSAA_4X
		"fxaa":
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	var shadow_size := 4096
	match _config.quality:
		"low":
			shadow_size = 2048
		"high", "ultra":
			shadow_size = 8192
	RenderingServer.directional_shadow_atlas_set_size(shadow_size, true)

	var world_environment := _scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_environment != null and _config.is_enabled("post_processing"):
		CinematicEnvironment.apply_quality(world_environment.environment, _config.quality_tier())


func _mount_camera() -> void:
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_camera = Camera3D.new()
	_camera.name = "BenchmarkCamera"
	_camera.far = 14_000.0
	_scene.add_child(_camera)
	_camera.current = true
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player != null:
		_player.process_mode = Node.PROCESS_MODE_DISABLED
	_streamer = get_tree().get_first_node_in_group("district_streamer")


func _move_route(frame: int, total_frames: int) -> void:
	var route_progress := (
		float(frame) / float(maxi(total_frames - 1, 1)) * float(_route_points.size() - 1)
	)
	var segment := mini(int(floor(route_progress)), _route_points.size() - 2)
	var blend := route_progress - float(segment)
	var position := _route_points[segment].lerp(_route_points[segment + 1], blend)
	var route_direction := _route_points[segment + 1] - _route_points[segment]
	route_direction.y = 0.0
	route_direction = route_direction.normalized()
	_camera.global_position = position
	_camera.look_at(Vector3(position.x, 8.0, position.z) + route_direction * 100.0)
	if _player != null:
		_player.global_position = Vector3(position.x, 2.0, position.z)


func _capture_sample(delta: float) -> void:
	var viewport_rid := get_viewport().get_viewport_rid()
	var wall := delta * 1000.0
	var render_cpu := RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
	var render_gpu := RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	var physics := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var residual := maxf(wall - render_cpu - physics, 0.0)

	_wall_ms.append(wall)
	_render_cpu_ms.append(render_cpu)
	_render_gpu_ms.append(render_gpu)
	_physics_ms.append(physics)
	_script_residual_ms.append(residual)
	_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_vram_bytes.append(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))

	var signature := _resident_signature()
	if signature != _last_resident_signature:
		_streaming_events += 1
		_streaming_hitch_ms = maxf(_streaming_hitch_ms, wall)
		_last_resident_signature = signature


func _resident_signature() -> String:
	if _streamer == null or not _streamer.has_method("resident_names"):
		return ""
	var names: Array = _streamer.call("resident_names")
	names.sort()
	var strings := PackedStringArray()
	for name in names:
		strings.append(String(name))
	return ",".join(strings)


func _report() -> void:
	var wall := BenchmarkMetrics.summarize(_wall_ms)
	var cpu := BenchmarkMetrics.summarize(_render_cpu_ms)
	var gpu := BenchmarkMetrics.summarize(_render_gpu_ms)
	var physics := BenchmarkMetrics.summarize(_physics_ms)
	var script := BenchmarkMetrics.summarize(_script_residual_ms)
	var draws := BenchmarkMetrics.summarize(_draw_calls)
	var primitive_stats := BenchmarkMetrics.summarize(_primitives)
	var object_stats := BenchmarkMetrics.summarize(_objects)
	var build_type := _build_type()
	var memory := OS.get_memory_info()
	var ram_gb := float(memory.get("physical", 0)) / 1_073_741_824.0

	var lines := PackedStringArray(
		[
			"# Deterministic performance profile",
			"",
			"- **Commit:** `%s`" % _markdown(OS.get_environment("BENCHMARK_COMMIT")),
			"- **Build:** %s" % build_type,
			"- **Godot:** %s" % Engine.get_version_info().get("string", "unknown"),
			"- **OS:** %s %s" % [OS.get_name(), OS.get_version()],
			(
				"- **CPU:** %s (%d logical cores)"
				% [OS.get_processor_name(), OS.get_processor_count()]
			),
			(
				"- **GPU:** %s %s"
				% [
					RenderingServer.get_video_adapter_vendor(),
					RenderingServer.get_video_adapter_name()
				]
			),
			"- **RAM:** %.1f GB" % ram_gb,
			(
				"- **Renderer:** %s / %s"
				% [
					RenderingServer.get_current_rendering_driver_name(),
					RenderingServer.get_current_rendering_method()
				]
			),
			"- **Scene:** `%s`" % _config.scene_path,
			"- **Route:** `%s`" % ROUTE_NAME,
			"- **Resolution:** %dx%d" % [_config.resolution.x, _config.resolution.y],
			"- **Quality / AA:** %s / %s" % [_config.quality, _config.aa_mode],
			"- **Time of day:** %.2f (cycle paused)" % _config.time_of_day,
			"- **VSync requested / observed:** disabled / %s" % _vsync_name(),
			(
				"- **Warmup / measured frames:** %d / %d"
				% [_config.warmup_frames, _config.measure_frames]
			),
			"- **Seed:** %d" % _config.random_seed,
			"- **Command:** `%s`" % _markdown(OS.get_environment("BENCHMARK_COMMAND")),
			"",
			"## Subsystems",
			"",
		]
	)
	for subsystem in BenchmarkConfig.SUBSYSTEMS:
		lines.append(
			(
				"- **%s:** %s"
				% [
					subsystem.replace("_", " ").capitalize(),
					"on" if _config.is_enabled(subsystem) else "off"
				]
			)
		)
	(
		lines
		. append_array(
			[
				"",
				"## Metrics",
				"",
				"| Metric | Value |",
				"| --- | ---: |",
				"| Startup to scene ready | %.2f ms |" % _startup_ms,
				(
					"| Average wall frame | %.2f ms / %.1f FPS |"
					% [wall["mean"], _fps(float(wall["mean"]))]
				),
				"| Wall p50 | %.2f ms / %.1f FPS |" % [wall["p50"], _fps(float(wall["p50"]))],
				"| Wall p95 | %.2f ms / %.1f FPS |" % [wall["p95"], _fps(float(wall["p95"]))],
				"| Wall p99 | %.2f ms / %.1f FPS |" % [wall["p99"], _fps(float(wall["p99"]))],
				(
					"| Worst wall frame | %.2f ms / %.1f FPS |"
					% [wall["worst"], _fps(float(wall["worst"]))]
				),
				"| 1%% low | %.1f FPS |" % BenchmarkMetrics.one_percent_low_fps(_wall_ms),
				(
					"| Render CPU p50 / p95 / p99 / worst | %.2f / %.2f / %.2f / %.2f ms |"
					% [cpu["p50"], cpu["p95"], cpu["p99"], cpu["worst"]]
				),
				(
					"| Render GPU p50 / p95 / p99 / worst | %.2f / %.2f / %.2f / %.2f ms |"
					% [gpu["p50"], gpu["p95"], gpu["p99"], gpu["worst"]]
				),
				(
					"| Physics p50 / p95 / p99 / worst | %.2f / %.2f / %.2f / %.2f ms |"
					% [physics["p50"], physics["p95"], physics["p99"], physics["worst"]]
				),
				(
					"| Script/main residual p50 / p95 / p99 / worst | %.2f / %.2f / %.2f / %.2f ms |"
					% [script["p50"], script["p95"], script["p99"], script["worst"]]
				),
				(
					"| Draw calls p50 / p95 / peak | %.0f / %.0f / %.0f |"
					% [draws["p50"], draws["p95"], draws["worst"]]
				),
				(
					"| Primitives p50 / p95 / peak | %.0f / %.0f / %.0f |"
					% [primitive_stats["p50"], primitive_stats["p95"], primitive_stats["worst"]]
				),
				(
					"| Objects p50 / p95 / peak | %.0f / %.0f / %.0f |"
					% [object_stats["p50"], object_stats["p95"], object_stats["worst"]]
				),
				(
					"| Peak video memory | %.0f MB |"
					% (BenchmarkMetrics.peak(_vram_bytes) / 1_048_576.0)
				),
				(
					"| Streaming hitch peak | %.2f ms (%d residency changes) |"
					% [_streaming_hitch_ms, _streaming_events]
				),
				"",
				"Script/main residual is an estimate: wall frame time minus measured render CPU and physics.",
				"Zero GPU timings mean the active backend does not expose timestamps; they are not zero cost.",
			]
		)
	)
	var body := "\n".join(lines) + "\n"
	print(body)
	var file := FileAccess.open(_config.output_path, FileAccess.WRITE)
	if file == null:
		push_error("benchmark: could not write %s" % _config.output_path)
		return
	file.store_string(body)
	file.close()
	print("benchmark: wrote %s" % _config.output_path)


func _build_type() -> String:
	if OS.has_feature("editor"):
		return "editor (non-release)"
	if OS.has_feature("debug"):
		return "debug export"
	return "release export"


func _vsync_name() -> String:
	match DisplayServer.window_get_vsync_mode():
		DisplayServer.VSYNC_ENABLED:
			return "enabled"
		DisplayServer.VSYNC_ADAPTIVE:
			return "adaptive"
		DisplayServer.VSYNC_MAILBOX:
			return "mailbox"
		_:
			return "disabled"


static func _fps(frame_ms: float) -> float:
	return 1000.0 / frame_ms if frame_ms > 0.0 else 0.0


static func _markdown(value: String) -> String:
	return value.replace("|", "\\|").replace("`", "'")


func _cleanup_and_quit(status: int) -> void:
	_phase = 3
	if _scene != null:
		_scene.queue_free()
		_scene = null
	var timer := get_tree().create_timer(0.25)
	timer.timeout.connect(func() -> void: get_tree().quit(status))
