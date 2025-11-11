extends Control

signal display_back_pressed

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	emit_signal("display_back_pressed")

func _on_window_type_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
		$VBoxContainer/WindowTypeSwitch.text = "Fullscreen"
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
		$VBoxContainer/WindowTypeSwitch.text = "Windowed"



func _on_window_size_switch_toggled(toggled_on: bool) -> void:
	var target_resolution: Vector2 = Vector2.ZERO
	if toggled_on:
		target_resolution = Vector2(1280, 720)
		$VBoxContainer/WindowSizeSwitch.text = "1280*720"
	else:
		target_resolution = Vector2(1920, 1080)
		$VBoxContainer/WindowSizeSwitch.text = "1920*1080"
	DisplayServer.window_set_size(target_resolution)
