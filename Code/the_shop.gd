extends Node2D

@onready var toys := [$Toys/Toys1, $Toys/Toys2, $Toys/Toys3]
@onready var clock_label := $Clock/TimeLabel
@onready var morning_bg := $ShopMorningBackground
@onready var evening_bg := $ShopEveningBackground
@onready var night_bg := $ShopNightBackground

@onready var customer_panel := $CustomerPanel
@onready var customer_sprite := $CustomerPanel/Sprite2D
@onready var speech_label := $CustomerPanel/SpeechBubble/Label
@onready var give_button := $CustomerPanel/VBoxContainer/GiveButton
@onready var reject_button := $CustomerPanel/VBoxContainer/RejectButton
@onready var raise_button := $CustomerPanel/VBoxContainer/RaiseButton

var original_scales := {}
var current_bg: Node2D = null
var current_customer: Customer
var _typing_seq := 0
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

	if GameManager.just_came_from_kennel:
		_instant_set_background(GameManager.hour)
		GameManager.just_came_from_kennel = false
	else:
		morning_bg.modulate.a = 0.0
		evening_bg.modulate.a = 0.0
		night_bg.modulate.a = 0.0
		_update_background(GameManager.hour)
	
	if GameManager.request_meeted == true:
		GameManager.customers_queue.remove_at(0)
		if !GameManager.customers_queue.is_empty():
			current_customer = GameManager.customers_queue[0]
			GameManager.request_meeted = false
			_show_next_customer()
			
	else:
		if !GameManager.customers_queue.is_empty():
			current_customer = GameManager.customers_queue[0] #TODO: What do you think will happen when the last customer is gone? It will respawn. Also it is not a criteria for the customer to be happy for it to be removed from the list.
			_load_customer()

func _process(delta: float) -> void:
	clock_label.text = get_formatted_time()
	_update_background(GameManager.hour)	
	
func _please():
	GameManager.customers_queue.remove_at(0)
	if !GameManager.customers_queue.is_empty():
		current_customer = GameManager.customers_queue[0]
		GameManager.request_meeted = false
		_show_next_customer()
	
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
	
	if ResourceLoader.exists(current_customer.asset_path):
		customer_sprite.texture = load(current_customer.asset_path)

	'''var opening_text = current_customer.dialogues.opening.format({
		"feature": current_customer.feature.capitalize(),
		"value": str(current_customer.min_value),
		"price": str(current_customer.max_price)
	})''' # TODO formattable texts
	var opening_text = CustomerFunctions.get_opening(current_customer, CustomerFunctions.get_random_opening_index())
	_type_text(speech_label, opening_text)
	
	var give_callable = Callable(self, "_on_give_button_pressed")
	var reject_callable = Callable(self, "_on_reject_button_pressed")
	var raise_callable = Callable(self, "_on_raise_button_pressed")

	if give_button.is_connected("pressed", give_callable):
		give_button.disconnect("pressed", give_callable)
	give_button.pressed.connect(give_callable)

	if reject_button.is_connected("pressed", reject_callable):
		reject_button.disconnect("pressed", reject_callable)
	reject_button.pressed.connect(reject_callable)

	if raise_button.is_connected("pressed", raise_callable):
		raise_button.disconnect("pressed", raise_callable)
	raise_button.pressed.connect(raise_callable)


func _on_give_button_pressed():
	GameManager.give_mode = true
	var kennel_scene := preload("res://Scenes/Kennel.tscn")
	var kennel_page := kennel_scene.instantiate()
	get_tree().root.add_child(kennel_page)
	kennel_page.select_mode = true
	kennel_page.selection_callback = Callable(self, "_on_dog_selected")
	


func _on_dog_selected(dog: Dog):
	var feature = current_customer.feature
	var required_value = current_customer.min_value
	var max_price = current_customer.max_price

	var meets = false
	if feature == "cuteness":
		meets = dog.cuteness >= required_value
	else:
		meets = dog.get(feature) >= required_value

	if meets:
		await _type_text(speech_label, current_customer.dialogues.happy)
		print("Customer is happy! You sold the dog for $%s" % max_price)
		GameManager.dogs.erase(dog)
	else:
		await _type_text(speech_label, current_customer.dialogues.sad)
		print("Customer rejected the dog. You earned nothing.")

	await get_tree().create_timer(1.0).timeout
	_show_next_customer()


func _on_reject_button_pressed():
	await _type_text(speech_label, current_customer.dialogues.sad)
	print("You told the customer you don't have a dog matching their criteria.")
	await get_tree().create_timer(1.0).timeout
	GameManager.customers_queue.remove_at(0)
	if !GameManager.customers_queue.is_empty():
		current_customer = GameManager.customers_queue[0]
		GameManager.request_meeted = false
		_show_next_customer()


func _on_raise_button_pressed():
	var new_price = int(current_customer.max_price * 1.5)
	var raise_text := "I'll offer to pay $%s instead." % new_price
	await _type_text(speech_label, raise_text)
	print("Raised price to $%s" % new_price)
	await get_tree().create_timer(1.0).timeout
	_show_next_customer()


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

func _on_day_changed(day: int) -> void:
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
