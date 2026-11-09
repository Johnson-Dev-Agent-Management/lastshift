extends CharacterBody2D
var speed := 180.0
var frozen := false
var carrying := false
var working := false
var facing := Vector2.DOWN
var motion_time := 0.0
# Tests drive the same CharacterBody2D physics as keyboard input.
var test_direction := Vector2.ZERO

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	add_child(collision)
	z_index = 10

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if test_direction != Vector2.ZERO:
		direction = test_direction.limit_length()
	velocity = Vector2.ZERO if frozen else direction * speed
	if velocity.length() > 1:
		facing = velocity.normalized()
		motion_time += delta * 12
	if working and not frozen:
		motion_time += delta * 4
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(2, 5), 16, Color(0, 0, 0, 0.35))
	var stride := sin(motion_time) * 3 if velocity.length() > 1 else 0.0
	draw_line(Vector2(-6, 5), Vector2(-6, 14 + stride), Color("263b48"), 6)
	draw_line(Vector2(6, 5), Vector2(6, 14 - stride), Color("263b48"), 6)
	draw_circle(Vector2.ZERO, 12, Color("efbb70"))
	draw_rect(Rect2(-9, -7, 18, 8), Color("dceee9"))
	draw_line(facing * 5, facing * 18, Color("152b37"), 4)
	if carrying:
		draw_rect(Rect2(-10, 14, 20, 13), Color("7cdac0"))
		draw_line(Vector2(-13, 19), Vector2(13, 19), Color("dceee9"), 3)
	if working:
		draw_arc(Vector2.ZERO, 24, motion_time, motion_time + 2.4, 18, Color("7cdac0"), 3)
