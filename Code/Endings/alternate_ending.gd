extends Node2D

@onready var sprite1 = $Sprite2D
@onready var sprite2 = $Sprite2D2
@onready var sprite3 = $Sprite2D3

var speed = 2.0

var ready_for_exit = false

func _ready() -> void:
	sprite1.modulate.a = 0.0
	sprite2.modulate.a = 0.0
	sprite3.modulate.a = 0.0
	
	await yield_fade(sprite1, true)
	await get_tree().create_timer(speed).timeout
	await yield_fade(sprite1, false)
	
	await yield_fade(sprite2, true)
	await get_tree().create_timer(speed).timeout
	await yield_fade(sprite2, false)
	
	await yield_fade(sprite3, true)
	await get_tree().create_timer(speed).timeout
	await yield_fade(sprite3, false)
	
	await get_tree().create_timer(speed).timeout
	
	ready_for_exit = true
	
func _input(event: InputEvent) -> void:
	if ready_for_exit and event is InputEventKey and event.is_pressed() and not event.is_echo():
		get_tree().quit()

func yield_fade(sprite: Sprite2D, fade_in := true) -> void:
	var tween = create_tween()
	var target_alpha = 1.0 if fade_in else 0.0
	tween.tween_property(sprite, "modulate:a", target_alpha, 1.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
