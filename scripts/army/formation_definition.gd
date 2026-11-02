extends Resource
## Slot layout is replaceable data, independent from board rendering and loadouts.

const DeploymentSlot = preload("res://scripts/army/deployment_slot.gd")
@export var formation_id: StringName
@export var display_name: String
@export var board_dimensions: Vector2i = Vector2i(8, 8)
@export var slots: Array[DeploymentSlot] = []


func coordinate_for_player(cell: Vector2i, player: int) -> Vector2i:
	return cell if player == 0 else Vector2i(cell.x, board_dimensions.y - 1 - cell.y)
