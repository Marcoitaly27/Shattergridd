extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(c.attacker_visual, "rotation:z", 0.08, 0.22).set_trans(Tween.TRANS_SINE)
	t.tween_callback(c.cue.bind(&"wither"))
	t.tween_callback(c.mark_cracks)
	for offset in [0.024, -0.024, 0.018, -0.018]:
		t.tween_property(c.victim_visual, "position:x", offset, 0.05)
	t.tween_callback(c.impact.bind(0.0))
	c.append_hold(t, 0.07)
	t.tween_property(c.victim_visual, "scale", Vector3(0.86, 0.92, 0.86), 0.20).set_trans(Tween.TRANS_SINE)
	t.tween_callback(c.shatter.bind(true))
	t.tween_interval(0.12)
