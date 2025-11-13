extends Node2D

@onready var info_panel := $DogsInfoBox/HBoxContainer/DataColumn
@onready var cages_grid := $ScrollContainer/CagesContainer
@onready var cages_scroll := $ScrollContainer
var selected_doggo: Dog = null
var breed_mode: bool = false
var first_parent: Dog = null

const GRID_ROWS := 3

func _ready():
	cages_grid.columns = GRID_ROWS
	update_cages()

func update_info_panel(doggo: Dog) -> void:
	selected_doggo = doggo
	get_node("DogsInfoBox/NameLabel").text = doggo.doggo_name
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

	var button_width := 1258.0 / 3.0
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
			btn.text = doggo.doggo_name
			btn.name = str(dog_index)
			btn.custom_minimum_size = Vector2(button_width, button_height)
			btn.size_flags_horizontal = Control.SIZE_FILL
			btn.size_flags_vertical = Control.SIZE_FILL
			btn.connect("pressed", Callable(self, "_on_cage_pressed").bind(dog_index))
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
