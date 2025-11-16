extends Node2D

func _ready():
	var box = $VBoxContainer
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.pivot_offset = box.size / 2
	box.position = get_viewport_rect().size / 2.1


	$VBoxContainer/Label.text = "Content Warning"
	$VBoxContainer/Label2.text = """\
This game contains themes and imagery that may be
disturbing to some players, including:

– Strong language  
– Depictions of animal harm  
– Blood and death  
– References to suicide  

Viewer discretion is advised.
"""


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main_Menu/main_menu.tscn")
