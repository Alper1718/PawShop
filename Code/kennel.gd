extends Node2D

@onready var info_panel := $DogsInfoBox/HBoxContainer/DataColumn
@onready var cages_grid := $ScrollContainer/CagesContainer
@onready var cages_scroll := $ScrollContainer
@onready var bg_texture := $ScrollContainer/NinePatchRect
@onready var bg := $ScrollContainer/NinePatchRect
@onready var bars := $ScrollContainer/MetalBarsRect
@onready var clock_label := $Clock/TimeLabel

var selected_doggo: Dog = null
var breed_mode: bool = false
var first_parent: Dog = null

const GRID_ROWS := 3
const SCROLL_AREA_SIZE := Vector2(1258, 1080)
const TILE_WIDTH := 1440.0

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
	_update_bg_size()
	update_cages()
	
func _process(_delta: float) -> void:
	var scroll_x: float = float(cages_scroll.scroll_horizontal)
	var wrapped_x: float = fmod(scroll_x, TILE_WIDTH)

	bg_texture.position.x = -wrapped_x
	bg.position.x = -wrapped_x
	bars.position.x = -wrapped_x

	_update_tiling(bg_texture, bg)
	_update_tiling(bars, null)

	if is_instance_valid(cages_grid):
		var content_w = cages_grid.get_combined_minimum_size().x
		if !is_equal_approx(bg.size.x, content_w):
			_update_bg_size()
			
	clock_label.text = get_formatted_time()


func _update_tiling(primary_node: Control, secondary_node: Control) -> void:
	var texture_w: float = TILE_WIDTH
	if secondary_node:
		secondary_node.size.x = texture_w
	primary_node.size.x = texture_w * 2

	var scroll_offset: float = fmod(float(cages_scroll.scroll_horizontal), texture_w)
	primary_node.position.x = -scroll_offset
	if secondary_node:
		secondary_node.position.x = -scroll_offset



func update_info_panel(doggo: Dog) -> void:
	selected_doggo = doggo
	get_node("DogsInfoBox/NameLabel").text = str(doggo.doggo_name)
	info_panel.get_node("EyesLabel").text = "Eyes: " + str(snappedf(doggo.eyes, 0.1))
	info_panel.get_node("FurLabel").text = "Fur: " + str(snappedf(doggo.fur, 0.1))
	info_panel.get_node("NoseLabel").text = "Nose: " + str(snappedf(doggo.nose, 0.1))
	info_panel.get_node("TailLabel").text = "Tail: " + str(snappedf(doggo.tail, 0.1))
	info_panel.get_node("CutenessValueLabel").text = "Cuteness: " + str(int(doggo.cuteness))
	info_panel.get_node("EstValueDataLabel").text = "Est. Value: " + str(int(GameManager.estimate_doggo_price(doggo)))

	var breed_button = get_node("BreedButton")
	if _is_dog_in_gestation(doggo):
		breed_button.disabled = true
		breed_button.text = "In Gestation"
	else:
		breed_button.disabled = false
		breed_button.text = "Breed"


func update_cages() -> void:
	_remove_duplicate_puppies()
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
					if feature == "fur" or feature == "tail":
						sprite.modulate = doggo.hsv
						
			bg_texture.size = cages_grid.size
			btn.add_child(dog_visual)
			cages_grid.add_child(btn)

func _on_cage_pressed(index: int) -> void:
	var doggo = GameManager.dogs[index]
	
	if breed_mode:
		if doggo == first_parent:
			print("Cannot breed a doggo with itself!")
			return
		
		var breed_confirm_scene := preload("res://Scenes/breed_confirm.tscn")
		var breed_page := breed_confirm_scene.instantiate()
		get_tree().root.add_child(breed_page)
		breed_page.setup(first_parent, doggo, self)
		
		breed_mode = false
		first_parent = null
	else:
		update_info_panel(doggo)


func _on_breed_button_pressed() -> void:
	if selected_doggo == null:
		print("Select a doggo first!")
		return
	
	breed_mode = true
	first_parent = selected_doggo
	print("Breed mode activated. Select a second doggo to breed with", first_parent.doggo_name)

func _update_bg_size() -> void:
	var content_size = cages_grid.get_combined_minimum_size()
	var viewport_w = cages_scroll.size.x
	var target_w = max(content_size.x, viewport_w)
	bg.size = Vector2(target_w, cages_scroll.size.y)

func get_formatted_time() -> String:
	var hour_str = str(GameManager.hour).pad_zeros(2)
	var minute_str = str(int(GameManager.minute)).pad_zeros(2)
	return hour_str + ":" + minute_str #+ " | Day " + str(GameManager.day)
	
func _is_parent_in_gestation(doggo: Dog) -> bool:
	for preg in GameManager.pregnancies:
		if preg.has("parents"):
			if doggo in preg["parents"]:
				return true
	return false
	
func _is_dog_in_gestation(doggo: Dog) -> bool:
	for preg in GameManager.pregnancies:
		if preg.has("parents") and doggo in preg["parents"]:
			return true
		if preg.has("child") and doggo == preg["child"]:
			return true
	return false

func _remove_duplicate_puppies() -> void:
	var seen: Array = []
	var duplicates: Array = []

	for doggo in GameManager.dogs:
		var key := str(snapped(doggo.eyes, 0.01)) + "-" + str(snapped(doggo.fur, 0.01)) + "-" + str(snapped(doggo.nose, 0.01)) + "-" + str(snapped(doggo.tail, 0.01)) + "-" + str(snapped(doggo.size, 0.01)) + "-" + str(snapped(doggo.hsv.h, 0.01)) + "-" + str(snapped(doggo.hsv.s, 0.01)) + "-" + str(snapped(doggo.hsv.v, 0.01)) #Mmm long

		
		if key in seen:
			duplicates.append(doggo)
		else:
			seen.append(key)
	
	for dup in duplicates:
		GameManager.dogs.erase(dup)
		print("Removed duplicate puppy:", dup.doggo_name)
