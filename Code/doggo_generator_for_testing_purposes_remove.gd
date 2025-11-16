extends Node

# TODO: Remove this when real save/load is ready.
@export var doggo_count: int = 6

func _ready():
	if GameManager.dogs_initialized:
		return
	GameManager.dogs_initialized = true
	print("Adding predetermined test doggos...")

	var dogs_data = [
		{
			"name": "Ringo",
			"eyes": 8.5, "fur": 6.2, "nose": 7.3, "tail": 5.0, "size": 3.5,
			"hsv": Color.from_hsv(0.12, 0.3, 0.9)
		},
		{
			"name": "Bolt",
			"eyes": 4.5, "fur": 3.0, "nose": 8.0, "tail": 9.2, "size": 6.0,
			"hsv": Color.from_hsv(0.08, 0.5, 0.8)
		},
		{
			"name": "Luna",
			"eyes": 9.3, "fur": 8.8, "nose": 8.9, "tail": 9.1, "size": 4.0,
			"hsv": Color.from_hsv(0.7, 0.2, 0.95)
		},
		{
			"name": "Rufus",
			"eyes": 3.5, "fur": 2.0, "nose": 4.1, "tail": 5.6, "size": 7.0,
			"hsv": Color.from_hsv(0.05, 0.65, 0.7)
		},
		{
			"name": "Cleo",
			"eyes": 7.2, "fur": 5.9, "nose": 9.5, "tail": 8.3, "size": 2.5,
			"hsv": Color.from_hsv(0.95, 0.3, 0.9)
		},
		{
			"name": "Chonk",
			"eyes": 4.0, "fur": 7.8, "nose": 5.5, "tail": 8.0, "size": 9.5,
			"hsv": Color.from_hsv(0.33, 0.5, 0.8)
		}
	]

	for data in dogs_data:
		var doggo = Dog.new()
		doggo.doggo_name = data.name
		doggo.eyes = data.eyes
		doggo.fur = data.fur
		doggo.nose = data.nose
		doggo.tail = data.tail
		doggo.size = data.size
		doggo.cuteness = (data.eyes + data.fur + data.nose + data.tail) * 2.5
		doggo.hsv = data.hsv
		GameManager.add_dog(doggo)

	print("Added ", dogs_data.size(), " predetermined doggos.")

	if has_node("/root/KennelScene"):
		get_node("/root/KennelScene").update_cages()
