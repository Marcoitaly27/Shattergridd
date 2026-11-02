extends "res://scripts/capture/capture_behavior.gd"
## Same camera/action contract, with timing supplied by the model's method tracks.


func append(timeline: Tween, context: RefCounted) -> void:
	var duration: float = context.attacker_visual.capture_duration()
	timeline.tween_callback(context.begin_authored_capture)
	timeline.tween_method(context.advance_authored_capture, 0.0, duration, duration)
	timeline.tween_callback(context.finish_authored_capture)
