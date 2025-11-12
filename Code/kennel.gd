extends Node2D

@onready var info_panel := $DogsInfoBox/HBoxContainer/DataColumn
@onready var cages_container := $CagesContainer
@onready var prev_button := $PreviousAreaButton
@onready var next_button := $NextAreaButton

var selected_doggo: Dog = null
var cage_index_start := 0
const CAGES_PER_PAGE := 9

func _ready():
	update_cages()
	prev_button.connect("pressed", Callable(self, "_on_prev_pressed"))
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))

#This took me way longer than it should have.
func update_info_panel(doggo: Dog) -> void:
	selected_doggo = doggo
	get_node("DogsInfoBox/NameLabel").text = doggo.doggo_name
	info_panel.get_node("EyesLabel").text = "Eyes: " + str(snappedf(doggo.eyes, 0.1))
	info_panel.get_node("FurLabel").text = "Fur: " + str(snappedf(doggo.fur,0.1))
	info_panel.get_node("NoseLabel").text = "Nose: " + str(snappedf(doggo.nose, 0.1))
	info_panel.get_node("EarsLabel").text = "Ears: " + str(snappedf(doggo.ears, 0.1))
	info_panel.get_node("CutenessValueLabel").text = "Cuteness: " + str(int(doggo.cuteness))
	info_panel.get_node("EstValueDataLabel").text = "Est. Value: " + str(int(GameManager.estimate_doggo_price(doggo)))

	var found := false
	for preg in GameManager.pregnancies:
		if preg["child"] == doggo:
			info_panel.get_node("GestationLabel").text = "Gestation left: " + str(preg["days_left"])
			found = true
			break
	if not found:
		info_panel.get_node("GestationLabel").text = "No gestation in progress"

func update_cages() -> void:
	for child in cages_container.get_children():
		child.queue_free()

	var doggos = GameManager.dogs
	if doggos.is_empty():
		var label := Label.new()
		label.text = "No doggos yet!"
		cages_container.add_child(label)
		return

	for i in range(cage_index_start, min(cage_index_start + CAGES_PER_PAGE, doggos.size())):
		var doggo = doggos[i]
		var btn = Button.new()
		btn.text = doggo.doggo_name
		btn.name = str(i)
		btn.connect("pressed", Callable(self, "_on_cage_pressed").bind(i))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		cages_container.add_child(btn)

func _on_cage_pressed(index: int) -> void:
	var doggo = GameManager.dogs[index]
	update_info_panel(doggo)

func _on_next_pressed() -> void:
	var max_index = max(0, GameManager.dogs.size() - CAGES_PER_PAGE)
	if cage_index_start < max_index:
		cage_index_start = min(cage_index_start + CAGES_PER_PAGE, max_index)
		animate_cages_slide(-1)
		update_cages()

func _on_prev_pressed() -> void:
	if cage_index_start > 0:
		cage_index_start = max(0, cage_index_start - CAGES_PER_PAGE)
		animate_cages_slide(1)
		update_cages()

func animate_cages_slide(direction: int) -> void:
	for cage in cages_container.get_children():
		var tween = create_tween()
		tween.tween_property(
			cage, "position:x", cage.position.x + direction * 100, 0.2
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
