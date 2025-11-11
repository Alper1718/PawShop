extends Control
signal audio_back_pressed

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	emit_signal("audio_back_pressed")
