extends Node2D

@onready var toys := [$Toys/Toys1, $Toys/Toys2, $Toys/Toys3]
@onready var clock_label := $Clock/TimeLabel
@onready var morning_bg := $ShopMorningBackground
@onready var evening_bg := $ShopEveningBackground
@onready var night_bg := $ShopNightBackground
@onready var SecondPhase := $CustomerPanel/SecondPhase
@onready var customer_panel := $CustomerPanel
@onready var customer_sprite := $CustomerPanel/Sprite2D
@onready var speech_label := $CustomerPanel/SpeechBubble/Label
@onready var give_button := $CustomerPanel/VBoxContainer/GiveButton
@onready var reject_button := $CustomerPanel/VBoxContainer/RejectButton
@onready var price_input := $CustomerPanel/SecondPhase/PriceInput 
@onready var price_offer_button := $CustomerPanel/SecondPhase/OfferButton

var waiting_for_offer: bool = false
var original_scales := {}
var current_bg: Node2D = null
var current_customer: Customer
var _typing_seq := 0
var _openings: Array = []
var _current_opening_index: int = 0
var _typing_in_progress: bool = false
var _selected_dog: Dog = null
var returning_from_kennel: bool = false


const TRANSITION_DURATION := 3.0

func _ready():
	if GameManager.is_connected("day_changed", Callable(self, "_on_day_changed")):
		GameManager.disconnect("day_changed", Callable(self, "_on_day_changed"))
	GameManager.connect("day_changed", Callable(self, "_on_day_changed"))
	for toy in toys:
		original_scales[toy] = toy.scale
	morning_bg.modulate.a = 0.0
	evening_bg.modulate.a = 0.0
	night_bg.modulate.a = 0.0
	price_input.visible = false
	price_offer_button.visible = false

	if GameManager.just_came_from_kennel:
		_instant_set_background(GameManager.hour)
		GameManager.just_came_from_kennel = false
	else:
		morning_bg.modulate.a = 0.0
		evening_bg.modulate.a = 0.0
		night_bg.modulate.a = 0.0
		_update_background(GameManager.hour)
	
	if GameManager.request_meeted:
		GameManager.customers_queue.remove_at(0)
		GameManager.request_meeted = false
	
	if !GameManager.customers_queue.is_empty():
		current_customer = GameManager.customers_queue[0]
		_openings.clear()
		_current_opening_index = 0
		_load_customer()

func _process(_delta: float) -> void:
	clock_label.text = get_formatted_time()
	_update_background(GameManager.hour)
	
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if customer_panel.visible and not _typing_in_progress and not waiting_for_offer:
			_show_next_opening()

	
func _please():
	_advance_to_next_customer()
	
func _show_next_customer():
	print("Called")
	if GameManager.customers_queue.is_empty():
		customer_panel.visible = false
		print("No customers left")
		return
	
	# current_customer = GameManager.customers_queue.pop_front()
	if current_customer == null:
		print("No customers left")
	print(current_customer["name"])
	customer_panel.visible = true
	
	_load_customer()
	
func _load_customer():
	$CustomerPanel/VBoxContainer.visible = false

	if current_customer == null:
		push_error("No current_customer to load")
		return

	if ResourceLoader.exists(current_customer.asset_path):
		customer_sprite.texture = load(current_customer.asset_path)
	else:
		customer_sprite.texture = null

	if _openings.size() == 0:
		_openings = current_customer.get_openings()
		_current_opening_index = 0

	_show_next_opening()

func _show_next_customer_buttons():
	var give_callable = Callable(self, "_on_give_button_pressed")
	var reject_callable = Callable(self, "_on_reject_button_pressed")

	if give_button.is_connected("pressed", give_callable):
		give_button.disconnect("pressed", give_callable)
	give_button.pressed.connect(give_callable)

	if reject_button.is_connected("pressed", reject_callable):
		reject_button.disconnect("pressed", reject_callable)
	reject_button.pressed.connect(reject_callable)

	$CustomerPanel/VBoxContainer.visible = true

func _show_next_opening():
	if waiting_for_offer:
		return

	while _current_opening_index < _openings.size() and _openings[_current_opening_index].strip_edges() == "":
		_current_opening_index += 1

	if _current_opening_index >= _openings.size():
		_show_next_customer_buttons()
		return

	_typing_in_progress = true
	await _type_text(speech_label, _openings[_current_opening_index].strip_edges())
	_typing_in_progress = false

	_current_opening_index += 1

func _on_give_button_pressed():
	GameManager.give_mode = true

	var kennel_scene := preload("res://Scenes/Kennel.tscn")
	var kennel_page := kennel_scene.instantiate()
	get_tree().root.add_child(kennel_page)

	kennel_page.select_mode = true
	kennel_page.selection_callback = Callable(self, "_on_dog_selected")

	kennel_page.back_callback = Callable(self, "_on_kennel_back_pressed")

	customer_panel.visible = false
	waiting_for_offer = false

