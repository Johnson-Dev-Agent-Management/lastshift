extends SceneTree
## Render-only evidence at exact output resolutions; requires a graphical display.
## Run with the pinned editor: --path game --script res://tests/capture.gd
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var output := ProjectSettings.globalize_path("res://../builds/screenshots")
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
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("map-%dx%d.png" % [dimensions.x, dimensions.y]))
		ship.map_open = false
		ship.player.position = Vector2(340, 400)
		ship.state.salvage()
		ship.state.advance(6, true, true, false, 6)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("repaired-%dx%d.png" % [dimensions.x, dimensions.y]))
		viewport.queue_free()
		await process_frame
	print("LAST_SHIFT_CAPTURE_PASS: rendered map and repaired state at 1280x720 and 1920x1080")
	quit()
