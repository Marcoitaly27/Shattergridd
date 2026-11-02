extends Node
## Presentation bridge. Audio observes authoritative events; it cannot finish actions.

const Scheduler = preload("res://scripts/audio/ambient_scheduler.gd")
const GLOBAL_EVENTS := {
	&"capture_started": &"capture.start", &"stone_impact": &"capture.stone_impact",
	&"stone_crack": &"capture.fracture", &"debris": &"capture.break",
}
var scope: int
var scheduler: Node
var _wind: int = 0
var _wind_age: float = 0.0

@onready var sound: Node = get_node("/root/SoundManager")
@onready var game: Node = $"../GameManager"


func _ready() -> void:
	scope = get_parent().get_instance_id()
	sound.begin_scope(scope, &"match")
	game.movement_cue.connect(_on_movement)
	game.selection_changed.connect(_on_selection)
	game.selection_cancelled.connect(func() -> void: sound.play_ui(&"ui.cancel"))
	$"../Interaction".hover_changed.connect(func(_cell: Vector2i, kind: StringName, _piece: Node3D) -> void:
		if kind in [&"selectable", &"capture"]:
			sound.play_ui(&"ui.hover"))
	game.feedback_requested.connect(_on_feedback)
	game.victory.connect(_on_victory)
	game.capture_director.cue_emitted.connect(_on_capture_cue)
	game.capture_director.completed.connect(_on_capture_end)
	game.capture_director.cancelled.connect(_on_cancelled)
	game.capture_director.destruction_spawned.connect(_on_destruction)
	_wind = sound.play_id(&"ambience.wind", null, scope, &"ambience", "wind")
	sound.play_id(&"ambience.world", null, scope, &"ambience", "world")
	var fires := get_tree().get_nodes_in_group("audio_fire")
	var fire_index := 0
	for fire in fires:
		if get_parent().is_ancestor_of(fire) and fire_index < 2:
			sound.play_id(&"environment.fire", fire.global_position, scope, &"ambience", "fire_%d" % fire_index, fire)
			fire_index += 1
	scheduler = Scheduler.new()
	add_child(scheduler)
	scheduler.start(scope)
	if _wind != 0:
		var variation := Timer.new()
		variation.wait_time = 1.5
		variation.timeout.connect(func() -> void:
			_wind_age += 1.5
			sound.set_loop_gain(_wind, sin(_wind_age * TAU / 75.0) * 0.6))
		add_child(variation)
		variation.start()
	_bind_controls($"../Interface")


func _on_movement(event: StringName, piece: Node3D) -> void:
	var definition: Resource = piece.character_definition
	if definition != null:
		sound.play_profile(definition.audio_profile, event, piece.global_position, scope)


func _on_selection(piece: Node3D) -> void:
	if piece != null:
		sound.play_ui(&"ui.select")


func _on_feedback(_message: String, kind: StringName) -> void:
	if kind == &"unavailable":
		sound.play_ui(&"ui.invalid")


func _on_capture_cue(event: StringName, attacker: Node3D, victim: Node3D) -> void:
	if event == &"capture_started":
		sound.begin_cinematic(scope)
	if GLOBAL_EVENTS.has(event):
		sound.play_id(GLOBAL_EVENTS[event], victim.global_position, scope, &"cinematic")
	if attacker.character_definition != null:
		sound.play_profile(attacker.character_definition.audio_profile, event, attacker.global_position, scope, &"cinematic")
		if event == &"attacker_settled":
			sound.play_profile(attacker.character_definition.audio_profile, &"move_end", attacker.global_position, scope, &"cinematic")
	if event == &"debris":
		sound.play_id(&"capture.debris", victim.global_position, scope, &"cinematic")
		sound.play_id(&"capture.dust", victim.global_position, scope, &"cinematic")
	if event == &"core_destruction":
		sound.core_release(scope)
		if victim.character_definition != null:
			sound.play_profile(victim.character_definition.audio_profile, event, victim.global_position, scope, &"cinematic")


func _on_capture_end(_attacker: Node3D, victim: Node3D) -> void:
	var core: bool = victim.character_definition != null and victim.character_definition.is_core_objective
	sound.end_cinematic(scope, core)
	sound.play_id(&"capture.end", null, scope, &"transition")


func _on_cancelled() -> void:
	sound.end_cinematic(scope)


func _on_victory(_player: int) -> void:
	sound.end_cinematic(scope)
	sound.music.request_state(&"victory", scope)
	sound.play_ui(&"ui.victory")


func _on_destruction(effect: Node3D) -> void:
	effect.fragment_contact.connect(func(position: Vector3, _strength: float) -> void:
		sound.play_id(&"destruction.contact", position, scope, &"destruction"))


func _bind_controls(root: Node) -> void:
	for button in root.find_children("*", "BaseButton", true, false):
		button.mouse_entered.connect(func() -> void: sound.play_ui(&"ui.hover"))
		button.pressed.connect(func() -> void: sound.play_ui(&"ui.confirm"))


func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.release_scope(scope)
