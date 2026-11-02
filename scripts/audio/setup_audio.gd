extends Node
## Army setup owns a music context, never the match's ambience loops.

var scope: int
@onready var sound: Node = get_node("/root/SoundManager")


func _ready() -> void:
	scope = get_parent().get_instance_id()
	sound.begin_scope(scope, &"army_setup")
	for button in get_parent().find_children("*", "BaseButton", true, false):
		button.mouse_entered.connect(func() -> void: sound.play_ui(&"ui.hover"))
		button.focus_entered.connect(func() -> void: sound.play_ui(&"ui.hover"))


func _exit_tree() -> void:
	if is_instance_valid(sound):
		sound.release_scope(scope)
