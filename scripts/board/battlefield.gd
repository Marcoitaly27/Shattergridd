@tool
extends Node3D
## Masonry, picking surfaces and move hints. Occupancy lives in board_state.gd.

const BOARD_SIZE: int = 8
const TILE_SPACING: float = 1.5
const TILE_HEIGHT: float = 0.24
const PALE_STONE: Material = preload("res://materials/pale_stone.tres")
const DARK_STONE: Material = preload("res://materials/dark_stone.tres")
const FOUNDATION_STONE: Material = preload("res://materials/foundation_stone.tres")
const MOVE_HINT: Material = preload("res://materials/move_hint.tres")
const ATTACK_HINT: Material = preload("res://materials/attack_hint.tres")

@export var board_dimensions: Vector2i = Vector2i(8, 8)
var _tiles: Dictionary = {}


func grid_to_local(cell: Vector2i) -> Vector3:
	var half_span := Vector2(board_dimensions - Vector2i.ONE) * TILE_SPACING * 0.5
	return Vector3(cell.x * TILE_SPACING - half_span.x, TILE_HEIGHT * 0.5,
		cell.y * TILE_SPACING - half_span.y)


func position_for_cell(cell: Vector2i) -> Vector3:
	var result := grid_to_local(cell)
	var tile := _tiles.get(cell) as MeshInstance3D
	if tile != null:
		result.y = tile.position.y + TILE_HEIGHT * 0.5 + 0.015
	return result


func clear_highlights() -> void:
	for tile in _tiles.values():
		tile.get_node("MoveHint").hide()


func show_destinations(cells: Array[Vector2i], state: RefCounted) -> void:
	clear_highlights()
	for cell in cells:
		var tile := _tiles.get(cell) as MeshInstance3D
		if tile == null:
			continue
		var hint: Node3D = tile.get_node("MoveHint")
		for edge in hint.get_children():
			edge.material_override = ATTACK_HINT if state.piece_at(cell) != null else MOVE_HINT
		hint.show()


func _ready() -> void:
	# Generated children deliberately have no owner: they are regenerated, not saved.
	if get_node_or_null("Tiles") != null:
		return
	var tiles := Node3D.new()
	tiles.name = "Tiles"
	add_child(tiles)
	var random := RandomNumberGenerator.new()
	random.seed = 71083
	for row in range(board_dimensions.y):
		for column in range(board_dimensions.x):
			var tile := _box(Vector3(1.455, TILE_HEIGHT, 1.455),
				PALE_STONE if (row + column) % 2 == 0 else DARK_STONE)
			tile.mesh = _worn_tile_mesh(random)
			tile.name = "Tile_%d_%d" % [column, row]
			tile.position = grid_to_local(Vector2i(column, row))
			tile.position.y = random.randf_range(-0.009, 0.009)
			tile.rotation.y = random.randf_range(-0.004, 0.004)
			var surface := tile.material_override.duplicate() as StandardMaterial3D
			var tint := random.randf_range(0.92, 1.04)
			surface.albedo_color = Color(tint, tint, tint, 1.0)
			surface.uv1_offset = Vector3(random.randf_range(0, 8), 0, random.randf_range(0, 8))
			tile.material_override = surface
			tile.set_meta("grid_coordinate", Vector2i(column, row))
			tiles.add_child(tile)
			_tiles[Vector2i(column, row)] = tile
			_add_tile_interaction(tile, Vector2i(column, row))
	_build_foundation(random)


func _add_tile_interaction(tile: MeshInstance3D, cell: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.name = "PickSurface"
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("grid_coordinate", cell)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.455, TILE_HEIGHT, 1.455)
	collision.shape = shape
	body.add_child(collision)
	tile.add_child(body)
	var hint := Node3D.new()
	hint.name = "MoveHint"
	hint.visible = false
	tile.add_child(hint)
	for side in range(4):
		var edge := _box(Vector3(1.27, 0.014, 0.035), MOVE_HINT)
		edge.position = Vector3(0, TILE_HEIGHT * 0.5 + 0.018, 0.635).rotated(Vector3.UP, side * PI * 0.5)
		edge.rotation.y = side * PI * 0.5
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hint.add_child(edge)


