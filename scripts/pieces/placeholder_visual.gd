@tool
extends Node3D
## Temporary primitive appearance; independent of the reusable piece root.

const ASH_MATERIAL: Material = preload("res://materials/ash_statue.tres")
const SLATE_MATERIAL: Material = preload("res://materials/slate_statue.tres")


func set_army(army: int) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = ASH_MATERIAL if army == 0 else SLATE_MATERIAL
	$Crown.visible = army == 0
	$Hood.visible = army == 1
