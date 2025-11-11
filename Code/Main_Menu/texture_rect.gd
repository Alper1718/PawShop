extends TextureRect

@export var background_textures: Array[Texture2D]
@export var flicker_chance := 0.01
@export var flicker_duration := 0.10

var normal_texture: Texture2D
var glitching := false

func _ready():
	background_textures = [
		load("res://Assets/Main_Menu/background_base.jpeg"),
		load("res://Assets/Main_Menu/background_glitch_1.jpeg"),
		load("res://Assets/Main_Menu/background_glitch_2.jpeg"),
		load("res://Assets/Main_Menu/background_glitch_3.jpeg"),
		load("res://Assets/Main_Menu/background_glitch_4.jpeg"),
		load("res://Assets/Main_Menu/background_glitch_5.jpeg")
	]
	normal_texture = background_textures[0]
	texture = normal_texture
	texture = normal_texture

func _process(delta):
	if !glitching and randf() < flicker_chance * delta * 60:
		_trigger_glitch()

func _trigger_glitch():
	glitching = true
	var idx = randi_range(1, background_textures.size() - 1)
	texture = background_textures[idx]
	await get_tree().create_timer(flicker_duration+randf()*0.3).timeout
	texture = normal_texture
	glitching = false
