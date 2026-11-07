@tool
extends Node3D
## Imported iron fire basket and restrained crossed flame surfaces.

var _age: float = 0.0


func _ready() -> void:
	for part in $Basket.find_children("*", "MeshInstance3D", true, false):
		if part.name == "Iron":
			part.material_override = preload("res://materials/world/aged_iron.tres")
	set_process(not Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		add_to_group("audio_fire")


func _process(delta: float) -> void:
	_age += delta
	$Flame.scale = Vector3(1.0 + sin(_age * 3.1) * 0.035, 1.0 + sin(_age * 4.7) * 0.10, 1.0)
	$Flame.rotation.z = sin(_age * 2.7) * 0.045
	$Firelight.light_energy = 0.85 + sin(_age * 3.7) * 0.035 + sin(_age * 2.1) * 0.015
