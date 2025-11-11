extends Control

signal controls_back_pressed

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	emit_signal("controls_back_pressed")
