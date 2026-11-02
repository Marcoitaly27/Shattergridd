extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(c.attacker_visual, "scale:y", 0.76, 0.12)
	t.tween_callback(c.cue.bind(&"predatory_lunge"))
	t.tween_property(c.attacker, "global_position", c.contact, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(c.impact.bind(0.055))
	t.tween_callback(c.cue.bind(&"wyrm_impact"))
	c.append_hold(t, 0.06)
	t.tween_property(c.attacker_visual, "rotation:z", 0.16, 0.09)
	t.tween_property(c.attacker_visual, "rotation:z", -0.12, 0.08)
	t.parallel().tween_property(c.victim_visual, "position", c.direction * 0.16, 0.08)
	t.tween_callback(c.shatter.bind(false))
	t.tween_interval(0.12)
