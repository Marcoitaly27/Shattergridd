extends SceneTree
## Optional reproducible idle sample. Run with --script; not part of normal play.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	for frame in range(4):
		await process_frame
	var game: Node = scene.get_node("GameManager")
	var interaction: Node = scene.get_node("Interaction")
	var calculations: int = game._movement.calculation_count
	var rays: int = interaction.ray_query_count
	var started := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - started < 3000:
		await process_frame
		frames += 1
	var scripts_processing := 0
	var scripts_physics := 0
	for node in scene.find_children("*", "", true, false):
		if node.get_script() != null:
			scripts_processing += int(node.is_processing())
			scripts_physics += int(node.is_physics_processing())
	var report := {
		"display": DisplayServer.get_name(),
		"render_device": RenderingServer.get_video_adapter_name(),
		"window": str(root.size),
		"sample_seconds": float(Time.get_ticks_msec() - started) / 1000.0,
		"rendered_fps": float(frames) * 1000.0 / (Time.get_ticks_msec() - started) if DisplayServer.get_name() != "headless" else null,
		"nodes": scene.find_children("*", "", true, false).size(),
		"script_process_nodes": scripts_processing,
		"script_physics_nodes": scripts_physics,
		"physics_bodies": scene.find_children("*", "PhysicsBody3D", true, false).size(),
		"lights": scene.find_children("*", "Light3D", true, false).size(),
		"effects": scene.get_node("Effects").get_child_count(),
		"idle_legal_calculations": game._movement.calculation_count - calculations,
		"idle_pick_rays": interaction.ray_query_count - rays,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	}
	var sound := root.get_node_or_null("SoundManager")
	if sound != null:
		report["audio"] = sound.metrics()
	print("SHATTERGRID idle baseline: " + JSON.stringify(report))
	scene.queue_free()
	await process_frame
	quit()
