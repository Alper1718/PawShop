extends Node
#TODO: Remove this.
@export var doggo_count: int = 18
@export var max_stat_value: float = 10.0
@export var min_stat_value: float = 0.0

func _ready():
	print("Generating test doggos...")
	for i in range(doggo_count):
		var doggo = generate_random_doggo(i)
		GameManager.add_dog(doggo)
	print("Generated", doggo_count, "test doggos.")

	if has_node("/root/KennelScene"):
		get_node("/root/KennelScene").update_cages()

func generate_random_doggo(index: int) -> Dog:
	var doggo = Dog.new()
	doggo.doggo_name = "Doggo #" + str(index + 1)
	doggo.eyes = randf_range(min_stat_value, max_stat_value)
	doggo.fur = randf_range(min_stat_value, max_stat_value)
	doggo.nose = randf_range(min_stat_value, max_stat_value)
	doggo.ears = randf_range(min_stat_value, max_stat_value)
	doggo.cuteness = (doggo.eyes + doggo.fur + doggo.nose + doggo.ears) * 2.5
	return doggo
