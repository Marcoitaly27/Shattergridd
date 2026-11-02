@tool
extends Node3D
## Non-destructive decorative wrapper. No board, progression or match references.

const Geometry = preload("res://scripts/visuals/geometry_helpers.gd")
@export_enum("Structural arena", "Background architecture", "Props", "Vegetation", "VFX", "Lighting") var category: int = 1
@export var model_scene: PackedScene
@export var visual_scale: Vector3 = Vector3.ONE
@export var visual_offset: Vector3
@export var visual_rotation_degrees: Vector3
@export var visibility_end: float = 180.0
@export var cast_shadows: bool = false
var _model: Node3D


func _ready() -> void:
	replace_asset(model_scene)


func replace_asset(scene: PackedScene) -> void:
	if is_instance_valid(_model):
		remove_child(_model)
		_model.queue_free()
	_model = null
	model_scene = scene
	if scene == null:
		return
	var node := scene.instantiate()
	if not node is Node3D:
		node.free()
		return
	_model = node
	_model.name = "VisualRoot"
	Geometry.disable_source_collision(_model)
	add_child(_model)
	_model.position = visual_offset
	_model.rotation_degrees = visual_rotation_degrees
	_model.scale = visual_scale.abs().clamp(Vector3.ONE * 0.001, Vector3.ONE * 100)
	var geometry := _model.find_children("*", "GeometryInstance3D", true, false)
	if _model is GeometryInstance3D:
		geometry.append(_model)
	for mesh in geometry:
		mesh.visibility_range_end = maxf(visibility_end, 0.0)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func validation_warnings() -> Array[String]:
	var result: Array[String] = []
	if _model == null:
		result.append("No environment asset assigned")
	elif category != 0 and not _model.find_children("*", "CollisionObject3D", true, false).is_empty():
		result.append("Decorative source contains collision; remove it in the wrapper/import settings")
	return result