func _on_kennel_back_pressed():
	customer_panel.visible = true
	if _selected_dog:
		SecondPhase.visible = true
		price_input.visible = true
		price_offer_button.visible = true
	else:
		SecondPhase.visible = false



func _on_dog_selected(dog: Dog):
	var feature = current_customer.feature
	var required_value = current_customer.min_value
	
	var meets = false
	if feature == "cuteness":
		meets = dog.cuteness >= required_value
	else:
		meets = dog.get(feature) >= required_value
	
	if meets:
		_selected_dog = dog
		SecondPhase.visible = true
		price_input.visible = true
		price_offer_button.visible = true
		await _type_text(speech_label, "This dog matches your requirements! What will you offer?")
		waiting_for_offer = true
	else:
		await _type_text(speech_label, current_customer.dialogues.sad)
		await get_tree().create_timer(1.0).timeout
		_advance_to_next_customer()


func _on_reject_button_pressed():
	await _type_text(speech_label, current_customer.dialogues.sad)
	print("You told the customer you don't have a dog matching their criteria.")
	await get_tree().create_timer(1.0).timeout
	_advance_to_next_customer()


func _on_raise_button_pressed():
	var new_price = int(current_customer.max_price * 1.5)
	var raise_text := "I'll offer to pay $%s instead." % new_price
	await _type_text(speech_label, raise_text)
	print("Raised price to $%s" % new_price)
	await get_tree().create_timer(1.0).timeout
	_advance_to_next_customer()


func _advance_to_next_customer() -> void:
	if !GameManager.customers_queue.is_empty():
		GameManager.customers_queue.remove_at(0)
	if !GameManager.customers_queue.is_empty():
		current_customer = GameManager.customers_queue[0]
		_openings.clear()
		_current_opening_index = 0
		_load_customer()
	else:
		customer_panel.visible = false
		print("No more customers!")


func _type_text(label, text: String, speed: float = 0.02) -> void:
	_typing_seq += 1
	var my_seq = _typing_seq
	label.text = ""
	for i in range(1, text.length() + 1):
		if my_seq != _typing_seq:
			return
		label.text = text.substr(0, i)
		await get_tree().create_timer(speed).timeout

func get_formatted_time() -> String:
	var hour_str = str(GameManager.hour).pad_zeros(2)
	var minute_str = str(int(GameManager.minute)).pad_zeros(2)
	return hour_str + ":" + minute_str

func _update_background(hour: int) -> void:
	var target_bg: Node2D = morning_bg

	if hour >= 6 and hour < 12:
		target_bg = morning_bg
	elif hour >= 12 and hour < 15:
		target_bg = evening_bg
	else:
		target_bg = night_bg

	if target_bg != current_bg:
		if current_bg:
			var tween_out = create_tween()
			tween_out.tween_property(current_bg, "modulate:a", 0.0, TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var tween_in = create_tween()
		tween_in.tween_property(target_bg, "modulate:a", 1.0, TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		current_bg = target_bg

func _on_day_changed(_day: int) -> void:
	pass

func _on_toys_button_pressed() -> void:
	$"/root/MusicPlayer".play_toy_noise()

	for toy in toys:
		toy.scale = original_scales[toy]

		for tween in toy.get_children():
			if tween is Tween:
				tween.kill()
				tween.queue_free()

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		var squish_scale = original_scales[toy] * Vector2(1.1, 0.8)
		tween.tween_property(toy, "scale", squish_scale, 0.06)
		tween.tween_property(toy, "scale", original_scales[toy], 0.08)

func _instant_set_background(hour: int) -> void:
	morning_bg.modulate.a = 0.0
	evening_bg.modulate.a = 0.0
	night_bg.modulate.a = 0.0

	if hour >= 6 and hour < 12:
		current_bg = morning_bg
	elif hour >= 12 and hour < 15:
		current_bg = evening_bg
	else:
		current_bg = night_bg

	current_bg.modulate.a = 1.0

func _on_switch_scene_button_pressed() -> void:
	GameManager.give_mode = false
	get_tree().change_scene_to_file("res://Scenes/kennel.tscn")


func _on_offer_button_pressed() -> void:
	var offer_text = price_input.text.strip_edges()
	var offer_amount: int = 0

	if offer_text.is_valid_integer():
		offer_amount = int(offer_text)
	else:
		await _type_text(speech_label, "Please enter a valid number!")
		return

	var dog = _selected_dog
	if dog == null:
		push_error("No dog selected for the offer!")
		return
	var estimated_price = GameManager.estimate_doggo_price(dog)
	var max_tolerance = int(estimated_price * 1.2)

	if offer_amount <= max_tolerance:
		await _type_text(speech_label, current_customer.dialogues.happy)
		GameManager.money += offer_amount
		GameManager.dogs.erase(dog)
		print("Customer bought the dog for $%s" % offer_amount)
	else:
		await _type_text(speech_label, "Hmm, that's too much! I can't pay that.")

	price_input.visible = false
	price_offer_button.visible = false
	SecondPhase.visible = false
	_selected_dog = null
	waiting_for_offer = false
	await get_tree().create_timer(1.0).timeout
	_advance_to_next_customer()
