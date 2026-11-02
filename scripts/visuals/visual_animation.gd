@tool
extends RefCounted
## The visual owns AnimationPlayer/Tree details; a method-track relay owns impact.

var model: Node3D
var config: Resource
var player: AnimationPlayer
var tree: AnimationTree
var _handler: Callable
var _saved: Dictionary = {}
var _last_time: float = 0.0


func bind_model(next_model: Node3D, next_config: Resource) -> void:
	end_capture()
	if is_instance_valid(model) and model.has_signal("animation_event") and model.is_connected("animation_event", _on_event):
		model.disconnect("animation_event", _on_event)
	model = next_model
	config = next_config
	player = null
	tree = null
	if model == null or config == null:
		return
	if not config.player_path.is_empty():
		player = model.get_node_or_null(config.player_path) as AnimationPlayer
	else:
		var players := model.find_children("*", "AnimationPlayer", true, false)
		if not players.is_empty():
			player = players[0] as AnimationPlayer
	if not config.tree_path.is_empty():
		tree = model.get_node_or_null(config.tree_path) as AnimationTree
	if model.has_signal("animation_event"):
		model.connect("animation_event", _on_event)


func request_state(state: StringName) -> bool:
	if not _saved.is_empty() or model == null:
		return false
	if model.has_method("request_animation_state") and model.call("request_animation_state", state):
		return true
	if config == null or player == null:
		return false
	var clip := StringName(config.states.get(state, &""))
	if clip == &"" or not player.has_animation(clip) or not _safe_clip(player.get_animation(clip)):
		return false
	player.play(clip)
	return true


func capture_ready() -> bool:
	if config == null or player == null or model == null:
		return false
	var clip := StringName(config.states.get(&"capture_attack", &""))
	if clip == &"" or not player.has_animation(clip) or not model.has_signal("animation_event") or not model.has_method("report_animation_event"):
		return false
	var animation := player.get_animation(clip)
	return animation.length > 0 and animation.loop_mode == Animation.LOOP_NONE and _safe_clip(animation) and _has_impact(animation)


func _safe_clip(animation: Animation) -> bool:
	var origin := player.get_node_or_null(player.root_node)
	if origin == null:
		return false
	for index in range(animation.get_track_count()):
		var path: NodePath = NodePath(animation.track_get_path(index).get_concatenated_names())
		var target := origin.get_node_or_null(path)
		if target == null or (target != model and not model.is_ancestor_of(target)):
			return false
	return true


func _has_impact(animation: Animation) -> bool:
	var origin := player.get_node_or_null(player.root_node)
	for track in range(animation.get_track_count()):
		if animation.track_get_type(track) != Animation.TYPE_METHOD:
			continue
		var target := origin.get_node_or_null(NodePath(animation.track_get_path(track).get_concatenated_names()))
		if target != model:
			continue
		for key in range(animation.track_get_key_count(track)):
			var value: Dictionary = animation.track_get_key_value(track, key)
			var args: Array = value.get("args", [])
			if value.get("method") == &"report_animation_event" and not args.is_empty() and StringName(args[0]) == &"impact":
				return true
	return false


func capture_duration() -> float:
	return player.get_animation(config.states[&"capture_attack"]).length if capture_ready() else 0.0


func begin_capture(handler: Callable) -> bool:
	if not capture_ready():
		return false
	_saved = {"process": player.callback_mode_process, "method": player.callback_mode_method,
		"speed": player.speed_scale, "playing": player.is_playing(), "clip": player.current_animation,
		"position": player.current_animation_position if player.current_animation != "" else 0.0,
		"tree": tree.active if tree != null else false, "model_transform": model.transform}
	_handler = handler
	_last_time = 0.0
	if tree != null:
		tree.active = false
	player.stop()
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	player.speed_scale = 1.0
	player.play(config.states[&"capture_attack"])
	player.advance(0.0)
	return true


func advance_to(time: float) -> void:
	if not _saved.is_empty() and is_instance_valid(player):
		var delta := maxf(time - _last_time, 0.0)
		_last_time = time
		player.advance(delta)


func _on_event(event: StringName) -> void:
	if _handler.is_valid():
		_handler.call(event)


func end_capture() -> void:
	_handler = Callable()
	if _saved.is_empty():
		return
	if is_instance_valid(player):
		if player.has_animation(&"RESET"):
			player.play(&"RESET")
			player.advance(0.0)
		elif player.current_animation != "":
			player.seek(0.0, true)
		player.stop()
		player.callback_mode_process = _saved.process
		player.callback_mode_method = _saved.method
		player.speed_scale = _saved.speed
		if _saved.playing and player.has_animation(_saved.clip):
			player.play(_saved.clip)
			player.seek(_saved.position, true)
	if is_instance_valid(model):
		model.transform = _saved.model_transform
	if is_instance_valid(tree):
		tree.active = _saved.tree
	_saved.clear()


func warnings() -> Array[String]:
	var result: Array[String] = []
	if config == null:
		return result
	if not config.states.is_empty() and player == null:
		result.append("Configured animation source is missing")
		return result
	if not config.tree_path.is_empty() and tree == null:
		result.append("Configured AnimationTree is missing")
	for state in config.states:
		var clip := StringName(config.states[state])
		if clip != &"" and (not player.has_animation(clip) or not _safe_clip(player.get_animation(clip))):
			result.append("Missing/unsafe animation for %s" % state)
	if config.states.has(&"capture_attack") and not capture_ready():
		result.append("Capture clip needs a non-looping, wrapper-local impact event; procedural fallback is active")
	return result
