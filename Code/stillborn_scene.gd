extends Node2D

var bin_x_min := 538
var bin_x_max := 1400
var bin_y_min := 170
var bin_y_max := 530
@onready var puppy := $Puppy
@onready var trash_closed := $TrashClosed
@onready var trash_open := $TrashOpen
@onready var button := $Button

func _ready():
	trash_open.visible = false
	puppy.visible = false
	GameManager.stillborn_count += 1

func _process(delta):
	if Input.is_action_just_released("mouse_left"):
		var pos = puppy.global_position
		if pos.x >= bin_x_min and pos.x <= bin_x_max and pos.y >= bin_y_min and pos.y <= bin_y_max:
			_on_puppy_dropped_in_bin()

func _on_button_pressed() -> void:
	trash_open.visible = true
	trash_open.modulate.a = 0.0
	trash_closed.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(trash_closed, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(trash_open, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await get_tree().create_timer(0.3).timeout
	puppy.visible = true
	button.visible = false

func _on_puppy_dropped_in_bin():
	var tween = create_tween()
	tween.tween_property(puppy, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(trash_open, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	if GameManager.stillborn_count >= 2:
		GameManager.ending = "stillborn"
		GameManager.time_speed = 0
		get_tree().change_scene_to_file('res://Scenes/Endings/still_born_ending.tscn')
	get_tree().change_scene_to_file("res://Scenes/kennel.tscn")
