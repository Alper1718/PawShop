extends Node2D

@onready var toys := [$Toys/Toys1, $Toys/Toys2, $Toys/Toys3]
var original_scales := {}

func _ready():
	for toy in toys:
		original_scales[toy] = toy.scale

func _process(delta: float) -> void:
	pass


func _on_toys_button_pressed() -> void:
	$"/root/MusicPlayer".play_toy_noise()

	for toy in toys:
		toy.scale = original_scales[toy]

		for tween in toy.get_children():
			if tween is Tween:
				tween.kill()
				tween.queue_free()

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var squish_scale = original_scales[toy] * Vector2(1.1, 0.8)
		tween.tween_property(toy, "scale", squish_scale, 0.06)
		tween.tween_property(toy, "scale", original_scales[toy], 0.08)
