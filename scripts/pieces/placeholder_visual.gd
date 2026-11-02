@tool
extends Node3D
## Reusable visual attachment (legacy filename). Never owns board or turn state.

const Geometry = preload("res://scripts/visuals/geometry_helpers.gd")
const AnimationAdapter = preload("res://scripts/visuals/visual_animation.gd")
var animation := AnimationAdapter.new()
var presentation_locked: bool = false
var _definition: Resource
var _model: Node3D
var _override: PackedScene
var _loaded_scene: PackedScene
var _reflected: bool = false
var _army: int = 0
var _night: bool = false
var _instance_tint: Color = Color.WHITE
var _materials: Dictionary = {}


func set_character(definition: Resource) -> void:
	if definition != _definition:
		_override = null
	_definition = definition
	var scene: PackedScene = _override
	if scene == null and definition != null:
		scene = definition.paired_model_scene if _reflected and definition.paired_model_scene != null else definition.model_scene
		if _night and definition.night_model_scene != null:
			scene = definition.night_model_scene
	if scene != _loaded_scene or not is_instance_valid(_model):
		animation.bind_model(null, null)
		_materials.clear()
		if is_instance_valid(_model):
			remove_child(_model)
			_model.queue_free()
		_model = null
		_loaded_scene = scene
		if scene != null:
			var instance := scene.instantiate()
			_model = instance as Node3D
			if _model == null:
				instance.free()
			if _model != null:
				_model.name = "Model"
				Geometry.disable_source_collision(_model)
				add_child(_model)
				_remember_materials()
	if _model != null and definition != null:
		_model.scale = definition.visual_scale.abs().clamp(Vector3.ONE * 0.001, Vector3.ONE * 100)
		_model.position = definition.visual_offset
		_model.rotation_degrees = definition.visual_rotation_degrees
		animation.bind_model(_model, definition.animation_config)
	_apply_team_material()


func set_model_override(scene: PackedScene) -> bool:
	if presentation_locked:
		return false
	_override = scene
	set_character(_definition)
	return _model != null


func set_reflected(reflected: bool) -> void:
	if _reflected != reflected:
		_reflected = reflected
		set_character(_definition)


func set_night(night: bool) -> void:
	if _night != night:
		_night = night
		set_character(_definition)


func set_army(army: int) -> void:
	_army = army
	rotation.y = 0.0 if army == 0 else PI
	_apply_team_material()


func set_instance_tint(tint: Color) -> void:
	_instance_tint = tint
	_apply_team_material()


func get_visual_bounds() -> AABB:
	if _model == null:
		return AABB(global_position, Vector3.ZERO)
	if _definition != null and _definition.framing_bounds.size != Vector3.ZERO:
		return _model.global_transform * _definition.framing_bounds
	return Geometry.bounds_in(_model, Transform3D.IDENTITY)


func get_pick_point() -> Vector3:
	if is_instance_valid(_model):
		var anchor := _model.find_child("PickAnchor", true, false) as Marker3D
		if anchor != null:
			return anchor.global_position
		return get_visual_bounds().get_center()
	return global_position + Vector3.UP * 0.6


func create_picking_body(piece: Node3D) -> bool:
	if _model == null or _definition == null:
		return false
	var body := StaticBody3D.new()
	body.name = "PickBody"
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("piece", piece)
	piece.add_child(body)
	var mode: int = _definition.picking_mode
	var meshes := Geometry.meshes(_model)
	if mode == 1:
		for proxy in _model.find_children("*", "Node3D", true, false):
			if proxy.has_method("get_proxy_shape"):
				var shape: Shape3D = proxy.get_proxy_shape()
				if shape != null:
					_add_shape(body, shape, piece.global_transform.affine_inverse() * proxy.global_transform)
	elif mode == 2 and meshes.all(func(mesh: MeshInstance3D) -> bool: return mesh.mesh is PrimitiveMesh):
		for mesh in meshes:
			var bounds := mesh.mesh.get_aabb()
			var local := piece.global_transform.affine_inverse() * mesh.global_transform
			var shape := BoxShape3D.new()
			shape.size = bounds.size.max(Vector3.ONE * 0.01)
			_add_shape(body, shape, local * Transform3D(Basis.IDENTITY, bounds.get_center()))
	if body.get_child_count() == 0:
		# Production geometry gets one simple proxy, never a concave rendered mesh.
		var bounds := Geometry.bounds_in(_model, piece.global_transform)
		var shape := BoxShape3D.new()
		shape.size = bounds.size.max(Vector3.ONE * 0.05)
		_add_shape(body, shape, Transform3D(Basis.IDENTITY, bounds.get_center()))
	return true


