@tool
extends Node3D
## A visual placeholder with identity and placement data, not a gameplay controller.
## Replace the Visuals child with a model scene later; retain this root and its data.

enum Army { ASH, SLATE }

@export var piece_id: StringName = &"placeholder"
@export var army: Army = Army.ASH:
	set(value):
		army = value
		if is_node_ready():
			_apply_appearance()
@export var grid_coordinate: Vector2i = Vector2i.ZERO


func _ready() -> void:
	_apply_appearance()


func _apply_appearance() -> void:
	# Future model scenes keep their own materials and animation hierarchy.
	var visuals := get_node_or_null("Visuals")
	if visuals != null and visuals.has_method("set_army"):
		visuals.call("set_army", army)
