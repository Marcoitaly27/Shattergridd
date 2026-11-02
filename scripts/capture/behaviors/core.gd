extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(c.attacker_visual, "scale", Vector3(1.035, 1.0, 1.035), 0.22).set_trans(Tween.TRANS_SINE)
	t.tween_callback(c.cue.bind(&"core_force"))
	t.tween_property(c.victim_visual, "position", c.direction * 0.18, 0.16)
	t.tween_callback(c.impact.bind(0.008))
	c.append_hold(t, 0.07)
	t.tween_property(c.victim_visual, "scale", Vector3(0.80, 0.94, 0.80), 0.22)
	t.tween_callback(c.shatter.bind(true))
	t.tween_interval(0.14)
