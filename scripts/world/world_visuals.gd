@tool
extends Node3D
## Presentation-only world. No references to board state, turns or character rules.

const Settlement = preload("res://scenes/world/distant_settlement.tscn")
const Architecture = preload("res://scenes/world/floating_architecture.tscn")
const Chapel = preload("res://scenes/world/modules/ruined_chapel.tscn")
const Gallows = preload("res://scenes/world/modules/abandoned_gallows.tscn")
const Relic = preload("res://scenes/world/modules/draconic_relic.tscn")
const Brazier = preload("res://scenes/world/modules/brazier.tscn")


func _ready() -> void:
	if get_node_or_null("FloatingArchitecture") != null:
		return
	var architecture := Architecture.instantiate() as Node3D
	architecture.name = "FloatingArchitecture"
	add_child(architecture)
	var settlement := Settlement.instantiate() as Node3D
	settlement.name = "DistantSettlement"
	add_child(settlement)
	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	add_child(landmarks)
	_place(landmarks, Chapel, "RuinedChapel", Vector3(-32, -30, -12), 0.20)
	_place(landmarks, Gallows, "AbandonedExecutionSquare", Vector3(-43, -30, -8), -0.20)
	_place(landmarks, Relic, "BrokenDraconicRelic", Vector3(10, -27, -32), 0.65)
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
