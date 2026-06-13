class_name FloridaThreeJsPlacements
extends RefCounted
## Places Three.js-authored GLB packs across the Florida backdrop.
##
## Keeps authored asset placement out of FloridaBackdrop so the main builder
## remains within the repo's per-file lint budget.

const THREE_FLORIDA_LANDMARK_PACK := "res://assets/buildings/florida_landmark_pack.glb"
const THREE_FLORIDA_CITY_BLOCK_PACK := "res://assets/buildings/florida_city_block_pack.glb"
const THREE_FLORIDA_NEON_DETAIL_PACK := "res://assets/buildings/florida_neon_detail_pack.glb"
const THREE_FLORIDA_REGIONAL_PACK := "res://assets/buildings/florida_regional_pack.glb"
const THREE_FLORIDA_INFRASTRUCTURE_PACK := "res://assets/buildings/florida_infrastructure_pack.glb"
const THREE_FLORIDA_ENVIRONMENT_PACK := "res://assets/buildings/florida_environment_pack.glb"
const THREE_FLORIDA_TRAFFIC_MARINE_PACK := "res://assets/buildings/florida_traffic_marine_pack.glb"
const THREE_FLORIDA_VISTA_PACK := "res://assets/buildings/florida_vista_pack.glb"
const THREE_FLORIDA_STREETLIFE_PACK := "res://assets/buildings/florida_streetlife_pack.glb"

var _b: FloridaBackdrop


func _init(backdrop: FloridaBackdrop) -> void:
	_b = backdrop


func build_landmark_models() -> void:
	var placements := [
		{
			"name": "ThreeJsMiamiResortPack",
			"position": Vector2(980.0, -1700.0),
			"yaw": -0.42,
			"scale": 1.25
		},
		{
			"name": "ThreeJsKeysResortPack",
			"position": Vector2(-1220.0, -3400.0),
			"yaw": 0.34,
			"scale": 1.0
		},
		{
			"name": "ThreeJsGulfRoutePack",
			"position": Vector2(-1720.0, -760.0),
			"yaw": 0.78,
			"scale": 1.15
		}
	]
	_place_pack("ThreeJsFloridaModels", THREE_FLORIDA_LANDMARK_PACK, placements, 0.12)


func build_city_blocks() -> void:
	var placements := [
		{
			"name": "ThreeJsBrickellCityBlock",
			"position": Vector2(720.0, -1320.0),
			"yaw": -0.18,
			"scale": 1.8
		},
		{
			"name": "ThreeJsBeachCityBlock",
			"position": Vector2(1240.0, -2260.0),
			"yaw": 0.56,
			"scale": 1.45
		},
		{
			"name": "ThreeJsGulfCityBlock",
			"position": Vector2(-1480.0, -420.0),
			"yaw": 0.22,
			"scale": 1.55
		},
		{
			"name": "ThreeJsNorthCoastCityBlock",
			"position": Vector2(240.0, 1680.0),
			"yaw": -0.74,
			"scale": 1.35
		}
	]
	_place_pack("ThreeJsFloridaCityBlocks", THREE_FLORIDA_CITY_BLOCK_PACK, placements, 0.14)


func build_neon_details() -> void:
	var placements := [
		{
			"name": "ThreeJsBeachNeonDetail",
			"position": Vector2(1120.0, -2050.0),
			"yaw": 0.42,
			"scale": 1.4
		},
		{
			"name": "ThreeJsBrickellNeonDetail",
			"position": Vector2(610.0, -1190.0),
			"yaw": -0.26,
			"scale": 1.55
		},
		{
			"name": "ThreeJsKeysNeonDetail",
			"position": Vector2(-1040.0, -3220.0),
			"yaw": 0.18,
			"scale": 1.2
		},
		{
			"name": "ThreeJsGulfNeonDetail",
			"position": Vector2(-1600.0, -600.0),
			"yaw": 0.76,
			"scale": 1.35
		}
	]
	var models := _place_pack(
		"ThreeJsFloridaNeonDetails", THREE_FLORIDA_NEON_DETAIL_PACK, placements, 0.16
	)
	for model in models:
		_b._landmarks.add_neon_light_cluster(model, model.scale.x)


