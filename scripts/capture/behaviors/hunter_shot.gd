extends "res://scripts/capture/capture_behavior.gd"
func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_interval(0.20)
	t.tween_callback(c.cue.bind(&"weapon_swing"))
	c.append_arrow(t)
	t.tween_callback(c.impact.bind(0.025))
	t.tween_callback(c.shatter.bind(false))
	t.tween_interval(0.14)
