extends SceneTree
## Render evidence at exact resolutions; requires a graphical display.
var output := ""

func _initialize() -> void:
	run.call_deferred()

func capture(viewport: SubViewport, label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := output.path_join("%s-%dx%d.png" % [label, viewport.size.x, viewport.size.y])
	viewport.get_texture().get_image().save_png(path)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/screenshots-m3")
	DirAccess.make_dir_recursive_absolute(output)
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		viewport.size_2d_override = Vector2i(1280, 720)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var ship = load("res://scenes/ship.tscn").instantiate()
		viewport.add_child(ship)
		ship.map_open = true
		await capture(viewport, "opening-map")
		ship.map_open = false
		ship.player.position = ship.Layout.CONNECTOR + Vector2(0, 70)
		await capture(viewport, "opening-connector")
		ship.state.work_target = "connector"
		ship.state.advance(4, true, true, false, 6)
		ship.player.position = ship.Layout.POWER + Vector2(0, 80)
		ship.systems_panel.open("power")
		await capture(viewport, "opening-power")
		ship.state.set_power("cooling", false)
		ship.state.set_power("cooling", true)
		ship.state.advance(6, false, false, false, 6)
		await capture(viewport, "evacuation")
		ship.state.advance(2, false, false, false, 6)
		await capture(viewport, "emergency")
		ship.state.salvage()
		ship.state.work_target = "pump"
		ship.state.advance(6, true, true, false, 6)
		ship.state.arm_drive()
		ship.state.charge = 30
		ship.state.advance(40.1, false, false, false, 6)
		await capture(viewport, "leak-warning")
		ship.state.advance(6, false, false, false, 6)
		ship.player.position = ship.Layout.LEAK + Vector2(-70, 0)
		await capture(viewport, "leak-active")
		ship.state.work_target = "leak"
		ship.state.advance(3, true, true, false, 6)
		await capture(viewport, "leak-partial")
		ship.state.work_target = "leak"
		ship.state.advance(5, true, true, false, 6)
		await capture(viewport, "leak-sealed")
		ship.state.charge = 100
		ship.player.position = ship.Layout.BRIDGE
		await capture(viewport, "jump-ready")
		ship.interact()
		await capture(viewport, "shift-complete")
		ship.reset_run()
		ship.state.air = 0.00001
		await capture(viewport, "air-loss")
		ship.reset_run()
		ship.state.heat = 93
		ship.state.critical = true
		ship.state.critical_elapsed = ship.profile.critical_grace_seconds
		await capture(viewport, "heat-loss")
		viewport.queue_free()
		await process_frame
	print("LAST_SHIFT_CAPTURE_PASS: M3 opening, transition, leak, patch, bridge and results at 1280x720 and 1920x1080")
	quit()