func build_regional_destinations() -> void:
	var placements := [
		{
			"name": "ThreeJsPanhandleRegionalPack",
			"position": Vector2(80.0, 4100.0),
			"yaw": -0.38,
			"scale": 1.75
		},
		{
			"name": "ThreeJsSpaceCoastRegionalPack",
			"position": Vector2(1390.0, 1250.0),
			"yaw": 0.48,
			"scale": 1.45
		},
		{
			"name": "ThreeJsWetlandRegionalPack",
			"position": Vector2(-690.0, 1150.0),
			"yaw": -0.72,
			"scale": 1.65
		},
		{
			"name": "ThreeJsKeysRegionalPack",
			"position": Vector2(-980.0, -3510.0),
			"yaw": 0.12,
			"scale": 1.25
		},
		{
			"name": "ThreeJsGulfRegionalPack",
			"position": Vector2(-1320.0, -1220.0),
			"yaw": 0.88,
			"scale": 1.4
		}
	]
	_place_pack("ThreeJsFloridaRegionalDestinations", THREE_FLORIDA_REGIONAL_PACK, placements, 0.18)


func build_infrastructure_details() -> void:
	var placements := [
		{
			"name": "ThreeJsTurnpikeInfrastructure",
			"position": Vector2(410.0, -760.0),
			"yaw": -0.26,
			"scale": 1.25
		},
		{
			"name": "ThreeJsWetlandInfrastructure",
			"position": Vector2(-520.0, 610.0),
			"yaw": 0.48,
			"scale": 1.45
		},
		{
			"name": "ThreeJsKeysInfrastructure",
			"position": Vector2(-620.0, -3720.0),
			"yaw": 0.1,
			"scale": 1.05
		},
		{
			"name": "ThreeJsBeachInfrastructure",
			"position": Vector2(1480.0, -2450.0),
			"yaw": 0.72,
			"scale": 1.2
		},
		{
			"name": "ThreeJsPanhandleInfrastructure",
			"position": Vector2(-260.0, 3720.0),
			"yaw": -0.64,
			"scale": 1.35
		},
		{
			"name": "ThreeJsGulfInfrastructure",
			"position": Vector2(-1640.0, -1480.0),
			"yaw": 0.86,
			"scale": 1.15
		}
	]
	_place_pack(
		"ThreeJsFloridaInfrastructureDetails", THREE_FLORIDA_INFRASTRUCTURE_PACK, placements, 0.2
	)


func build_environment_details() -> void:
	var placements := [
		{
			"name": "ThreeJsBeachEnvironment",
			"position": Vector2(1380.0, -2220.0),
			"yaw": 0.46,
			"scale": 1.35
		},
		{
			"name": "ThreeJsWetlandEnvironment",
			"position": Vector2(-780.0, 860.0),
			"yaw": -0.35,
			"scale": 1.5
		},
		{
			"name": "ThreeJsKeysEnvironment",
			"position": Vector2(-820.0, -3360.0),
			"yaw": 0.18,
			"scale": 1.1
		},
		{
			"name": "ThreeJsGulfEnvironment",
			"position": Vector2(-1540.0, -1040.0),
			"yaw": 0.64,
			"scale": 1.2
		},
		{
			"name": "ThreeJsNorthCoastEnvironment",
			"position": Vector2(360.0, 2320.0),
			"yaw": -0.58,
			"scale": 1.3
		},
		{
			"name": "ThreeJsCityEdgeEnvironment",
			"position": Vector2(890.0, -1510.0),
			"yaw": -0.1,
			"scale": 1.25
		}
	]
	_place_pack(
		"ThreeJsFloridaEnvironmentDetails", THREE_FLORIDA_ENVIRONMENT_PACK, placements, 0.22
	)


