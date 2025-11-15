extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var squeaknoisepath := load("res://Sounds/dog_toy_squeak.mp3")
var musicpath := load("res://Sounds/Parcam-8-2.ogg")

func _ready() -> void:
	music_player.volume_db = 0
	sfx_player.volume_db = 6

func play_toy_noise() -> void:
	sfx_player.stream = squeaknoisepath
	sfx_player.play()

func play_music() -> void:
	music_player.stream = musicpath
	if music_player.stream is AudioStream:
		music_player.stream.loop = true
	music_player.play()
