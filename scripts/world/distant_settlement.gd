@tool
extends Node3D
## A finite backdrop, built from shared batches rather than individual house nodes.

const STONE: Material = preload("res://materials/world/distant_stone.tres")
const ROOF: Material = preload("res://materials/world/roof.tres")
const WOOD: Material = preload("res://materials/world/old_wood.tres")
const EARTH: Material = preload("res://materials/world/earth.tres")


func _ready() -> void:
	if get_node_or_null("HouseShells") != null:
		return
	var random := RandomNumberGenerator.new()
	random.seed = 58201
	var walls: Array[Transform3D] = []
	var roofs: Array[Transform3D] = []
	var broken_roofs: Array[Transform3D] = []
	var doors: Array[Transform3D] = []
	var seals: Array[Transform3D] = []
	var rubble: Array[Transform3D] = []
	var cliffs: Array[Transform3D] = []
	# Elevated terraces and lower settlement fragments: the arena has no supports
	# reaching the ground. All backdrop geometry stays well below the battlefield.
	var sites := [
		Vector3(-32, -30, -12), Vector3(20, -27, -30),
		Vector3(31, -37, 20), Vector3(-16, -43, 32),
	]
	for site_index in range(sites.size()):
		var site: Vector3 = sites[site_index]
		cliffs.append(_pose(site + Vector3(0, -7, 0), Vector3(28, 14, 25), site_index * 0.08))
		cliffs.append(_pose(site + Vector3(3, -17, -3), Vector3(23, 10, 20), -0.07))
		for index in range(6):
			var column := index % 3
			var row := 0 if index < 3 else 1
			var position := site + Vector3((column - 1) * 6.2, 0, (row - 0.5) * 9.0)
			if site_index == 0:
				position += Vector3(2, 0, 6)
			var width := random.randf_range(2.4, 3.5)
			var height := random.randf_range(2.4, 4.0)
			var depth := random.randf_range(3.0, 4.6)
			var yaw := random.randf_range(-0.16, 0.16)
			walls.append(_pose(position + Vector3(0, height * 0.5, 0), Vector3(width, height, depth), yaw))
			var roof_position := position + Vector3(0, height + 0.65, 0)
			if index % 3 == 0:
				var broken := _pose(roof_position + Vector3(width * 0.18, -0.35, 0), Vector3(width * 0.62, 1.2, depth), yaw)
				broken.basis = broken.basis.rotated(Vector3.FORWARD, 0.22)
				broken_roofs.append(broken)
				rubble.append(_pose(position + Vector3(-width * 0.6, 0.35, 0.5), Vector3(2.3, 0.7, 1.8), yaw + 0.25))
			else:
				roofs.append(_pose(roof_position, Vector3(width + 0.3, 1.3, depth + 0.3), yaw))
			var facade := Transform3D(Basis(Vector3.UP, yaw), position)
			doors.append(facade * _pose(Vector3(0, 0.85, depth * 0.5 + 0.02), Vector3(0.65, 1.7, 0.06)))
			if index % 2 == 0:
				# Sealed door silhouettes imply abandonment/quarantine without text.
				for angle in [-0.65, 0.65]:
					var seal := _pose(Vector3(0, 0.9, depth * 0.5 + 0.08), Vector3(0.12, 1.6, 0.10))
					seal.basis = seal.basis.rotated(Vector3.FORWARD, angle)
					seals.append(facade * seal)
	var box := BoxMesh.new()
	var roof_mesh := PrismMesh.new()
	_batch("HouseShells", box, walls, STONE)
	_batch("Roofs", roof_mesh, roofs, ROOF)
	_batch("BrokenRoofs", roof_mesh, broken_roofs, ROOF)
	_batch("DoorVoids", box, doors, WOOD)
	_batch("SealedDoors", box, seals, WOOD)
	_batch("CollapsedMasonry", box, rubble, STONE)
	_batch("LayeredCliffs", box, cliffs, EARTH)
	# Cliff bottoms dissolve into the sky's mist color. There is no visible square
	# backdrop edge, enormous terrain plane or invisible catch floor.


func _pose(location: Vector3, scale_value: Vector3, yaw: float = 0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(scale_value), location)


func _batch(label: String, mesh: Mesh, transforms: Array[Transform3D], material: Material) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	# Keep CPU placement data available to editor tools and headless validation;
	# the dummy renderer does not retain MultiMesh transform buffers.
	instance.set_meta("placement_transforms", transforms)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 180
	add_child(instance)
