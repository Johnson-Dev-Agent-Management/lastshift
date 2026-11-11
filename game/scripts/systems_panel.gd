extends PanelContainer
## Local equipment controls. The simulation validates every command.
signal closed
var ship: Node2D
var mode := "power"
var heading := Label.new()
var summary := Label.new()
var detail := Label.new()
var response := Label.new()
var buttons: Dictionary = {}
var reserve_button := Button.new()
var close_button := Button.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -370
	offset_right = 370
	offset_top = -166
	offset_bottom = 190
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182d39")
	style.border_color = Color("efbb70")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	heading.add_theme_font_size_override("font_size", 24)
	box.add_child(heading)
	for label in [summary, detail, response]:
		label.add_theme_font_size_override("font_size", 17)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.custom_minimum_size.y = 48
		response.custom_minimum_size.y = 44
		box.add_child(label)
	for consumer in ["life_support", "cooling", "drive"]:
		var button := Button.new()
		button.pressed.connect(func(): change_power(consumer))
		buttons[consumer] = button
		box.add_child(button)
	reserve_button.pressed.connect(use_reserve)
	box.add_child(reserve_button)
	close_button.text = "Close panel (Esc)"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	hide()

func open(which: String) -> void:
	mode = which
	response.text = ""
	show()
	refresh()
	close_button.grab_focus()

func close() -> void:
	hide()
	get_viewport().gui_release_focus()
	closed.emit()

func change_power(consumer: String) -> void:
	if not ship.can_operate("power"): return
	var enabled: bool = not ship.state.get(consumer + "_powered")
	response.text = ship.state.set_power(consumer, enabled)
	if response.text.is_empty():
		response.text = "Allocation updated. Other consumers are unchanged."
		ship.feedback.confirm()
	refresh()

func use_reserve() -> void:
	if not ship.can_operate("reserve"): return
	response.text = ship.state.use_reserve()
	if response.text.is_empty():
		response.text = ship.message
		ship.feedback.confirm(true)
	refresh()

func refresh() -> void:
	if not visible: return
	var state = ship.state
	var profile = ship.profile
	var power_mode := mode == "power"
	heading.text = "ENGINEERING / POWER" if power_mode else "LIFE SUPPORT / EMERGENCY AIR"
	summary.text = "POWER %d / %d   ·   AIR %.1f   ·   HEAT %.1f   ·   CHARGE %.1f%%" % [state.used_power(), profile.capacity, state.air, state.heat, state.charge]
	detail.text = "Time is running. Close this panel, then Esc to pause.\nDrive: " + state.drive_status() if power_mode else "Time is running. One use only; the preview updates to the actual available gain."
	for consumer: String in buttons:
		var button: Button = buttons[consumer]
		button.visible = power_mode
		button.disabled = not state.command_blocked().is_empty()
		var active: bool = state.get(consumer + "_powered")
		var demand: int = profile.get(consumer + "_demand")
		var effect := "slows air loss" if consumer == "life_support" else ("removes heat when repaired" if consumer == "cooling" else "charges the armed, repaired drive")
		button.text = "%s %s · %d units · %s" % ["Turn OFF" if active else "Turn ON", consumer.replace("_", " ").capitalize(), demand, effect]
	reserve_button.visible = not power_mode
	reserve_button.disabled = state.reserve_used or state.reserve_gain() <= 0 or not state.command_blocked().is_empty()
	reserve_button.text = "Reserve EMPTY" if state.reserve_used else "Release reserve: +%.2f air (one use)" % state.reserve_gain()
