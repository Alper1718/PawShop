extends Node2D

@onready var toys := [$Toys/Toys1, $Toys/Toys2, $Toys/Toys3]
@onready var clock_label := $Clock/TimeLabel
@onready var morning_bg := $ShopMorningBackground
@onready var evening_bg := $ShopEveningBackground
@onready var night_bg := $ShopNightBackground

var original_scales := {}
var current_bg: Node2D = null
const TRANSITION_DURATION := 3.0

func _ready():
	GameManager.connect("day_changed", Callable(self, "_on_day_changed"))
	for toy in toys:
		original_scales[toy] = toy.scale
	morning_bg.modulate.a = 0.0
	evening_bg.modulate.a = 0.0
	night_bg.modulate.a = 0.0

	if GameManager.just_came_from_kennel:
		_instant_set_background(GameManager.hour)
		GameManager.just_came_from_kennel = false
	else:
		morning_bg.modulate.a = 0.0
		evening_bg.modulate.a = 0.0
		night_bg.modulate.a = 0.0
		_update_background(GameManager.hour)

func _process(delta: float) -> void:
	clock_label.text = get_formatted_time()
	_update_background(GameManager.hour)

func get_formatted_time() -> String:
	var hour_str = str(GameManager.hour).pad_zeros(2)
	var minute_str = str(int(GameManager.minute)).pad_zeros(2)
	return hour_str + ":" + minute_str #+ " | Day " + str(GameManager.day)

func _update_background(hour: int) -> void:
	var target_bg: Node2D = morning_bg

	if hour >= 6 and hour < 12:
		target_bg = morning_bg
	elif hour >= 12 and hour < 15:
		target_bg = evening_bg
	else:
		target_bg = night_bg

	if target_bg != current_bg:
		if current_bg:
			var tween_out = create_tween()
			tween_out.tween_property(current_bg, "modulate:a", 0.0, TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var tween_in = create_tween()
		tween_in.tween_property(target_bg, "modulate:a", 1.0, TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		current_bg = target_bg

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

func _instant_set_background(hour: int) -> void:
	morning_bg.modulate.a = 0.0
	evening_bg.modulate.a = 0.0
	night_bg.modulate.a = 0.0

	if hour >= 6 and hour < 12:
		current_bg = morning_bg
	elif hour >= 12 and hour < 15:
		current_bg = evening_bg
	else:
		current_bg = night_bg

	current_bg.modulate.a = 1.0

func _on_switch_scene_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/kennel.tscn")
