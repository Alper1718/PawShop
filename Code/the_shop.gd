extends Node2D

@onready
var toys := [$Toys/Toys1, $Toys/Toys2, $Toys/Toys3]
@onready
var clock_label := $Clock/TimeLabel
var original_scales := {}

func _ready():
	GameManager.connect("day_changed", Callable(self, "_on_day_changed"))
	for toy in toys:
		original_scales[toy] = toy.scale

func _process(delta: float) -> void:
	clock_label.text = get_formatted_time()

func get_formatted_time() -> String:
	var hour_str = str(GameManager.hour).pad_zeros(2)
	var minute_str = str(int(GameManager.minute)).pad_zeros(2)
	return hour_str + ":" + minute_str #+ " | Day " + str(GameManager.day)


func _on_day_changed(day: int) -> void:
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
