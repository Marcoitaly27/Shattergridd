@tool
extends Node3D
## Visual-only courtyard. Tile coordinates, picking and match rules stay on Battlefield.
const Stone = preload("res://materials/foundation_stone.tres")
const Ground = preload("res://materials/world/courtyard_ground.tres")

func _ready() -> void:
	if has_node("ContinuousGround"):
		return
	var ground := MeshInstance3D.new()
	ground.name = "ContinuousGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(360, 360)
	ground.mesh = plane
	ground.material_override = Ground
	ground.position = Vector3(-35, -0.15, 0)
	add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51834
	# Two courses of paving meet the existing board rim; no geometry covers tiles.
	for side in range(4):
		for course in range(2):
			for index in range(12):
				var width := 1.08
				var center := Vector3((index - 11 * 0.5) * 1.12,
					-0.04 - course * 0.035, 7.12 + course * 1.12)
				var slab := _slab(Vector3(width, 0.18, 1.08), center.rotated(Vector3.UP, side * PI / 2))
				slab.rotation.y = side * PI / 2 + rng.randf_range(-0.009, 0.009)
	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			for x_course in range(2):
				for z_course in range(2):
					_slab(Vector3(1.08, 0.18, 1.08), Vector3(x_sign * (7.12 + x_course * 1.12), -0.075, z_sign * (7.12 + z_course * 1.12)))
	# Sparse fallen stones remain outside the playable apron, beside the ruin approach.
	for index in range(18):
		var location := Vector3(rng.randf_range(-22, -14), -0.015, rng.randf_range(-11, 16))
		var rubble := _slab(Vector3(rng.randf_range(0.2, 0.65), rng.randf_range(0.12, 0.32), rng.randf_range(0.18, 0.48)), location)
		rubble.rotation = Vector3(0.08, rng.randf_range(-PI, PI), 0.13)

func _slab(size: Vector3, location: Vector3) -> MeshInstance3D:
	var slab := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	slab.mesh = mesh
	slab.material_override = Stone
	slab.position = location
	add_child(slab)
	return slab
