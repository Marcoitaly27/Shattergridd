@tool
extends Resource
## Shared character data. Category, character identity and cinematic archetype are distinct.

@export var character_id: StringName
@export var title: String
@export var deployment_category: StringName
@export_multiline var gameplay_description: String
## Presentation family retained for existing cinematic/debug tools. Not a unique ID.
@export var archetype_id: StringName
@export var display_name: String
@export_multiline var lore_description: String
@export var model_scene: PackedScene
@export var movement_behavior: Resource
@export var capture_behavior: Resource
@export var post_capture_effect: Resource
@export var audio_profile: Resource
@export var is_core_objective: bool = false
@export var status_immunities: Array[StringName] = []
## Empty means the model keeps its authored materials (for later imported statues).
@export var team_materials: Array[Material] = []

@export_group("Collection")
@export var unlocked_by_default: bool = true
@export var unlock_condition_id: StringName
@export var hidden_until_unlocked: bool = false
