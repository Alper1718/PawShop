extends Node

var money: int = 100
var day: int = 1
var dogs: Array = []
var pregnancies: Array = []

var hour: int = 8
var minute: int = 0
const HOURS_PER_DAY := 24
const MINUTES_PER_HOUR := 60
var time_speed: float = 1.0 # 1 real second = 1 in-game minute
var _time_accumulator: float = 0.0

signal day_changed
signal minute_changed

const RENT_COST := 30
const FOOD_COST := 10
var current_scene: Node

func _ready() -> void:
	randomize()
	print("GameManager ready. Starting Day ", day)
	set_process(true)


func _process(delta: float) -> void:
	_time_accumulator += delta * time_speed
	while _time_accumulator >= 1.0:
		_time_accumulator -= 1.0
		advance_minute()

func advance_minute() -> void:
	minute += 1
	if minute >= MINUTES_PER_HOUR:
		minute = 0
		hour += 1
	if hour >= HOURS_PER_DAY:
		hour = 0
		next_day()

	emit_signal("minute_changed", hour, minute)

func advance_time(delta: float) -> void:
	minute += delta * time_speed
	if minute >= MINUTES_PER_HOUR:
		hour += int(minute / MINUTES_PER_HOUR)
		minute = minute % MINUTES_PER_HOUR

	if hour >= HOURS_PER_DAY:
		hour = hour % HOURS_PER_DAY
		next_day()


func change_scene(path: String) -> void:
	if current_scene:
		current_scene.queue_free()
	var next_scene = load(path).instantiate()
	get_tree().root.add_child(next_scene)
	current_scene = next_scene

func breed(parent1: Dog, parent2: Dog) -> Dog:
	var child := Dog.new()
	child.doggo_name = "Puppy"

	for stat in ["eyes", "fur", "nose", "tail"]:
		var val1 = parent1.get(stat)
		var val2 = parent2.get(stat)
		
		var high = max(val1, val2)
		var low = min(val1, val2)

		var bias := pow(randf(), 0.5)
		var stat_val :float= lerp(low, high, bias)
		
		if randf() < 0.15:
			stat_val += randf_range(0.0, 2.0)
		else:
			stat_val += randf_range(-0.5, 0.5)
		
		stat_val = clampf(stat_val, 0.0, 10.0)
		child.set(stat, stat_val)

	child.cuteness = (child.eyes + child.fur + child.nose + child.tail) * 2.5

	var avg_cute := (parent1.cuteness + parent2.cuteness) / 2.0
	var base_risk := pow(avg_cute / 100.0, 2.2) * 0.75
	var final_risk := clampf(base_risk, 0.0, 0.95)
	child.stillborn = randf() < final_risk
	child.gestation_days = round(2.0 + (avg_cute / 100.0) * 3.0)

	pregnancies.append({
		"child": child,
		"days_left": child.gestation_days
	})

	print("Pregnancy started! Gestation:", child.gestation_days, "days.")
	return child




func next_day() -> void:
	day += 1
	print("\nDay", day, "begins.")
	handle_pregnancies()
	pay_expenses()
	emit_signal("day_changed", day)

func handle_pregnancies() -> void:
	var born_today: Array = []

	for preg in pregnancies:
		preg["days_left"] -= 1
		if preg["days_left"] <= 0:
			born_today.append(preg)

	for birth in born_today:
		pregnancies.erase(birth)
		var pup = birth["child"]

		if pup.stillborn:
			print("A puppy was stillborn. Too cute for this world.")
		else:
			print("A new puppy was born!")
			add_dog(pup)


func pay_expenses() -> void:
	var expenses = RENT_COST + FOOD_COST * dogs.size()
	money -= expenses
	print("Expenses paid:", -expenses, "→ Money left:", money)
	if money < 0:
		print("Bankrupt! Game Over.")

func add_dog(dog: Resource) -> void:
	dogs.append(dog)

func create_dog_from_dict(data: Dictionary) -> Resource:
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
