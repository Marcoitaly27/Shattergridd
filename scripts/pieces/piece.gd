@tool
extends Node3D
## Piece identity and presentation hooks. Board state owns logical occupancy.
## Replace the Visuals child with a model scene later; retain this root and its data.

enum Army { ASH, SLATE }
const AdjacentMovement = preload("res://scripts/movement/adjacent_movement.gd")

@export var piece_id: StringName = &"placeholder"
@export var display_name: String = "Stone sentinel"
@export var movement_behavior: Resource = AdjacentMovement.new()
@export var picking_height: float = 1.34
@export var picking_radius: float = 0.28
@export var army: Army = Army.ASH:
	set(value):
		army = value
		if is_node_ready():
			_apply_appearance()
@export var grid_coordinate: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_apply_appearance()
	if Engine.is_editor_hint():
		return
	_add_picking_body()
	_add_selection_ring()


func set_selected(selected: bool) -> void:
	var ring := get_node_or_null("SelectionRing") as MeshInstance3D
	if ring != null:
		ring.visible = selected


func animate_to(destination: Vector3, duration: float) -> Tween:
	var animation := create_tween()
	animation.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return animation


func _add_picking_body() -> void:
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


func _add_selection_ring() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.46
	torus.outer_radius = 0.51
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = preload("res://materials/move_hint.tres")
	ring.position.y = 0.035
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	add_child(ring)


func _apply_appearance() -> void:
	# Future model scenes keep their own materials and animation hierarchy.
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("set_army"):
		visuals.call("set_army", army)
