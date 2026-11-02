extends Node
## Cinematic pose interpolation and non-accumulating local shake.

const CINEMATIC_FOV: float = 46.0
const MIN_CINEMATIC_HEIGHT: float = 3.0
var fallback_count: int = 0
var base_pose: Transform3D
var playback_speed: float = 1.0
var _saved: Dictionary = {}
var _shake_age: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0
var _last_tick_usec: int = 0

@onready var camera: Camera3D = $"../Camera3D"


func _ready() -> void:
	set_process(false)


func save_strategic_state() -> void:
	_saved = {
		"transform": camera.global_transform, "fov": camera.fov,
		"near": camera.near, "far": camera.far, "size": camera.size,
		"projection": camera.projection, "keep_aspect": camera.keep_aspect,
		"h_offset": camera.h_offset, "v_offset": camera.v_offset,
		"current": camera.current,
	}
	base_pose = camera.global_transform
	_last_tick_usec = Time.get_ticks_usec()
	_shake_duration = 0.0
	set_process(true)


func strategic_pose() -> Transform3D:
	return _saved.get("transform", camera.global_transform)


func strategic_fov() -> float:
	return _saved.get("fov", camera.fov)


func calculate_pose(attacker: Vector3, victim: Vector3, bounds: AABB, behavior: Resource, seed_value: int, actors: Array[Node3D] = []) -> Transform3D:
	var direction := (victim - attacker) * Vector3(1, 0, 1)
	direction = direction.normalized() if direction.length_squared() > 0.001 else Vector3.FORWARD
	var side := direction.cross(Vector3.UP)
	var center := (attacker + victim) * 0.5
	center.y = bounds.get_center().y
	if side.dot(strategic_pose().origin - center) < 0.0:
		side = -side
	var variation := float(posmod(seed_value, 3) - 1)
	var view: Vector3 = (side * behavior.camera_side_bias - direction * 0.32).normalized()
	view = view.rotated(Vector3.UP, variation * 0.065)
	var opposite: Vector3 = (-side * behavior.camera_side_bias - direction * 0.32).normalized().rotated(Vector3.UP, variation * 0.065)
	var distance: float = behavior.camera_distance + variation * 0.12
	var height: float = behavior.camera_height + variation * 0.08
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var pose := Transform3D.IDENTITY
	var best_fitted := strategic_pose()
	# Fit the complete statues, not just their roots; includes motion clearance.
	for attempt in range(12):
		var fitted := false
		for angle in [view, opposite]:
			pose.origin = center + angle * distance + Vector3.UP * height
			pose.origin.y = maxf(pose.origin.y, MIN_CINEMATIC_HEIGHT)
			pose = pose.looking_at(center, Vector3.UP)
			if _fits(bounds.grow(0.35), pose, aspect):
				fitted = true
				best_fitted = pose
				if _actors_visible(pose.origin, actors):
					return pose
		if fitted:
			height += 0.65
		else:
			distance *= 1.10
			height *= 1.04
	# Keep a proven fit if crowding exhausts the closer views. Never return an
	# unfitted final trial merely because it was the last camera position tested.
	fallback_count += 1
	var strategic := strategic_pose()
	if _fits(bounds.grow(0.35), strategic, aspect) and _actors_visible(strategic.origin, actors):
		return strategic
	return best_fitted


func _actors_visible(origin: Vector3, actors: Array[Node3D]) -> bool:
	for actor in actors:
		var query := PhysicsRayQueryParameters3D.create(origin, actor.get_pick_point(), 2)
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider: CollisionObject3D = hit.collider
			if not collider.has_meta("piece") or collider.get_meta("piece") != actor:
				return false
	return true


func append_move(timeline: Tween, from: Transform3D, to: Transform3D, from_fov: float, to_fov: float, duration: float) -> void:
	timeline.tween_method(_blend.bind(from, to, from_fov, to_fov), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func shake(intensity: float, duration: float) -> void:
	_last_tick_usec = Time.get_ticks_usec()
	_shake_age = 0.0
	_shake_duration = maxf(duration, 0.001)
	_shake_intensity = clampf(intensity, 0.0, 0.12)


func restore_strategic_state() -> void:
	_shake_duration = 0.0
	_shake_intensity = 0.0
	playback_speed = 1.0
	if not _saved.is_empty() and is_instance_valid(camera):
		camera.global_transform = _saved.transform
		camera.fov = _saved.fov
		camera.near = _saved.near
		camera.far = _saved.far
		camera.size = _saved.size
		camera.projection = _saved.projection
		camera.keep_aspect = _saved.keep_aspect
		camera.h_offset = _saved.h_offset
		camera.v_offset = _saved.v_offset
		camera.current = _saved.current
		base_pose = _saved.transform
	_saved.clear()
	set_process(false)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	_shake_age += float(now - _last_tick_usec) / 1000000.0 * playback_speed
	_last_tick_usec = now
	_apply_pose()


func _blend(weight: float, from: Transform3D, to: Transform3D, from_fov: float, to_fov: float) -> void:
	base_pose = from.interpolate_with(to, weight)
	camera.fov = lerpf(from_fov, to_fov, weight)
	_apply_pose()


func _apply_pose() -> void:
	var pose := base_pose
	if _shake_age < _shake_duration:
		var strength := _shake_intensity * pow(1.0 - _shake_age / _shake_duration, 2.0)
		pose.origin += pose.basis.x * sin(_shake_age * 91.0) * strength
		pose.origin += pose.basis.y * sin(_shake_age * 67.0) * strength * 0.55
	pose.origin.y = maxf(pose.origin.y, MIN_CINEMATIC_HEIGHT)
	camera.global_transform = pose


func _fits(bounds: AABB, pose: Transform3D, aspect: float) -> bool:
	var tangent := tan(deg_to_rad(CINEMATIC_FOV * 0.5)) * 0.78
	var inverse := pose.affine_inverse()
	for index in range(8):
		var point := inverse * bounds.get_endpoint(index)
		if point.z >= -0.3 or absf(point.y) > -point.z * tangent or absf(point.x) > -point.z * tangent * aspect:
			return false
	return true
