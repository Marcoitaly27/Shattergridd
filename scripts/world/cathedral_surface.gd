@tool
extends Node3D
## Presentation-only material attachment; original imported geometry stays recoverable.
const STONE = preload("res://materials/world/cathedral_stone.tres")
func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		node.material_override = STONE
