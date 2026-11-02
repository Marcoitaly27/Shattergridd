extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(c.attacker, "global_position", c.start - c.direction * 0.13, 0.22).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(c.attacker_visual, "rotation:x", -0.08, 0.22)
	t.tween_callback(c.cue.bind(&"weapon_swing"))
	t.tween_property(c.attacker, "global_position", c.contact, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(c.impact.bind(0.080))
	c.append_hold(t, 0.08)
	t.tween_property(c.victim_visual, "position", c.direction * 0.14, 0.11)
	t.parallel().tween_property(c.victim_visual, "rotation:z", 0.14, 0.11)
	t.tween_callback(c.shatter.bind(false))
	t.tween_interval(0.10)