func _add_shape(body: StaticBody3D, source: Shape3D, local: Transform3D) -> void:
	var shape: Shape3D = source.duplicate()
	var scale_value := local.basis.get_scale().abs().max(Vector3.ONE * 0.001)
	if shape is BoxShape3D:
		shape.size *= scale_value
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		shape.radius *= maxf(scale_value.x, scale_value.z)
		shape.height = maxf(shape.height * scale_value.y, shape.radius * 2.0)
	elif shape is SphereShape3D:
		shape.radius *= maxf(scale_value.x, maxf(scale_value.y, scale_value.z))
	else:
		return # A simple supported proxy or the bounds fallback is preferable.
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(local.basis.orthonormalized(), local.origin)
	body.add_child(collision)


func _remember_materials() -> void:
	for mesh in Geometry.meshes(_model, false):
		var surfaces: Array[Material] = []
		for index in range(mesh.mesh.get_surface_count()):
			surfaces.append(mesh.get_active_material(index))
		_materials[mesh] = {"override": mesh.material_override, "surfaces": surfaces}


func _apply_team_material() -> void:
	if not is_instance_valid(_model) or _definition == null:
		return
	var mode: int = _definition.team_material_mode
	var material: Material
	if _definition.stone_material_profile != null:
		material = _definition.stone_material_profile.build_material()
	elif _army >= 0 and _army < _definition.team_materials.size():
		material = _definition.team_materials[_army]
	var tint := _instance_tint
	if _army >= 0 and _army < _definition.team_tints.size():
		tint *= _definition.team_tints[_army]
	if material != null and tint != Color.WHITE and material is BaseMaterial3D:
		material = material.duplicate()
		material.albedo_color *= tint
	for mesh in _materials:
		var authored: Dictionary = _materials[mesh]
		mesh.material_override = authored.override
		for index in range(authored.surfaces.size()):
			mesh.set_surface_override_material(index, authored.surfaces[index])
		if mode == 0 or material == null:
			continue
		if mode == 1:
			mesh.material_override = material
		else:
			mesh.material_override = null
			for index in range(authored.surfaces.size()):
				var original: Material = authored.surfaces[index]
				var chosen: Material = material if original != null and _definition.team_surface_names.has(StringName(original.resource_name)) else original
				mesh.set_surface_override_material(index, chosen)


func request_animation(state: StringName) -> bool:
	return animation.request_state(state)


func set_presentation_locked(locked: bool) -> void:
	presentation_locked = locked


func authored_capture_ready() -> bool:
	return animation.capture_ready()


func capture_duration() -> float:
	return animation.capture_duration()


func begin_authored_capture(handler: Callable) -> bool:
	return animation.begin_capture(handler)


func advance_authored_capture(time: float) -> void:
	animation.advance_to(time)


func end_authored_capture() -> void:
	animation.end_capture()


func animation_warnings() -> Array[String]:
	return animation.warnings()


func asset_info() -> Dictionary:
	return {"scene": _loaded_scene.resource_path if _loaded_scene != null else "none",
		"scale": _model.scale if _model != null else Vector3.ZERO,
		"offset": _model.position if _model != null else Vector3.ZERO,
		"rotation": _model.rotation_degrees if _model != null else Vector3.ZERO,
		"animation": str(_model.get_path_to(animation.player)) if is_instance_valid(animation.player) else "procedural Tween",
		"team_mode": _definition.team_material_mode if _definition != null else 0,
		"team": _army, "reflected": _reflected,
		"stage": "PROTOTYPE" if _definition == null or _definition.prototype_visual else "production integration"}


func _exit_tree() -> void:
	animation.end_capture()
