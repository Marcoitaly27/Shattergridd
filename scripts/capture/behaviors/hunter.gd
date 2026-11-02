extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(c.attacker_visual, "position:y", -0.06, 0.12)
	t.tween_callback(c.cue.bind(&"weapon_swing"))
	t.tween_property(c.attacker, "global_position", c.destination + c.direction * 0.15 + c.side * 0.16, 0.17).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Precision first, then a deliberate silent beat before the fracture.
	t.tween_callback(c.cue.bind(&"strike_passed"))
	c.append_hold(t, 0.14)
	t.tween_callback(c.impact.bind(0.018))
	t.tween_property(c.victim_visual, "rotation:z", -0.09, 0.09)
	t.tween_callback(c.shatter.bind(false))
	t.tween_interval(0.12)
