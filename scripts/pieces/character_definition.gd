@tool
extends Resource
## Archetype data, separate from per-instance identity, ownership and board state.

@export var archetype_id: StringName
@export var display_name: String
@export_multiline var lore_description: String
@export var model_scene: PackedScene
@export var movement_behavior: Resource
@export var capture_behavior: Resource
@export var post_capture_effect: Resource
@export var is_core_objective: bool = false
@export var status_immunities: Array[StringName] = []
## Empty means the model keeps its authored materials (for later imported statues).
@export var team_materials: Array[Material] = []
