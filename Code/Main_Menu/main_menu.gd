extends Control

@onready var menu_buttons = $MenuButtons
var options_scene: PackedScene = preload("res://Scenes/Main_Menu/main_menu_options.tscn")
var options_instance: Node
var is_options_open :bool = false

func _ready():
	GameManager.time_paused = true
	var display_settings = GameManager._load_display_settings()
	if display_settings["fullscreen"] == true:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
		GameManager.fullscreen = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
		GameManager.fullscreen = false
	MusicPlayer.play_music()
	DisplayServer.window_set_size(display_settings["resolution"])

func _process(delta: float) -> void:
	pass


func _on_start_game_pressed() -> void:
	GameManager.time_paused = false

	get_tree().change_scene_to_file("res://Scenes/the_shop.tscn")


func _on_options_pressed() -> void:
	if is_options_open: return
	is_options_open = true
	
	menu_buttons.modulate.a = 1.0
	menu_buttons.create_tween().tween_property(menu_buttons, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout
	menu_buttons.visible = false
	options_instance = options_scene.instantiate()
	add_child(options_instance)
	
	options_instance.visible = true
	options_instance.modulate.a = 0.0
	options_instance.create_tween().tween_property(options_instance, "modulate:a", 1.0, 0.5)
	if not options_instance.is_connected("back_pressed", Callable(self, "_on_back_from_options")):
		options_instance.connect("back_pressed", Callable(self, "_on_back_from_options"))


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_synema_pressed() -> void:
	print("Studio Synema")

func _on_back_from_options():
	if not is_options_open:
		return
	is_options_open = false
	var fade_out = options_instance.create_tween()
	fade_out.tween_property(options_instance, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout

	options_instance.queue_free()
	options_instance = null
	
	menu_buttons.visible = true
	menu_buttons.modulate.a = 0.0
	var fade_in = menu_buttons.create_tween()
	fade_in.tween_property(menu_buttons, "modulate:a", 1.0, 0.5)
