@tool
extends Node3D
## Presentation-only world. No references to board state, turns or character rules.

const Courtyard = preload("res://scripts/world/grounded_courtyard.gd")
const Brazier = preload("res://scenes/world/modules/brazier.tscn")


func _ready() -> void:
	if get_node_or_null("GroundedCourtyard") != null:
		return
	var courtyard := Node3D.new()
	courtyard.name = "GroundedCourtyard"
	courtyard.set_script(Courtyard)
	add_child(courtyard)
	var fires := Node3D.new()
	fires.name = "RitualBraziers"
	add_child(fires)
	_place(fires, Brazier, "WestBrazier", Vector3(-6.5, 0.08, 6.5), 0)
	_place(fires, Brazier, "EastBrazier", Vector3(6.5, 0.08, -6.5), 0)


func _place(parent: Node3D, scene: PackedScene, label: String, location: Vector3, yaw: float) -> void:
	var instance := scene.instantiate() as Node3D
	instance.name = label
	instance.position = location
	instance.rotation.y = yaw
	parent.add_child(instance)
