extends Camera2D

var mode: bool = true

func _input(event: InputEvent) -> void:
	if mode:
		if event.is_action("mos_down"):
			if zoom.x > 0.002 and zoom.y > 0.002:
				zoom /= 1.1
		elif event.is_action("mos_up"):
			if zoom.x < 3 and zoom.y < 3:
				zoom *= 1.1
