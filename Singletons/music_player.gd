extends Node

@onready
var audioplayer: AudioStreamPlayer = $AudioStreamPlayer
var squeaknoisepath:=load("res://Sounds/dog_toy_squeak.mp3")

func _ready() -> void:
	pass

func play_toy_noise() -> void:
	audioplayer.stream = squeaknoisepath
	audioplayer.play()
	
