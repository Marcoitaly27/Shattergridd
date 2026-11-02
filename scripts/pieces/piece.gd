@tool
extends Node3D
## Piece identity and presentation hooks. Board state owns logical occupancy.
## Replace the Visuals child with a model scene later; retain this root and its data.

enum Army { ASH, SLATE }
const CharacterDefinition = preload("res://scripts/pieces/character_definition.gd")
const StatusState = preload("res://scripts/status/status_state.gd")
const DEFAULT_MOVEMENT: Resource = preload("res://resources/characters/temporary_movement.tres")
var statuses: RefCounted = StatusState.new()

@export var piece_id: StringName = &"placeholder"
@export var character_definition: CharacterDefinition:
	set(value):
		character_definition = value
		if is_node_ready():
			_apply_appearance()
			_refresh_picking_body()
## Optional per-instance overrides; otherwise use the archetype's shared data.
@export var display_name: String = ""
@export var movement_behavior: Resource
@export var picking_height: float = 1.34
@export var picking_radius: float = 0.28
@export var army: Army = Army.ASH:
	set(value):
		army = value
		if is_node_ready():
			_apply_appearance()
			_refresh_picking_body()
@export var grid_coordinate: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_apply_appearance()
	if Engine.is_editor_hint():
		return
	_add_picking_body()
	_add_selection_ring()


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return character_definition.display_name if character_definition != null else "Stone sentinel"


func get_movement_behavior() -> Resource:
	if movement_behavior != null:
		return movement_behavior
	if character_definition != null and character_definition.movement_behavior != null:
		return character_definition.movement_behavior
	return DEFAULT_MOVEMENT


func get_pick_point() -> Vector3:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("get_pick_point"):
		return visuals.call("get_pick_point")
	return global_position + Vector3.UP * picking_height * 0.6


func get_capture_behavior() -> Resource:
	return character_definition.capture_behavior if character_definition != null else null


func apply_status(definition: Resource, starts_after: int, expires_at: int) -> bool:
	if character_definition != null and character_definition.status_immunities.has(definition.status_id):
		return false
	statuses.grant(definition, starts_after, expires_at)
	return true


func get_visual_bounds() -> AABB:
	var bounds := AABB(global_position, Vector3.ZERO)
	var started := false
	for mesh_node in $Visuals.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var part := mesh.global_transform * mesh.mesh.get_aabb()
		bounds = bounds.merge(part) if started else part
		started = true
	return bounds


func set_selected(selected: bool) -> void:
	var ring := get_node_or_null("SelectionRing") as Node3D
	if ring != null:
		ring.visible = selected


func animate_to(destination: Vector3, duration: float) -> Tween:
	var animation := create_tween()
	animation.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return animation


func _add_picking_body() -> void:
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("create_picking_body"):
		if visuals.call("create_picking_body", self):
			return
	# Fallback for replacement models without a compound picking implementation.
	var body := StaticBody3D.new()
	body.name = "PickBody"
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("piece", self)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = picking_radius
	shape.height = picking_height
	collision.shape = shape
	collision.position.y = picking_height * 0.5
	body.add_child(collision)
	var base_collision := CollisionShape3D.new()
	var base_shape := CylinderShape3D.new()
	base_shape.radius = 0.44
	base_shape.height = 0.32
	base_collision.shape = base_shape
	base_collision.position.y = 0.16
	body.add_child(base_collision)
	add_child(body)


func _refresh_picking_body() -> void:
	if Engine.is_editor_hint():
		return
	var previous := get_node_or_null("PickBody")
	if previous != null:
		remove_child(previous)
		previous.queue_free()
	_add_picking_body()


func _add_selection_ring() -> void:
	var ring := Node3D.new()
	ring.name = "SelectionRing"
	# Outline outside architectural bases, rather than hiding a circular ring
	# inside the new rectangular plinths. It still stays within a single tile.
	ring.position.y = 0.025
	for side in range(4):
		var edge := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(1.36, 0.014, 0.035)
		edge.mesh = bar
		edge.material_override = preload("res://materials/move_hint.tres")
		edge.position = Vector3(0, 0, 0.68).rotated(Vector3.UP, side * PI * 0.5)
		edge.rotation.y = side * PI * 0.5
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(edge)
	ring.visible = false
	add_child(ring)


func _apply_appearance() -> void:
	# Future model scenes keep their own materials and animation hierarchy.
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("set_character"):
		visuals.call("set_character", character_definition)
	if visuals != null and visuals.has_method("set_army"):
		visuals.call("set_army", army)
