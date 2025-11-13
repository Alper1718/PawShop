extends Control

@onready var first_panel := $FirstDogInfoBox/HBoxContainer/DataColumn
@onready var second_panel := $SecondDogInfoBox/HBoxContainer/DataColumn
@onready var first_visual_container := $FirstDogVisual
@onready var second_visual_container := $SecondDogVisual
@onready var confirm_button := $ConfirmButton
@onready var cancel_button := $CancelButton
@onready var gestation_label := $GestationLabel

var parent1: Dog
var parent2: Dog
var kennel_scene: Node = null

const DOG_OFFSETS := {
	"small": Vector2(250, 170),
	"middle": Vector2(390, 150),
	"big": Vector2(610, 180)
}

const DOG_SCALES := {
	"small": 0.31,
	"middle": 0.38,
	"big": 0.31
}

func _ready():
	confirm_button.connect("pressed", Callable(self, "_on_confirm_pressed"))
	cancel_button.connect("pressed", Callable(self, "_on_cancel_pressed"))

func _adjust_z_index(node: Node) -> void:
	if node is CanvasItem:
		node.z_index += 2
	for child in node.get_children():
		_adjust_z_index(child)

func setup(dog1: Dog, dog2: Dog, kennel_ref: Node) -> void:
	parent1 = dog1
	parent2 = dog2
	kennel_scene = kennel_ref

	var first_offset := Vector2(810, 0)
	var second_offset := Vector2(250, 0)

	_update_info(first_panel, first_visual_container, dog1, first_offset)
	_update_info(second_panel, second_visual_container, dog2, second_offset)

	var gestation_days = GameManager.estimate_gestation(dog1, dog2)
	gestation_label.text = "Gestation Period:\n " + str(gestation_days) + " hours."
	_adjust_z_index(self)


func _update_info(panel: Node, visual_container: Node, doggo: Dog, custom_offset: Vector2) -> void:
	panel.get_node("EyesLabel").text = "Eyes: " + str(snappedf(doggo.eyes, 0.1))
	panel.get_node("FurLabel").text = "Fur: " + str(snappedf(doggo.fur, 0.1))
	panel.get_node("NoseLabel").text = "Nose: " + str(snappedf(doggo.nose, 0.1))
	panel.get_node("TailLabel").text = "Tail: " + str(snappedf(doggo.tail, 0.1))
	panel.get_node("CutenessValueLabel").text = "Cuteness: " + str(int(doggo.cuteness))
	panel.get_node("EstValueDataLabel").text = "Est. Value: " + str(int(GameManager.estimate_doggo_price(doggo)))
	panel.get_parent().get_parent().get_node("NameLabel").text = str(doggo.size)
	
	for child in visual_container.get_children():
		child.queue_free()
	
	var features := ["tail", "fur", "nose", "eyes"]
	
	var size_str := ""
	if doggo.size <= 3.33:
		size_str = "small"
	elif doggo.size <= 6.66:
		size_str = "middle"
	else:
		size_str = "big"
	
	var scale_factor = DOG_SCALES[size_str]
	var base_offset = DOG_OFFSETS[size_str]
	
	for feature in features:
		var rating := int(ceil(doggo.get(feature) / 10.0 * 3))
		rating = clamp(rating, 1, 3)
		var path := "res://assets/dogs/%s_%s%d.png" % [size_str, feature, rating]
		if ResourceLoader.exists(path):
			var sprite := Sprite2D.new()
			sprite.texture = load(path)
			sprite.centered = true
			sprite.position = base_offset + custom_offset
			sprite.scale = Vector2.ONE * scale_factor
			if feature == "fur" or feature == "tail":
						sprite.modulate = doggo.hsv
			visual_container.add_child(sprite)


func _on_confirm_pressed() -> void:
	if parent1 == null or parent2 == null:
		return
	
	var child = GameManager.breed(parent1, parent2)
	if child.stillborn:
		print("A puppy was stillborn. Too cute for this world.")
	else:
		print("A new puppy was born!")
		GameManager.add_dog(child)
	
	if kennel_scene:
		kennel_scene.update_cages()
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()
