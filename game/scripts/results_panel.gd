extends PanelContainer
var ship: Node2D
var heading := Label.new()
var detail := Label.new()
var stats := Label.new()
var retry := Button.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -360
	offset_right = 360
	offset_top = -204
	offset_bottom = 204
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182d39")
	style.border_color = Color("7cdac0")
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	heading.add_theme_font_size_override("font_size", 28)
	box.add_child(heading)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.y = 58
	detail.add_theme_font_size_override("font_size", 18)
	box.add_child(detail)
	stats.add_theme_font_size_override("font_size", 16)
	box.add_child(stats)
	retry.text = "Retry — start at the emergency"
	retry.pressed.connect(func(): ship.reset_run())
	box.add_child(retry)
	var opening := Button.new()
	opening.text = "Replay the opening and full shift"
	opening.pressed.connect(func(): ship.reset_run(true))
	box.add_child(opening)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	hide()

func open() -> void:
	var state = ship.state
	heading.text = "SHIFT COMPLETE" if state.escaped else "SHIFT ENDED — " + state.failure
	detail.text = state.recovery_advice()
	stats.text = "ACTIVE PLAY  %.1fs   ·   EMERGENCY  %.1fs\nAIR  %.1f   ·   HEAT  %.1f   ·   CHARGE  %.1f%%\nPUMP  %s   ·   HULL  %s   ·   RESERVE  %s\nPROFILE  %s" % [state.opening_seconds + state.active_seconds, state.active_seconds, state.air, state.heat, state.charge, "REPAIRED" if state.repaired else "BROKEN", "SEALED" if state.leak_patched else ("LEAKING" if state.leak_active else "INTACT"), "USED" if state.reserve_used else "AVAILABLE", ship.profile.profile_id]
	show()
	retry.grab_focus()
