extends Node2D

@onready var info_panel := $DogsInfoBox/HBoxContainer/DataColumn
@onready var cages_grid := $ScrollContainer/CagesContainer
@onready var cages_scroll := $ScrollContainer
@onready var bg_texture := $ScrollContainer/BackgroundTextureRect

var selected_doggo: Dog = null
var breed_mode: bool = false
var first_parent: Dog = null

const GRID_ROWS := 3

const DOG_OFFSETS := {
	"small": Vector2(-250, 50),
	"middle": Vector2(135, 110),
	"big": Vector2(460, 150)
}

const DOG_SCALES := {
	"small": 0.69,
	"middle": 0.54,
	"big": 0.45
}

func _ready():
	cages_grid.columns = GRID_ROWS
	update_cages()
	
func _process(delta: float) -> void:
	var scroll_x = cages_scroll.scroll_horizontal
	bg_texture.position.x = -scroll_x

func update_info_panel(doggo: Dog) -> void:
	selected_doggo = doggo
	get_node("DogsInfoBox/NameLabel").text = str(doggo.size)
	info_panel.get_node("EyesLabel").text = "Eyes: " + str(snappedf(doggo.eyes, 0.1))
	info_panel.get_node("FurLabel").text = "Fur: " + str(snappedf(doggo.fur, 0.1))
	info_panel.get_node("NoseLabel").text = "Nose: " + str(snappedf(doggo.nose, 0.1))
	info_panel.get_node("TailLabel").text = "Tail: " + str(snappedf(doggo.tail, 0.1))
	info_panel.get_node("CutenessValueLabel").text = "Cuteness: " + str(int(doggo.cuteness))
	info_panel.get_node("EstValueDataLabel").text = "Est. Value: " + str(int(GameManager.estimate_doggo_price(doggo)))

func update_cages() -> void:
	for child in cages_grid.get_children():
		child.queue_free()

	var doggos = GameManager.dogs
	if doggos.is_empty():
		var label := Label.new()
		label.text = "No doggos yet!"
		cages_grid.add_child(label)
		return

	var rows := 3
	var total_doggos := doggos.size()
	var columns := int(ceil(float(total_doggos) / float(rows)))
	if columns < 1:
		columns = 1
	cages_grid.columns = columns

	var button_width := 1440.0 / 3.0
	var button_height := 360.0

	var total_slots := columns * rows
	var slots := []
	slots.resize(total_slots)
	for s in range(total_slots):
		slots[s] = -1

	for i in range(total_doggos):
		var col := int(floor(float(i) / float(rows)))
		var row := i % rows
		var slot_index := row * columns + col
		if slot_index >= 0 and slot_index < total_slots:
			slots[slot_index] = i

	for slot_val in slots:
		if slot_val == -1:
			var placeholder := Control.new()
			placeholder.custom_minimum_size = Vector2(button_width, button_height)
			placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cages_grid.add_child(placeholder)
		else:
			var dog_index := int(slot_val)
			if dog_index < 0 or dog_index >= GameManager.dogs.size():
				var ph := Control.new()
				ph.custom_minimum_size = Vector2(button_width, button_height)
				ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cages_grid.add_child(ph)
				continue

			var doggo = GameManager.dogs[dog_index]
			var btn := Button.new()
			btn.name = str(dog_index)
			btn.custom_minimum_size = Vector2(button_width, button_height)
			btn.size_flags_horizontal = Control.SIZE_FILL
			btn.size_flags_vertical = Control.SIZE_FILL
			btn.connect("pressed", Callable(self, "_on_cage_pressed").bind(dog_index))
			
			var dog_visual := Node2D.new()
			var features := ["tail", "fur", "nose", "eyes"]
			
			var size_str := ""
			if doggo.size <= 3.33:
				size_str = "small"
			elif doggo.size <= 6.66:
				size_str = "middle"
			else:
				size_str = "big"
			
			var offset = DOG_OFFSETS[size_str]
			var scale_factor = DOG_SCALES[size_str]
			
			for feature in features:
				var rating := int(ceil(doggo.get(feature) / 10.0 * 3))
				rating = clamp(rating, 1, 3)
				var path := "res://assets/dogs/%s_%s%d.png" % [size_str, feature, rating]
				if ResourceLoader.exists(path):
					var sprite := Sprite2D.new()
					sprite.texture = load(path)
					sprite.centered = true
					sprite.position = offset
					sprite.scale = Vector2.ONE * scale_factor
					dog_visual.add_child(sprite)
			
			btn.add_child(dog_visual)
			cages_grid.add_child(btn)

func _on_cage_pressed(index: int) -> void:
	var doggo = GameManager.dogs[index]
	if breed_mode:
		if doggo == first_parent:
			print("Cannot breed a doggo with itself!")
			return
		var child = GameManager.breed(first_parent, doggo)
		if child.stillborn:
			print("A puppy was stillborn. Too cute for this world.")
		else:
			print("A new puppy was born instantly!") # TODO: day cycle
			GameManager.add_dog(child)
		breed_mode = false
		first_parent = null
		update_cages()
	else:
		update_info_panel(doggo)

func _on_breed_button_pressed() -> void:
	if selected_doggo == null:
		print("Select a doggo first!")
		return
	
	breed_mode = true
	first_parent = selected_doggo
	print("Breed mode activated. Select a second doggo to breed with", first_parent.doggo_name)
