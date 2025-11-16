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


var original_scales := {}

var current_bg: Node2D = null

var current_customer: Customer

var _typing_seq := 0

var _openings: Array = []

var _typing_in_progress: bool = false

var _selected_dog: Dog = null

var _skip_typing: bool = false
var _customer_locked_for_typing: bool = false


const TRANSITION_DURATION := 3.0


func _ready():
	
	$SwitchSceneButton.visible = true
	$ShopButtonSprite.visible = true
	GameManager.time_paused = false

	if GameManager.is_connected("day_changed", Callable(self, "_on_day_changed")):

		GameManager.disconnect("day_changed", Callable(self, "_on_day_changed"))

	GameManager.connect("day_changed", Callable(self, "_on_day_changed"))

	for toy in toys:

		original_scales[toy] = toy.scale

	morning_bg.modulate.a = 0.0

	evening_bg.modulate.a = 0.0

	night_bg.modulate.a = 0.0


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

		_load_customer()


func _process(_delta: float) -> void:

	clock_label.text = get_formatted_time()

	_update_background(GameManager.hour)

	if not has_node("DaySummaryOverlay") and (

		GameManager.hour >= GameManager.WORK_HOURS_END or

		GameManager.customers_served_today >= GameManager.MAX_CUSTOMERS_PER_DAY

	):
		print('process')
		get_tree().change_scene_to_file("res://Scenes/day_summary.tscn")

	

func _input(event):

	if event is InputEventMouseButton and event.pressed:

		if customer_panel.visible and not _typing_in_progress:

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

	_openings = current_customer.get_openings()

	GameManager.current_opening_index = 0
	speech_label.text = ""
	_typing_seq = 0
	_typing_in_progress = false

	customer_panel.visible = true
	print("Loading customer; queue size:", GameManager.customers_queue.size(), "opening_index:", GameManager.current_opening_index)
	await get_tree().create_timer(0.05).timeout
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

	while GameManager.current_opening_index < _openings.size() and _openings[GameManager.current_opening_index].strip_edges() == "":

		GameManager.current_opening_index += 1


	if GameManager.current_opening_index >= _openings.size():

		_show_next_customer_buttons()

		return


	_typing_in_progress = true

	await _type_text(speech_label, _openings[GameManager.current_opening_index].strip_edges())

	_typing_in_progress = false


	GameManager.current_opening_index += 1



func _on_give_button_pressed():

	GameManager.give_mode = true

	_selected_dog = null


	var kennel_scene := preload("res://Scenes/Kennel.tscn")

	var kennel_page := kennel_scene.instantiate()

	get_tree().root.add_child(kennel_page)


	kennel_page.select_mode = true

	kennel_page.selection_callback = Callable(self, "_on_dog_selected")


	kennel_page.back_callback = Callable(self, "_on_kennel_back_pressed")


	customer_panel.visible = false
	$SwitchSceneButton.visible = false
	$ShopButtonSprite.visible = false


func _on_kennel_back_pressed():

	customer_panel.visible = true

	SecondPhase.visible = false

	_selected_dog = null





func _on_dog_selected(dog: Dog):
	var feature = current_customer.feature
	var required_value = current_customer.min_value
	
	var meets = false
	if feature == "cuteness":
		meets = dog.cuteness >= required_value
	else:
		meets = dog.get(feature) >= required_value
	
	customer_panel.visible = true
	SecondPhase.visible = false
	$CustomerPanel/VBoxContainer.visible = false

	if meets:
		var estimated_price = GameManager.estimate_doggo_price(dog)

		var happy_text = CustomerFunctions.get_happy(current_customer)
		print("[DEBUG] happy_text length:", happy_text.length(), "raw:", happy_text)
		speech_label.visible = true
		_customer_locked_for_typing = true
		print("[DEBUG] about to await _type_text (happy)")
		await _type_text(speech_label, happy_text)
		print("[DEBUG] finished awaiting _type_text (happy)")

		GameManager.money += estimated_price
		GameManager.dogs.erase(dog)
		print("Customer bought the dog for $%s" % estimated_price)
		
		_selected_dog = null
		
		await get_tree().create_timer(1.0).timeout
		_customer_locked_for_typing = false
		_advance_to_next_customer()
	else:
		var random_sad_index = CustomerFunctions.get_random_sad_index(current_customer)
		var sad_text = CustomerFunctions.get_sad(current_customer, random_sad_index)
		print("[DEBUG] sad_text length:", sad_text.length(), "raw:", sad_text)
		speech_label.visible = true
		_customer_locked_for_typing = true
		print("[DEBUG] about to await _type_text (sad)")
		await _type_text(speech_label, sad_text)
		print("[DEBUG] finished awaiting _type_text (sad)")

		await get_tree().create_timer(1.0).timeout
		_customer_locked_for_typing = false
		_advance_to_next_customer()



func _on_reject_button_pressed():
	$CustomerPanel/VBoxContainer.visible = false 
	var random_sad_index = CustomerFunctions.get_random_sad_index(current_customer)
	var sad_text = CustomerFunctions.get_sad(current_customer, random_sad_index)
	print("[DEBUG] reject sad_text length:", sad_text.length(), "raw:", sad_text)
	speech_label.visible = true
	_customer_locked_for_typing = true
	print("[DEBUG] about to await _type_text (reject)")
	await _type_text(speech_label, sad_text)
	print("[DEBUG] finished awaiting _type_text (reject)")

	print("You told the customer you don't have a dog matching their criteria.")
	await get_tree().create_timer(1.0).timeout
	_customer_locked_for_typing = false
	_advance_to_next_customer()



