extends Node

var money: int = 100
var day: int = 1
var dogs: Array = []
var pregnancies: Array = []
var just_came_from_kennel := false
var time_paused: bool = false

var hour: int = 8
var minute: int = 0
const HOURS_PER_DAY := 24
const MINUTES_PER_HOUR := 60
var time_speed: float = 20.0
var _time_accumulator: float = 0.0

signal day_changed
signal minute_changed
signal hour_changed

const RENT_COST := 30
const FOOD_COST := 10
var current_scene: Node

var fullscreen = true

var customers_queue = [
		{
			"name": "Teyze",
			"sprite_path": "res://Assets/Customers/Teyze.jpeg",
			"feature": "eyes",
			"min_value": 5.0,
			"max_price": 900,
			"dialogues": {
				"opening": "I want a dog with {feature} ≥ {value}! I can pay up to ${price}.",
				"happy": "Begendim!",
				"sad": "So sad..."
			}
		},
		{
			"name": "Ergen",
			"sprite_path": "res://Assets/Customers/Ergen.jpeg",
			"feature": "cuteness",
			"min_value": 60.0,
			"max_price": 1700,
			"dialogues": {
				"opening": "Hello! I'm looking for a dog with {feature} ≥ {value}. My max budget is ${price}.",
				"happy": "Akıllı olur aklını alırım",
				"sad": "Takarım bıçağı görürsün."
			}
		}
	]
	
var request_meeted = false
#var first_customer = true

func _ready() -> void:
	randomize()
	print("GameManager ready. Starting Day ", day)
	set_process(true)

func _process(delta: float) -> void:
	if time_paused:
		return
	_time_accumulator += delta * time_speed
	while _time_accumulator >= 1.0:
		_time_accumulator -= 1.0
		advance_minute()

func advance_minute() -> void:
	minute += 1
	if minute >= MINUTES_PER_HOUR:
		minute = 0
		hour += 1
		emit_signal("hour_changed", hour)

	if hour >= HOURS_PER_DAY:
		hour = 0
		next_day()

	emit_signal("minute_changed", hour, minute)

	_update_pregnancies(1.0 / MINUTES_PER_HOUR)

func advance_time(delta_minutes: float) -> void:
	var delta_hours = delta_minutes / 60.0
	minute += delta_minutes
	while minute >= 60:
		minute -= 60
		hour += 1
	while hour >= HOURS_PER_DAY:
		hour -= HOURS_PER_DAY
		next_day()
	_update_pregnancies(delta_hours)

func next_day() -> void:
	day += 1
	print("\nDay", day, "begins.")
	pay_expenses()
	emit_signal("day_changed", day)

func breed(parent1: Dog, parent2: Dog) -> Dog:
	var child := Dog.new()
	child.doggo_name = "Puppy"

	for stat in ["eyes", "fur", "nose", "tail"]:
		var val1 = parent1.get(stat)
		var val2 = parent2.get(stat)
		var high = max(val1, val2)
		var low = min(val1, val2)
		var bias = pow(randf(), 0.5)
		var stat_val = lerp(low, high, bias)

		if randf() < 0.15:
			stat_val += randf_range(0.0, 2.0)
		else:
			stat_val += randf_range(-0.5, 0.5)

		child.set(stat, clampf(stat_val, 0.0, 10.0))

	child.cuteness = (child.eyes + child.fur + child.nose + child.tail) * 2.5
	child.stillborn = randf() < clamp(pow((parent1.cuteness + parent2.cuteness) / 200.0, 2.2) * 0.75, 0.0, 0.95)

	var inherited_s = clampf(lerp(parent1.hsv.s, parent2.hsv.s, randf()) + randf_range(-0.05, 0.05), 0.0, 1.0)
	var inherited_h = wrapf(lerp(parent1.hsv.h, parent2.hsv.h, 0.5) + randf_range(-0.05, 0.05), 0.0, 1.0)
	var inherited_v = clampf(lerp(parent1.hsv.v, parent2.hsv.v, 0.5) + randf_range(-0.05, 0.05), 0.0, 1.0)
	child.hsv = Color.from_hsv(inherited_h, inherited_s, inherited_v)

	var size_avg = (parent1.size + parent2.size) / 2.0
	var size_variation = randf_range(-0.2, 0.2)
	child.size = clampf(size_avg + size_variation, 0.1, 10.0)

	var gestation_hours = 2.0 + ((parent1.cuteness + parent2.cuteness) / 200.0) * 2.0
	pregnancies.append({
		"child": child,
		"parents": [parent1, parent2],
		"hours_left": gestation_hours
	})

	for dog in [parent1, parent2, child]:
		dog.set_meta("in_gestation", true)

	print("Pregnancy started! Gestation:", gestation_hours, "hours. Child size:", child.size)
	return child


func _update_pregnancies(delta_hours: float) -> void:
	var born: Array = []

	for preg in pregnancies:
		preg["hours_left"] -= delta_hours
		if preg["hours_left"] <= 0:
			born.append(preg)

	for preg in born:
		pregnancies.erase(preg)
		var pup = preg["child"]
		var parents = preg["parents"]

		if pup.has_meta("in_gestation"):
			pup.set_meta("in_gestation", false)
		for parent in parents:
			if parent.has_meta("in_gestation"):
				parent.set_meta("in_gestation", false)

		if pup.stillborn:
			print("A puppy was stillborn.")
		else:
			print("A new puppy was born!")
			add_dog(pup)

func add_dog(dog: Dog) -> void:
	dogs.append(dog)

func create_dog_from_dict(data: Dictionary) -> Dog:
	var dog = Dog.new()
	for key in data.keys():
		if dog.has_property(key):
			dog.set(key, data[key])
	return dog

func estimate_doggo_price(doggo: Dog) -> int:
	const BASE_MIN_PRICE := 300
	const BASE_MAX_PRICE := 5000
	var frac: float = clamp(doggo.cuteness / 100.0, 0.0, 1.0)
	var price_frac := pow(frac, 2.0)
	var raw_price := BASE_MIN_PRICE + (BASE_MAX_PRICE - BASE_MIN_PRICE) * price_frac
	return int(ceil(raw_price))

static func estimate_gestation(dog1: Dog, dog2: Dog) -> float:
	var base_hours = 2.0
	var avg_cute = (dog1.cuteness + dog2.cuteness) / 2.0
	var penalty = (avg_cute / 100.0) * 2.0
	return roundf(base_hours + penalty)

func pay_expenses() -> void:
	var expenses = RENT_COST + FOOD_COST * dogs.size()
	money -= expenses
	print("Expenses paid:", -expenses, "→ Money left:", money)
	if money < 0:
		print("Bankrupt! Game Over.")

func change_scene(path: String) -> void:
	if current_scene:
		current_scene.queue_free()
	var next_scene = load(path).instantiate()
	get_tree().root.add_child(next_scene)
	current_scene = next_scene
	
func _save_display_settings(fullscreen: bool, resolution: Vector2) -> Error:
	var config = ConfigFile.new()
	var err = config.load("res://settings.cfg")
	
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution", resolution)
	
	config.save("res://settings.cfg")
	
	return err
	
func _load_display_settings() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load("res://settings.cfg")
	if err != OK:
		return {"fullscreen": true, "resolution": Vector2(1920, 1080)}
		print("Error loading display settings.s")
	
	return {
		"fullscreen": config.get_value("display", "fullscreen", true),
		"resolution": config.get_value("display", "resolution", Vector2(1920, 1080))
	}
