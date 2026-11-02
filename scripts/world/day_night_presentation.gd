extends Node
## Observes the turn clock. Lighting never owns gameplay timing.
var _transition: Tween
@onready var game: Node = $"../GameManager"
@onready var key: DirectionalLight3D = $"../Moonlight"
@onready var fill: DirectionalLight3D = $"../DuskFill"

func _ready() -> void:
	game.cycle_changed.connect(_on_cycle)
	_apply(game.is_night, false)

func _on_cycle(night: bool, _rounds_remaining: int) -> void:
	_apply(night, true)

func _apply(night: bool, animate: bool) -> void:
	var energy := 0.70 if night else 1.20
	var color := Color(0.58, 0.69, 0.86) if night else Color(0.80, 0.86, 0.90)
	if is_instance_valid(_transition):
		_transition.kill()
	if not animate:
		key.light_energy = energy
		key.light_color = color
		fill.light_energy = 0.18 if night else 0.24
		return
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(key, "light_energy", energy, 0.7)
	_transition.tween_property(key, "light_color", color, 0.7)
	_transition.tween_property(fill, "light_energy", 0.18 if night else 0.24, 0.7)
