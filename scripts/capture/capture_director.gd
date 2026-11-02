extends Node
## One explicitly completed timeline owns the complete presentation lock interval.

signal cue_emitted(event: StringName, attacker: Node3D, victim: Node3D)
signal victim_shattered(attacker: Node3D, victim: Node3D)
signal completed(attacker: Node3D, victim: Node3D)
signal cancelled
signal destruction_spawned(effect: Node3D)

const CaptureContext = preload("res://scripts/capture/capture_context.gd")
const FALLBACK_BEHAVIOR: Resource = preload("res://resources/captures/warden.tres")
var active: bool = false
var playback_speed: float = 1.0
var _timeline: Tween
var _context: RefCounted
var _capture_serial: int = 0
var _last_tick_usec: int = 0
var _hold_until_usec: int = 0
var _hold_advance_seconds: float = 0.0

@onready var camera_director: Node = $"../CameraDirector"
@onready var effects: Node3D = $"../Effects"


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	if not active or _timeline == null:
		return
	# Godot may cap frame delta on slow renderers. A single monotonic presentation
	# clock keeps the short cinematic from stretching, without global time_scale.
	var now := Time.get_ticks_usec()
	var elapsed := float(now - _last_tick_usec) / 1000000.0
	_last_tick_usec = now
	if _hold_until_usec > 0:
		if now < _hold_until_usec:
			return
		elapsed = maxf(elapsed, _hold_advance_seconds)
		_hold_until_usec = 0
		_hold_advance_seconds = 0.0
	# Stop at a deliberate presentation hold before a large slow-frame delta
	# can consume the silence/hit pause and the following impact in one draw.
	while elapsed > 0.000001 and active and _timeline != null:
		var slice := minf(elapsed, 0.01)
		_timeline.custom_step(slice)
		elapsed -= slice
		if _hold_until_usec > 0:
			break


func hold(duration: float) -> void:
	_hold_advance_seconds = duration / playback_speed
	_hold_until_usec = Time.get_ticks_usec() + int(_hold_advance_seconds * 1000000.0)


func start(attacker: Node3D, victim: Node3D) -> bool:
	if active or not is_instance_valid(attacker) or not is_instance_valid(victim):
		return false
	var game := get_node_or_null("../GameManager")
	if game != null and (game.phase != game.Phase.CAPTURING or attacker.army != game.current_player \
			or attacker.army == victim.army):
		return false
	active = true
	_capture_serial += 1
	var behavior: Resource = attacker.get_capture_behavior()
	if behavior == null or not behavior.has_method("append"):
		behavior = FALLBACK_BEHAVIOR
	_context = CaptureContext.new()
	_context.setup(self, attacker, victim, int(victim.grid_coordinate.x * 83 + victim.grid_coordinate.y * 31 + _capture_serial))
	camera_director.save_strategic_state()
	var bounds: AABB = attacker.get_visual_bounds().merge(victim.get_visual_bounds())
	var actors: Array[Node3D] = [attacker, victim]
	var pose: Transform3D = camera_director.calculate_pose(_context.start, _context.destination, bounds, behavior, _context.seed_value, actors)
	_timeline = create_tween()
	_timeline.set_speed_scale(playback_speed)
	_timeline.tween_callback(_context.cue.bind(&"capture_started"))
	camera_director.append_move(_timeline, camera_director.strategic_pose(), pose, camera_director.strategic_fov(), camera_director.CINEMATIC_FOV, 0.32)
	_timeline.tween_callback(_context.cue.bind(&"camera_ready"))
	behavior.append(_timeline, _context)
	if _context.victim_is_core:
		_timeline.tween_interval(0.18)
	_timeline.tween_callback(_context.cue.bind(&"settling"))
	_context.append_settle(_timeline, 0.28)
	_timeline.tween_callback(_context.cue.bind(&"attacker_settled"))
	_timeline.tween_interval(0.12)
	_timeline.tween_callback(_context.cue.bind(&"camera_return"))
	camera_director.append_move(_timeline, pose, camera_director.strategic_pose(), camera_director.CINEMATIC_FOV, camera_director.strategic_fov(), 0.34)
	_timeline.tween_callback(_finish)
	_timeline.pause()
	_last_tick_usec = Time.get_ticks_usec()
	set_process(true)
	return true


func accelerate() -> void:
	# Fast-forward every event; never bypass impact, board resolution or cleanup.
	if not active:
		return
	var previous_speed := playback_speed
	playback_speed = 8.0
	if _hold_until_usec > 0:
		var now := Time.get_ticks_usec()
		_hold_until_usec = now + int(maxi(_hold_until_usec - now, 0) * previous_speed / playback_speed)
		_hold_advance_seconds *= previous_speed / playback_speed
	_timeline.set_speed_scale(playback_speed)
	camera_director.playback_speed = playback_speed


func abort() -> void:
	var was_active := active
	if is_instance_valid(_timeline):
		_timeline.kill()
	_timeline = null
	if _context != null:
		_context.abort()
	_context = null
	active = false
	_hold_until_usec = 0
	_hold_advance_seconds = 0.0
	set_process(false)
	playback_speed = 1.0
	if is_instance_valid(camera_director):
		camera_director.restore_strategic_state()
	if was_active:
		cancelled.emit()


func _finish() -> void:
	if not active or _context == null:
		return
	var context: RefCounted = _context
	var attacker: Node3D = context.attacker
	var victim: Node3D = context.victim
	camera_director.restore_strategic_state()
	context.cue(&"camera_restored")
	if not active or _context != context:
		return
	context.restore_visuals()
	_context = null
	_timeline = null
	active = false
	_hold_until_usec = 0
	_hold_advance_seconds = 0.0
	set_process(false)
	playback_speed = 1.0
	completed.emit(attacker, victim)


func _exit_tree() -> void:
	abort()