func _on_raise_button_pressed():

	var new_price = int(current_customer.max_price * 1.5)

	var raise_text := "I'll offer to pay $%s instead." % new_price

	await _type_text(speech_label, raise_text)

	print("Raised price to $%s" % new_price)

	await get_tree().create_timer(1.0).timeout

	_advance_to_next_customer()



func _advance_to_next_customer() -> void:
	while _customer_locked_for_typing:
		await get_tree().create_timer(0.05).timeout

	GameManager.customers_served_today += 1

	if GameManager.customers_served_today >= GameManager.MAX_CUSTOMERS_PER_DAY:
		print('max')
		get_tree().change_scene_to_file("res://Scenes/day_summary.tscn")
		return

	if !GameManager.customers_queue.is_empty():
		GameManager.customers_queue.remove_at(0)

	if !GameManager.customers_queue.is_empty():
		current_customer = GameManager.customers_queue[0]

		_openings = current_customer.get_openings()
		GameManager.current_opening_index = 0
		_typing_seq = 0
		_skip_typing = false
		_typing_in_progress = false
		_selected_dog = null
		SecondPhase.visible = false
		$CustomerPanel/VBoxContainer.visible = false
		speech_label.text = ""

		await get_tree().create_timer(0.5).timeout
		_load_customer()
	else:
		customer_panel.visible = false
		print("No more customers!")




func _type_text(label: Label, text: String, speed: float = 0.02) -> void:
	_typing_seq += 1

	var my_seq = _typing_seq

	print("[TYPE] start seq:", my_seq, "text_len:", text.length())

	label.text = ""

	_typing_in_progress = true

	_skip_typing = false

	for i in range(1, text.length() + 1):

		if my_seq != _typing_seq:
			if _skip_typing:
				label.text = text
			return

		label.text = text.substr(0, i)

		await get_tree().create_timer(speed).timeout


	_typing_in_progress = false

	_skip_typing = false

	print("[TYPE] finished seq:", my_seq)



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

	

func _show_day_summary():
	var overlay := $DaySummary
	# var fade := overlay.get_node("Fade")
	var image := overlay.get_node("SummaryImage")
	var text := overlay.get_node("SummaryText")

	GameManager.time_paused = true
	overlay.visible = true
	text.visible = true

	var gm = GameManager
	var rent = gm.RENT_COST
	var food = gm.FOOD_COST * gm.dogs.size()
	var needs = 20
	var total_expenses = rent + food + needs
	var final_balance = gm.money - total_expenses

	var summary = {
		"day": gm.day,
		"money": gm.money,
		"rent": rent,
		"food": food,
		"needs": needs,
		"total_expenses": total_expenses,
		"balance": final_balance
	}

	text.get_node("DayLabel").text = "Day {day} Summary".format(summary.day) 
	
	text.get_node("SavingsLabel").text = "€0"
	text.get_node("RentLabel").text = "-€0"
	text.get_node("FoodLabel").text = "-€0"
	text.get_node("NeedsLabel").text = "-€0"
	text.get_node("TotalLabel").text = "€0"

	'''image.modulate.a = 0.0
	# fade.modulate.a = 0.0

	var tween = create_tween()
	# tween.set_parallel(true)
	# tween.tween_property(fade, "modulate:a", 0.6, 1.5)
	tween.tween_property(image, "modulate:a", 1.0, 2.0)
	await tween.finished

	await _animate_summary_numbers(text, summary)'''
	
func _animate_summary_numbers(text: VBoxContainer, data: Dictionary) -> void:
	var duration := 1.0
	var steps := 30
	var delay := duration / steps
	
	var initial_savings = data.money
	var initial_balance = data.money
	var final_savings = data.money
	var final_rent = data.rent
	var final_food = data.food
	var final_needs = data.needs
	var final_balance = data.balance

	for i in range(1, steps + 1):
		var t = float(i) / steps
		
		text.get_node("SavingsLabel").text = "Savings: €%d" % int(lerp(0, final_savings, t))
		
		text.get_node("RentLabel").text = "Rent: -€%d" % int(lerp(0, final_rent, t))
		text.get_node("FoodLabel").text = "Dog Care: -€%d" % int(lerp(0, final_food, t))
		text.get_node("NeedsLabel").text = "Personal Needs: -€%d" % int(lerp(0, final_needs, t))
		
		text.get_node("TotalLabel").text = "Balance: €%d" % int(lerp(initial_balance, final_balance, t))
		
		await get_tree().create_timer(delay).timeout

	text.get_node("SavingsLabel").text = "Savings: €%d" % final_savings
	text.get_node("RentLabel").text = "Rent: -€%d" % final_rent
	text.get_node("FoodLabel").text = "Dog Care: -€%d" % final_food
	text.get_node("NeedsLabel").text = "Personal Needs: -€%d" % final_needs
	text.get_node("TotalLabel").text = "Balance: €%d" % final_balance

	GameManager.money = data.balance
