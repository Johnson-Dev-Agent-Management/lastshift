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
	output = ProjectSettings.globalize_path("res://../builds/screenshots-m2")
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
		await capture(viewport, "map")
		ship.map_open = false
		ship.player.position = ship.Layout.DRIVE_PANEL + Vector2(-75, 65)
		await capture(viewport, "drive-unarmed")
		ship.state.arm_drive()
		for frame in 20: await physics_frame
		await capture(viewport, "drive-pulled")
		for frame in 75: await physics_frame
		await capture(viewport, "drive-armed")
		ship.reset_run()
		ship.player.position = ship.Layout.POWER + Vector2(0, 80)
		ship.state.salvage()
		ship.state.advance(6, true, true, false, 6)
		ship.state.arm_drive()
		ship.systems_panel.open("power")
		ship.systems_panel.change_power("drive")
		await capture(viewport, "capacity-rejection")
		ship.systems_panel.change_power("life_support")
		ship.systems_panel.change_power("drive")
		ship.systems_panel.close()
		ship.state.advance(60, false, false, false, 6)
		await capture(viewport, "charging")
		ship.state.heat = 86
		ship.state.advance(ship.State.STEP, false, false, false, 6)
		await capture(viewport, "cooldown")
		ship.player.position = ship.Layout.RESERVE
		ship.state.air = 90
		ship.systems_panel.open("reserve")
		await capture(viewport, "reserve-preview")
		ship.systems_panel.close()
		ship.state.heat = 93
		ship.state.advance(ship.State.STEP, false, false, false, 6)
		await capture(viewport, "critical")
		ship.reset_run()
		ship.state.salvage()
		ship.state.advance(6, true, true, false, 6)
		ship.state.arm_drive()
		ship.state.set_power("life_support", false)
		ship.state.set_power("drive", true)
		ship.state.advance(100.0 / ship.profile.charge_rate + ship.State.STEP, false, false, false, 6)
		ship.player.position = ship.Layout.BRIDGE
		await capture(viewport, "escape-ready")
		viewport.queue_free()
		await process_frame
	print("LAST_SHIFT_CAPTURE_PASS: M2 map, local panels, resource HUD and thresholds at 1280x720 and 1920x1080")
	quit()
