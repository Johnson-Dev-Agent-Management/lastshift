extends Node2D
const ICON = preload("res://assets/icon.svg")
var frames := 0
func _ready() -> void:
	var label := Label.new()
	label.text = "LAST SHIFT\nM0 foundation ready"
	label.position = Vector2(80, 80)
	add_child(label)
func _process(_delta: float) -> void:
	frames += 1
	if frames == 3 and "--smoke-test" in OS.get_cmdline_user_args():
		assert(ICON.get_width() == 128)
		print("LAST_SHIFT_STARTUP_PASS")