func _worn_tile_mesh(random: RandomNumberGenerator) -> ArrayMesh:
	# Small clipped corners and sloped edges catch light like worn masonry.
	# Native geometry keeps this independent of shaders and imported assets.
	var half_width := 0.7275
	var cut := random.randf_range(0.035, 0.085)
	var outline := PackedVector2Array([
		Vector2(-half_width + cut, -half_width), Vector2(half_width - cut, -half_width),
		Vector2(half_width, -half_width + cut), Vector2(half_width, half_width - cut),
		Vector2(half_width - cut, half_width), Vector2(-half_width + cut, half_width),
		Vector2(-half_width, half_width - cut), Vector2(-half_width, -half_width + cut),
	])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Flat triangle normals preserve the small bevels under directional light.
	surface.set_smooth_group(-1)
	for index in range(outline.size()):
		var next := (index + 1) % outline.size()
		var a := Vector3(outline[index].x, TILE_HEIGHT * 0.5, outline[index].y) * Vector3(0.96, 1, 0.96)
		var b := Vector3(outline[next].x, TILE_HEIGHT * 0.5, outline[next].y) * Vector3(0.96, 1, 0.96)
		var c := Vector3(outline[index].x, TILE_HEIGHT * 0.5 - 0.035, outline[index].y)
		var d := Vector3(outline[next].x, TILE_HEIGHT * 0.5 - 0.035, outline[next].y)
		var e := Vector3(c.x, -TILE_HEIGHT * 0.5, c.z)
		var f := Vector3(d.x, -TILE_HEIGHT * 0.5, d.z)
		for vertex in [Vector3(0, TILE_HEIGHT * 0.5, 0), a, b,
			a, c, d, a, d, b, c, e, f, c, f, d,
			Vector3(0, -TILE_HEIGHT * 0.5, 0), f, e]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


func _build_foundation(random: RandomNumberGenerator) -> void:
	var foundation := Node3D.new()
	foundation.name = "Foundation"
	foundation.scale = Vector3(float(board_dimensions.x) / BOARD_SIZE, 1, float(board_dimensions.y) / BOARD_SIZE)
	add_child(foundation)
	# Broad courses and a tapered underside expose the floating structure's depth.
	_add_block(foundation, "UpperCourse", Vector3(13.65, 0.38, 13.65), Vector3(0, -0.32, 0))
	_add_block(foundation, "CentralMass", Vector3(13.15, 1.25, 13.15), Vector3(0, -1.08, 0))
	_add_block(foundation, "LowerCourse", Vector3(13.5, 0.22, 13.5), Vector3(0, -1.82, 0))
	_add_block(foundation, "Underside", Vector3(11.9, 0.6, 11.9), Vector3(0, -2.2, 0))
	for side in range(4):
		var rotation_angle := side * PI * 0.5
		for index in range(9):
			var block := _box(Vector3(1.43, random.randf_range(0.27, 0.35), 0.53), FOUNDATION_STONE)
			block.name = "Rim_%d_%d" % [side, index]
			block.position = Vector3((index - 4) * 1.47, -0.025, 6.3).rotated(Vector3.UP, rotation_angle)
			block.rotation.y = rotation_angle + random.randf_range(-0.014, 0.014)
			foundation.add_child(block)
		for index in range(5):
			var bracket := _box(Vector3(0.42, 1.35, 0.42), FOUNDATION_STONE)
			bracket.name = "Buttress_%d_%d" % [side, index]
			bracket.position = Vector3((index - 2) * 2.65, -1.15, 6.57).rotated(Vector3.UP, rotation_angle)
			bracket.rotation.y = rotation_angle
			foundation.add_child(bracket)


func _add_block(parent: Node3D, label: String, size: Vector3, location: Vector3) -> void:
	var block := _box(size, FOUNDATION_STONE)
	block.name = label
	block.position = location
	parent.add_child(block)


func _box(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	return mesh_instance
