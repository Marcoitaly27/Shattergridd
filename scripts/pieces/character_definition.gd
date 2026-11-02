@tool
extends Resource
## Shared character data. Category, character identity and cinematic archetype are distinct.

const AnimationConfig = preload("res://scripts/visuals/animation_config.gd")
const StoneSurface = preload("res://scripts/visuals/stone_surface.gd")
@export var character_id: StringName
@export var title: String
@export var deployment_category: StringName
@export_multiline var gameplay_description: String
## Presentation family retained for existing cinematic/debug tools. Not a unique ID.
@export var archetype_id: StringName
@export var display_name: String
@export_multiline var lore_description: String
@export var model_scene: PackedScene
@export_group("Visual integration")
@export var visual_scale: Vector3 = Vector3.ONE
@export var visual_offset: Vector3 = Vector3.ZERO
@export var visual_rotation_degrees: Vector3 = Vector3.ZERO
@export var paired_model_scene: PackedScene
@export var prototype_visual: bool = true
@export_enum("Bounds proxy", "Authored proxies", "Prototype parts") var picking_mode: int = 2
@export var framing_bounds: AABB
@export var animation_config: AnimationConfig
@export_enum("Keep authored", "Whole mesh prototype", "Named surfaces") var team_material_mode: int = 1
@export var team_surface_names: Array[StringName] = []
@export var stone_material_profile: StoneSurface
@export var team_tints: Array[Color] = []
@export_group("Gameplay")
@export var movement_behavior: Resource
@export var capture_behavior: Resource
@export var post_capture_effect: Resource
@export var active_ability: StringName
@export var passive_ability: StringName
@export_multiline var ability_description: String
@export var night_movement_behavior: Resource
@export var night_model_scene: PackedScene
@export var night_capture_behavior: Resource
@export var audio_profile: Resource
@export var is_core_objective: bool = false
@export var status_immunities: Array[StringName] = []
## Empty means the model keeps its authored materials (for later imported statues).
@export var team_materials: Array[Material] = []

@export_group("Collection")
@export var unlocked_by_default: bool = true
@export var unlock_condition_id: StringName
@export var hidden_until_unlocked: bool = false
