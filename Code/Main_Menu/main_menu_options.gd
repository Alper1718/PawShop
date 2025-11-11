extends Control

signal back_pressed

const MENU_SCENES = {
	"audio": preload("res://Scenes/Main_Menu/main_menu_audio.tscn"),
	"display": preload("res://Scenes/Main_Menu/main_menu_display.tscn"),
	"controls": preload("res://Scenes/Main_Menu/main_menu_controls.tscn")
}

var current_submenu_name: String = ""
var current_submenu_instance: Node = null
var is_transitioning: bool = false

func fade_out_container(container: Control, duration: float = 0.5) -> void:
	container.visible = true
	container.modulate.a = 1.0
	var tween = container.create_tween()
	tween.tween_property(container, "modulate:a", 0.0, duration)
	await tween.finished #And Java still doesn't have async.
	container.visible = false

func fade_in_container(container: Control, duration: float = 0.5) -> void:
	container.visible = true
	container.modulate.a = 0.0
	var tween = container.create_tween()
	tween.tween_property(container, "modulate:a", 1.0, duration)
	await tween.finished

func open_submenu(name: String, back_signal_name: String) -> void:
	if is_transitioning or current_submenu_instance != null:
		return
	is_transitioning = true

	current_submenu_name = name
	await fade_out_container($OptionsContainer)

	var scene: PackedScene = MENU_SCENES.get(name, null)
	if not scene:
		push_error("Submenu '%s' not found in MENU_SCENES!" % name)
		is_transitioning = false
		return

	current_submenu_instance = scene.instantiate()
	add_child(current_submenu_instance)

	current_submenu_instance.visible = true
	current_submenu_instance.modulate.a = 0.0
	var tween = current_submenu_instance.create_tween()
	tween.tween_property(current_submenu_instance, "modulate:a", 1.0, 0.5)
	await tween.finished

	if not current_submenu_instance.is_connected(back_signal_name, Callable(self, "_on_submenu_back")):
		current_submenu_instance.connect(back_signal_name, Callable(self, "_on_submenu_back"))

	is_transitioning = false

func _on_submenu_back() -> void:
	if is_transitioning or current_submenu_instance == null:
		return
	is_transitioning = true

	var tween = current_submenu_instance.create_tween()
	tween.tween_property(current_submenu_instance, "modulate:a", 0.0, 0.5)
	await tween.finished

	current_submenu_instance.queue_free()
	current_submenu_instance = null
	current_submenu_name = ""

	await fade_in_container($OptionsContainer)
	is_transitioning = false

func _on_back_pressed() -> void:
	emit_signal("back_pressed")

func _on_audio_pressed() -> void:
	open_submenu("audio", "audio_back_pressed")

func _on_display_pressed() -> void:
	open_submenu("display", "display_back_pressed")

func _on_controls_pressed() -> void:
	open_submenu("controls", "controls_back_pressed")
