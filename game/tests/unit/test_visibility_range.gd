extends RefCounted
## Regression coverage for geometry-only visibility ranges.


func test_applies_ranges_to_nested_geometry_only() -> bool:
	var root := Node3D.new()
	var container := Node3D.new()
	var mesh := MeshInstance3D.new()
	var multimesh := MultiMeshInstance3D.new()
	root.add_child(container)
	container.add_child(mesh)
	root.add_child(multimesh)

	var applied := VisibilityRange.apply_to_tree(root, 125.0)
	var ok := (
		applied == 2
		and mesh.visibility_range_end == 125.0
		and multimesh.visibility_range_end == 125.0
		and mesh.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	)
	root.free()
	return ok


func test_distant_geometry_falls_outside_render_range() -> bool:
	var mesh := MeshInstance3D.new()
	VisibilityRange.apply_to_tree(mesh, 100.0)
	var ok := (
		VisibilityRange.renders_at_distance(mesh, 99.0)
		and not VisibilityRange.renders_at_distance(mesh, 100.0)
		and not VisibilityRange.renders_at_distance(mesh, 250.0)
	)
	mesh.free()
	return ok
