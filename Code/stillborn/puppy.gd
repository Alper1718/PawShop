extends Sprite2D

var dragging := false

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_rect().has_point(to_local(event.position)):
			dragging = true
		elif not event.pressed:
			dragging = false

	if dragging and event is InputEventMouseMotion:
		global_position = event.position
