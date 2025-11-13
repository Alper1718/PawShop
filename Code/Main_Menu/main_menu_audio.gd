extends Control
signal audio_back_pressed

const SLIDER_HEIGHT = 16
const LABEL_HEIGHT = 23


func _ready() -> void:
	
	var main_menu = get_parent()
	var sprites = get_parent().get_tree().get_nodes_in_group("menu_sprites")
	
	#var labels = get_tree().get_nodes_in_group("audio_labels")
	#var sliders = get_tree().get_nodes_in_group("audio_sliders")
	
	var new_sprite = sprites[0].duplicate()
	add_child(new_sprite)
	sprites.append(new_sprite)
	
	var starting_y = 410.0
	var spacing = 150
	
	for i in range(sprites.size()):
		sprites[i].position = Vector2(sprites[i].position.x, starting_y + i * spacing)
		#if (i != 3):
		#	labels[i].position = Vector2(labels[i].position.x, (starting_y + i * spacing) - LABEL_HEIGHT/2)
		#	sliders[i].position = Vector2(sliders[i].position.x, (starting_y + i * spacing) - SLIDER_HEIGHT/2)
		
	

func _process(_delta: float) -> void:
	pass


func _on_back_button_pressed() -> void:
	var main_menu = get_parent()
	var sprites = get_parent().get_tree().get_nodes_in_group("menu_sprites")
	sprites[0].position = Vector2(sprites[0].position.x, 459)
	sprites[1].position = Vector2(sprites[1].position.x, 641)
	sprites[2].position = Vector2(sprites[2].position.x, 827)
	emit_signal("audio_back_pressed")
