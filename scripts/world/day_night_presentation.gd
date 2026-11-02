extends Node
## Observe the turn clock; lighting/fog never own gameplay timing.
var _transition: Tween
var _night: bool = false
@onready var game: Node = $"../GameManager"
@onready var key: DirectionalLight3D = $"../Moonlight"
@onready var fill: DirectionalLight3D = $"../DuskFill"
@onready var world_environment: WorldEnvironment = $"../WorldEnvironment"
var environment: Environment

func _ready() -> void:
	# Each match owns its atmospheric state; lab/rematch never recolour a shared Resource.
	environment = world_environment.environment.duplicate()
	world_environment.environment = environment
	game.cycle_changed.connect(_on_cycle)
	_apply(game.is_night, false)

func _on_cycle(night: bool, _rounds_remaining: int) -> void:
	if night != _night:
		_apply(night, true)

func _apply(night: bool, animate: bool) -> void:
	_night = night
	if is_instance_valid(_transition):
		_transition.kill()
	var values: Array = [
		[key, "light_energy", 0.95 if night else 1.65],
		[key, "light_color", Color(0.64, 0.74, 0.91) if night else Color(0.93, 0.90, 0.82)],
		[fill, "light_energy", 0.38 if night else 0.32],
		[environment, "background_energy_multiplier", 0.45 if night else 1.0],
		[environment, "ambient_light_energy", 0.28 if night else 0.34],
		[environment, "ambient_light_color", Color(0.48, 0.58, 0.73) if night else Color(0.66, 0.71, 0.76)],
		[environment, "fog_light_color", Color(0.11, 0.155, 0.21) if night else Color(0.21, 0.25, 0.27)],
	]
	if animate:
		_transition = create_tween().set_parallel(true)
	for entry in values:
		if animate:
			_transition.tween_property(entry[0], entry[1], entry[2], 1.1).set_trans(Tween.TRANS_SINE)
		else:
			entry[0].set(entry[1], entry[2])

func _exit_tree() -> void:
	if is_instance_valid(_transition):
		_transition.kill()
