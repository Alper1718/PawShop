extends Node

func random_doggo(name_index: int) -> Dog:
	var d := Dog.new()
	d.doggo_name = "Doggo " + str(name_index + 1)

	d.size  = randf_range(0, 10)
	d.eyes  = randf_range(0, 10)
	d.fur   = randf_range(0, 10)
	d.nose  = randf_range(0, 10)
	d.tail  = randf_range(0, 10)

	d.cuteness = (d.eyes + d.fur + d.nose + d.tail) * 2.5
	return d
