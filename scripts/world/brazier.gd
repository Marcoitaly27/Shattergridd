@tool
extends Node3D
## Two restrained local flames; no random global lighting or expensive fire shader.

var _age: float = 0.0


func _ready() -> void:
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_age += delta
	$Flame.scale = Vector3(1.0 + sin(_age * 3.1) * 0.035, 1.0 + sin(_age * 4.7) * 0.10, 1.0)
	$Flame.rotation.z = sin(_age * 2.7) * 0.045
	$Firelight.light_energy = 0.85 + sin(_age * 3.7) * 0.035 + sin(_age * 2.1) * 0.015
