@tool
extends Node3D
## Loads the chosen prototype model. Character data never lives in GameManager.

var _definition: Resource
var _model: Node3D
var _army: int = 0


func set_character(definition: Resource) -> void:
	if definition == _definition and is_instance_valid(_model):
		return
	_definition = definition
	if is_instance_valid(_model):
		remove_child(_model)
		_model.queue_free()
	_model = null
	if definition == null or definition.model_scene == null:
		return
	_model = definition.model_scene.instantiate() as Node3D
	_model.name = "Model"
	add_child(_model)
	_apply_team_material()


func set_army(army: int) -> void:
	_army = army
	rotation.y = 0.0 if army == 0 else PI
	_apply_team_material()


func create_picking_body(piece: Node3D) -> bool:
	if not is_instance_valid(_model):
		return false
	var body := StaticBody3D.new()
	body.name = "PickBody"
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("piece", piece)
	piece.add_child(body)
	# One compound body follows the actual primitive parts, preserving negative
	# space around shrines, weapons and the low creature instead of a tall cylinder.
	for mesh_node in _model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh_node as MeshInstance3D
		if instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		var local := piece.global_transform.affine_inverse() * instance.global_transform
		var shape := BoxShape3D.new()
		shape.size = bounds.size * local.basis.get_scale().abs()
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = Transform3D(local.basis.orthonormalized(), local * bounds.get_center())
		body.add_child(collision)
	return true


func get_pick_point() -> Vector3:
	if is_instance_valid(_model):
		var anchor := _model.get_node_or_null("PickAnchor") as Marker3D
		if anchor != null:
			return anchor.global_position
	return global_position + Vector3.UP * 0.6


func _apply_team_material() -> void:
	if not is_instance_valid(_model) or _definition == null:
		return
	if _army < 0 or _army >= _definition.team_materials.size():
		return
	var material: Material = _definition.team_materials[_army]
	if material == null:
		return
	for mesh_node in _model.find_children("*", "MeshInstance3D", true, false):
		(mesh_node as MeshInstance3D).material_override = material
