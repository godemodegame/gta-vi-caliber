class_name VisibilityRange
extends RefCounted
## Applies distance culling only to renderable geometry. Node3D containers do
## not own visibility ranges, so callers can safely pass an assembled subtree.


static func apply_to_tree(
	root: Node, range_end: float, fade_mode: int = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
) -> int:
	var applied := 0
	if root is GeometryInstance3D:
		var geometry := root as GeometryInstance3D
		geometry.visibility_range_end = maxf(range_end, 0.0)
		geometry.visibility_range_fade_mode = fade_mode
		applied += 1
	for child in root.get_children():
		applied += apply_to_tree(child, range_end, fade_mode)
	return applied


static func renders_at_distance(geometry: GeometryInstance3D, distance: float) -> bool:
	if geometry == null or not geometry.visible:
		return false
	var range_end := geometry.visibility_range_end
	return range_end <= 0.0 or maxf(distance, 0.0) < range_end
