extends RefCounted
## Development warnings, not rejection thresholds or game rules.


static func inspect_piece(piece: Node3D) -> Array[String]:
	var result: Array[String] = []
	var visuals := piece.get_node_or_null("Visuals")
	var definition: Resource = piece.character_definition
	if visuals == null:
		result.append("Missing Visuals attachment")
		return result
	var model := visuals.get_node_or_null("Model") as Node3D
	if model == null:
		result.append("Missing visual model")
		return result
	if definition == null:
		result.append("Missing character definition")
		return result
	var scale_value: Vector3 = definition.visual_scale
	if scale_value.x <= 0 or scale_value.y <= 0 or scale_value.z <= 0:
		result.append("Use positive visual scale; use a paired variant instead of negative rig scale")
	if minf(scale_value.x, minf(scale_value.y, scale_value.z)) < 0.05 or maxf(scale_value.x, maxf(scale_value.y, scale_value.z)) > 10:
		result.append("Extreme correction scale; check export units in the source application")
	var bounds: AABB = piece.global_transform.affine_inverse() * piece.get_visual_bounds()
	if bounds.size == Vector3.ZERO:
		result.append("No renderable geometry or framing bounds")
	if bounds.size.y > 3.0:
		result.append("Height exceeds the 3 m review guideline; retest strategic/capture framing")
	if maxf(absf(bounds.position.x), absf(bounds.end.x)) > 0.72 or maxf(absf(bounds.position.z), absf(bounds.end.z)) > 0.72:
		result.append("Visual footprint exceeds one tile; check weapon/animation clearance")
	if bounds.position.y < -0.04:
		result.append("Geometry sinks below the ground pivot")
	if bounds.position.y > 0.15:
		result.append("Geometry floats above the ground pivot")
	if Vector2(bounds.get_center().x, bounds.get_center().z).length() > 0.4:
		result.append("Model is far from its ground-centered origin")
	if not model.find_children("*", "CollisionObject3D", true, false).is_empty():
		result.append("Imported visual contains collision; interaction belongs to Piece/PickBody")
	if not definition.prototype_visual and definition.picking_mode == 2:
		result.append("Use bounds/authored proxies for production geometry, not prototype-part picking")
	if not definition.prototype_visual:
		for mesh in model.find_children("*", "GeometryInstance3D", true, false):
			if mesh.visibility_range_end > 0:
				result.append("Playable mesh has a finite visibility range; review hero visibility")
				break
	if visuals.has_method("animation_warnings"):
		result.append_array(visuals.animation_warnings())
	return result
