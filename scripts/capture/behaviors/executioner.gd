extends "res://scripts/capture/capture_behavior.gd"


func append(t: Tween, c: RefCounted) -> void:
	var axe: Node3D = c.find_part("AxeRig")
	if axe == null:
		axe = c.attacker_visual
	t.tween_property(c.attacker, "global_position", c.contact, 0.16).set_trans(Tween.TRANS_SINE)
	t.tween_callback(c.cue.bind(&"anticipation"))
	t.tween_property(axe, "rotation:x", 0.70, 0.22).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(axe, "position:y", axe.position.y + 0.20, 0.22)
	t.parallel().tween_property(c.attacker_visual, "position:y", 0.06, 0.22)
	t.tween_callback(c.cue.bind(&"weapon_swing"))
	t.tween_property(axe, "rotation:x", -0.85, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(axe, "position:y", axe.position.y, 0.20)
	t.tween_callback(c.impact.bind(0.10, 0.20))
	c.append_hold(t, 0.10)
	t.tween_property(c.victim_visual, "rotation:z", 0.19, 0.10)
	t.parallel().tween_property(c.victim_visual, "position", c.direction * 0.12, 0.10)
	t.tween_callback(c.shatter.bind(false))
	t.tween_interval(0.14)
