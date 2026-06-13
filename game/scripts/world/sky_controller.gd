class_name SkyController
extends Node
## Drives the day/night cycle: advances time of day and pushes SkyModel's output
## into the three things that have to stay in agreement — the sun
## DirectionalLight (direction, colour, energy, shadows), the WorldEnvironment's
## ambient/sky term, and the sky shader (sky.gdshader) uniforms. Add one to a
## world scene and point it at the Sun light and the WorldEnvironment.
##
## All the actual maths lives in SkyModel so it stays headless-testable; this
## node is just the wiring between that model and live scene resources.

## Current time of day, hours in [0, 24). Editable live in the inspector.
@export_range(0.0, 24.0, 0.01) var time_of_day: float = 9.5

## Real seconds for one full in-game day. 0 freezes time at `time_of_day`.
@export var day_length_seconds: float = 1200.0

## Allows deterministic benchmarks to isolate the cost of all key-light shadows.
@export var shadows_enabled: bool = true

## The world's key light. Its basis is reoriented to point along the sun ray.
@export var sun_light: DirectionalLight3D

## Optional second light for moonlight; left dark during the day if assigned.
@export var moon_light: DirectionalLight3D

## The scene's WorldEnvironment, whose Environment carries the sky + ambient.
@export var world_environment: WorldEnvironment

var _sky_material: ShaderMaterial


func _ready() -> void:
	_resolve_refs()
	_resolve_sky_material()
	add_to_group("graphics_quality_aware")
	apply_graphics_quality(GraphicsQuality.resolved_tier())
	_apply(time_of_day)


func apply_graphics_quality(tier: int) -> void:
	var distance := float(GraphicsQuality.profile(tier)["shadow_distance"])
	if sun_light != null:
		sun_light.directional_shadow_max_distance = distance
	if moon_light != null:
		moon_light.directional_shadow_max_distance = distance


## Fill any unset node references by searching the scene. Lets the controller be
## dropped into a world scene without hand-wiring exported paths (which don't
## always survive hand-authored .tscn files).
func _resolve_refs() -> void:
	var scope := get_parent()
	if scope == null:
		scope = self
	if sun_light == null:
		sun_light = _find_node_of_type(scope, "DirectionalLight3D") as DirectionalLight3D
	if world_environment == null:
		world_environment = _find_node_of_type(scope, "WorldEnvironment") as WorldEnvironment


## Depth-first search for the first descendant whose class matches `type_name`.
func _find_node_of_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.is_class(type_name):
			return child
		var found := _find_node_of_type(child, type_name)
		if found != null:
			return found
	return null


func _process(delta: float) -> void:
	if day_length_seconds > 0.0:
		time_of_day = fposmod(
			time_of_day + delta / day_length_seconds * SkyModel.DAY_HOURS, SkyModel.DAY_HOURS
		)
	_apply(time_of_day)


## Snap the cycle to a specific hour (e.g. a mission forcing dusk).
func set_time_of_day(hour: float) -> void:
	time_of_day = fposmod(hour, SkyModel.DAY_HOURS)
	_apply(time_of_day)


func _apply(tod: float) -> void:
	var sun_dir := SkyModel.sun_direction(tod)
	_orient_sun(sun_dir, tod)
	_update_environment(tod)
	_update_shader(sun_dir, tod)
	# Publish night level globally so world materials (e.g. the building facade
	# shader lighting its windows) share one day/night clock with the sky — once
	# to the shader global (GPU) and once to the CPU channel streetlamps read.
	var night := SkyModel.night_amount(tod)
	RenderingServer.global_shader_parameter_set("world_night_amount", night)
	StreetlightSwitch.night_level = night


func _orient_sun(sun_dir: Vector3, tod: float) -> void:
	if sun_light != null:
		# A DirectionalLight emits along its local -Z; aim that down the ray the
		# sunlight travels, i.e. away from the sun position (-sun_dir).
		_aim_light(sun_light, -sun_dir)
		sun_light.light_color = SkyModel.light_color(tod)
		sun_light.light_energy = SkyModel.light_energy(tod)
		sun_light.shadow_enabled = shadows_enabled and SkyModel.is_sun_up(tod)
	if moon_light != null:
		var moon_dir := SkyModel.moon_direction(tod)
		_aim_light(moon_light, -moon_dir)
		var night := SkyModel.night_amount(tod)
		moon_light.light_energy = SkyModel.MOON_ENERGY * night
		moon_light.shadow_enabled = shadows_enabled and night > 0.5 and moon_dir.y > 0.0


## Point a light's -Z down `forward`, keeping a stable up vector unless `forward`
## is near-vertical (where up would be degenerate).
func _aim_light(light: DirectionalLight3D, forward: Vector3) -> void:
	if forward.length_squared() < 1e-6:
		return
	forward = forward.normalized()
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var origin := light.global_transform.origin
	light.look_at_from_position(origin, origin + forward, up)


func _update_environment(tod: float) -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var env := world_environment.environment
	env.ambient_light_energy = SkyModel.ambient_energy(tod)
	# Tie any distance fog to the warm/cool key-light colour so aerial
	# perspective matches the sky.
	if env.fog_enabled:
		env.fog_light_color = SkyModel.light_color(tod)


func _update_shader(sun_dir: Vector3, tod: float) -> void:
	if _sky_material == null:
		_resolve_sky_material()
	if _sky_material == null:
		return
	_sky_material.set_shader_parameter("sun_direction", sun_dir)
	_sky_material.set_shader_parameter("moon_direction", SkyModel.moon_direction(tod))
	_sky_material.set_shader_parameter("sun_energy", SkyModel.sky_sun_energy(tod))
	_sky_material.set_shader_parameter("night_amount", SkyModel.night_amount(tod))


func _resolve_sky_material() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	var sky := world_environment.environment.sky
	if sky != null and sky.sky_material is ShaderMaterial:
		_sky_material = sky.sky_material as ShaderMaterial
