class_name BenchmarkConfig
extends RefCounted
## Parsed, testable configuration for the deterministic performance harness.

const SUBSYSTEMS: PackedStringArray = [
	"districts",
	"backdrop",
	"shadows",
	"post_processing",
	"crowds",
	"traffic",
	"ocean",
	"imported_prop_packs",
]

var scene_path: String = "res://scenes/world/miami.tscn"
var output_path: String = "/tmp/gta_caliber_benchmark.md"
var resolution: Vector2i = Vector2i(1920, 1080)
var quality: String = "medium"
var aa_mode: String = "taa"
var time_of_day: float = 17.5
var warmup_frames: int = 180
var measure_frames: int = 900
var random_seed: int = 530_600
var require_release: bool = false
var disabled_subsystems: Dictionary = {}


static func from_environment() -> BenchmarkConfig:
	var config := BenchmarkConfig.new()
	config.scene_path = _env_string("BENCHMARK_SCENE", config.scene_path)
	config.output_path = _env_string("BENCHMARK_OUTPUT", config.output_path)
	config.resolution = parse_resolution(
		_env_string("BENCHMARK_RESOLUTION", "1920x1080"), config.resolution
	)
	config.quality = _env_string("BENCHMARK_QUALITY", config.quality).to_lower()
	config.aa_mode = _env_string("BENCHMARK_AA", config.aa_mode).to_lower()
	config.time_of_day = _env_float("BENCHMARK_TIME_OF_DAY", config.time_of_day)
	config.warmup_frames = maxi(_env_int("BENCHMARK_WARMUP", config.warmup_frames), 1)
	config.measure_frames = maxi(_env_int("BENCHMARK_FRAMES", config.measure_frames), 10)
	config.random_seed = _env_int("BENCHMARK_SEED", config.random_seed)
	config.require_release = OS.get_environment("BENCHMARK_REQUIRE_RELEASE") == "1"
	config.disabled_subsystems = parse_disabled(OS.get_environment("BENCHMARK_DISABLED"))
	return config


static func parse_resolution(raw: String, fallback: Vector2i) -> Vector2i:
	var parts := raw.to_lower().split("x", false, 1)
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return fallback
	var parsed := Vector2i(int(parts[0]), int(parts[1]))
	return parsed if parsed.x > 0 and parsed.y > 0 else fallback


static func parse_disabled(raw: String) -> Dictionary:
	var disabled := {}
	for token in raw.to_lower().split(",", false):
		var name := token.strip_edges().replace("-", "_")
		if name == "all":
			for subsystem in SUBSYSTEMS:
				disabled[subsystem] = true
		elif SUBSYSTEMS.has(name):
			disabled[name] = true
	return disabled


func is_enabled(subsystem: String) -> bool:
	return not disabled_subsystems.has(subsystem)


func quality_tier() -> int:
	match quality:
		"low":
			return CinematicEnvironment.Quality.LOW
		"high":
			return CinematicEnvironment.Quality.HIGH
		"ultra":
			return CinematicEnvironment.Quality.ULTRA
		_:
			return CinematicEnvironment.Quality.MEDIUM


func apply_before_ready(scene: Node) -> void:
	_configure_time(scene)
	_configure_streamer(scene)
	_configure_backdrop(scene)
	_configure_shadows(scene)
	_configure_post_processing(scene)
	_configure_director(scene, "CrowdDirector", "crowds", random_seed)
	_configure_director(scene, "TrafficDirector", "traffic", random_seed + 1)
	if not is_enabled("imported_prop_packs"):
		_remove_named(scene, "CoastalProps")


func _configure_time(scene: Node) -> void:
	var sky := scene.find_child("SkyController", true, false)
	if sky != null:
		sky.set("time_of_day", time_of_day)
		sky.set("day_length_seconds", 0.0)
		sky.set("shadows_enabled", is_enabled("shadows"))


func _configure_streamer(scene: Node) -> void:
	var streamer := scene.find_child("Streamer", true, false)
	if streamer != null:
		streamer.set("streaming_enabled", is_enabled("districts"))


func _configure_backdrop(scene: Node) -> void:
	if not is_enabled("backdrop"):
		for node_name in ["FloridaBackdrop", "CoastalProps", "Causeways", "BayIslands"]:
			_remove_named(scene, node_name)
		return
	var backdrop := scene.find_child("FloridaBackdrop", true, false)
	if backdrop != null:
		backdrop.set("build_ocean", is_enabled("ocean"))
		backdrop.set("build_causeway_traffic", is_enabled("traffic"))
		backdrop.set("build_imported_prop_packs", is_enabled("imported_prop_packs"))


func _configure_shadows(scene: Node) -> void:
	if is_enabled("shadows"):
		return
	for node in scene.find_children("*", "Light3D", true, false):
		(node as Light3D).shadow_enabled = false


func _configure_post_processing(scene: Node) -> void:
	var world_environment := scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_environment == null:
		return
	world_environment.set("minimum_tier", quality_tier())
	if is_enabled("post_processing"):
		return
	world_environment.set_script(null)
	var source_environment := world_environment.environment
	if source_environment == null:
		return
	var environment := source_environment.duplicate() as Environment
	world_environment.environment = environment
	environment.ssao_enabled = false
	environment.ssil_enabled = false
	environment.ssr_enabled = false
	environment.glow_enabled = false
	environment.fog_enabled = false
	environment.volumetric_fog_enabled = false
	environment.sdfgi_enabled = false


func _configure_director(
	scene: Node, node_name: String, subsystem: String, seed_value: int
) -> void:
	if not is_enabled(subsystem):
		_remove_named(scene, node_name)
		return
	var director := scene.find_child(node_name, true, false)
	if director != null:
		director.set("random_seed", seed_value)


static func _remove_named(scene: Node, node_name: String) -> void:
	var node := scene.find_child(node_name, true, false)
	if node == null:
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


static func _env_string(name: String, fallback: String) -> String:
	var value := OS.get_environment(name).strip_edges()
	return value if not value.is_empty() else fallback


static func _env_int(name: String, fallback: int) -> int:
	var value := OS.get_environment(name).strip_edges()
	return int(value) if value.is_valid_int() else fallback


static func _env_float(name: String, fallback: float) -> float:
	var value := OS.get_environment(name).strip_edges()
	return float(value) if value.is_valid_float() else fallback
