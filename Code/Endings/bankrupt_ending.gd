extends Node2D

@onready var sprite := $Sprite2D
const speed = 2.0
var ready_for_exit = false

func _ready() -> void:
	sprite.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	await get_tree().create_timer(speed).timeout
	
	ready_for_exit = true
	
func _input(event: InputEvent) -> void:
	if ready_for_exit and event is InputEventKey and event.is_pressed() and not event.is_echo():
		get_tree().quit()