func build_traffic_marine_details() -> void:
	var placements := [
		{
			"name": "ThreeJsBeachTrafficMarine",
			"position": Vector2(1320.0, -2120.0),
			"yaw": 0.34,
			"scale": 1.3
		},
		{
			"name": "ThreeJsMarinaTrafficMarine",
			"position": Vector2(980.0, -1680.0),
			"yaw": -0.2,
			"scale": 1.4
		},
		{
			"name": "ThreeJsKeysTrafficMarine",
			"position": Vector2(-940.0, -3460.0),
			"yaw": 0.12,
			"scale": 1.15
		},
		{
			"name": "ThreeJsGulfTrafficMarine",
			"position": Vector2(-1460.0, -940.0),
			"yaw": 0.72,
			"scale": 1.2
		},
		{
			"name": "ThreeJsNorthTrafficMarine",
			"position": Vector2(280.0, 2200.0),
			"yaw": -0.44,
			"scale": 1.25
		},
		{
			"name": "ThreeJsTurnpikeTrafficMarine",
			"position": Vector2(520.0, -900.0),
			"yaw": -0.08,
			"scale": 1.2
		}
	]
	_place_pack(
		"ThreeJsFloridaTrafficMarineDetails", THREE_FLORIDA_TRAFFIC_MARINE_PACK, placements, 0.24
	)


func build_vista_details() -> void:
	var placements := [
		{
			"name": "ThreeJsBeachVista",
			"position": Vector2(1540.0, -2300.0),
			"yaw": 0.48,
			"scale": 1.35
		},
		{
			"name": "ThreeJsKeysVista",
			"position": Vector2(-1120.0, -3580.0),
			"yaw": 0.12,
			"scale": 1.05
		},
		{
			"name": "ThreeJsGulfVista",
			"position": Vector2(-1740.0, -1040.0),
			"yaw": 0.86,
			"scale": 1.2
		},
		{
			"name": "ThreeJsPanhandleVista",
			"position": Vector2(-140.0, 3920.0),
			"yaw": -0.52,
			"scale": 1.28
		},
		{
			"name": "ThreeJsSpaceCoastVista",
			"position": Vector2(1500.0, 1380.0),
			"yaw": 0.36,
			"scale": 1.16
		},
		{
			"name": "ThreeJsCityVista",
			"position": Vector2(760.0, -1460.0),
			"yaw": -0.18,
			"scale": 1.32
		}
	]
	_place_pack("ThreeJsFloridaVistaDetails", THREE_FLORIDA_VISTA_PACK, placements, 0.26)


func build_streetlife_details() -> void:
	var placements := [
		{
			"name": "ThreeJsBeachStreetlife",
			"position": Vector2(1180.0, -1960.0),
			"yaw": 0.38,
			"scale": 1.35
		},
		{
			"name": "ThreeJsBrickellStreetlife",
			"position": Vector2(690.0, -1220.0),
			"yaw": -0.2,
			"scale": 1.5
		},
		{
			"name": "ThreeJsKeysStreetlife",
			"position": Vector2(-1040.0, -3340.0),
			"yaw": 0.16,
			"scale": 1.0
		},
		{
			"name": "ThreeJsGulfStreetlife",
			"position": Vector2(-1580.0, -880.0),
			"yaw": 0.76,
			"scale": 1.12
		},
		{
			"name": "ThreeJsNorthStreetlife",
			"position": Vector2(220.0, 2060.0),
			"yaw": -0.5,
			"scale": 1.18
		},
		{
			"name": "ThreeJsSpaceCoastStreetlife",
			"position": Vector2(1320.0, 1120.0),
			"yaw": 0.44,
			"scale": 1.08
		}
	]
	_place_pack("ThreeJsFloridaStreetlifeDetails", THREE_FLORIDA_STREETLIFE_PACK, placements, 0.28)


func _place_pack(
	root_name: String, scene_path: String, placements: Array, y_offset: float
) -> Array[Node3D]:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("FloridaThreeJsPlacements: could not load %s" % scene_path)
		return []
	var root := Node3D.new()
	root.name = root_name
	_b.add_child(root)

	var models: Array[Node3D] = []
	for placement in placements:
		var model := scene.instantiate() as Node3D
		if model == null:
			continue
		var pos: Vector2 = placement["position"]
		var s := float(placement["scale"])
		model.name = String(placement["name"])
		model.position = Vector3(pos.x, _b.land_y + y_offset, pos.y)
		model.rotation.y = float(placement["yaw"])
		model.scale = Vector3(s, s, s)
		root.add_child(model, true)
		models.append(model)
	return models
