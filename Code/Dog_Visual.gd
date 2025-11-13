extends Node
class_name DogVisual

const ASSET_FMT := "res://assets/dogs/%s_%s%d.png"
const FEATURES := ["tail", "fur", "eyes", "nose"]

static func stat_to_rating(stat: float) -> int:
	var rating = int(ceil(stat / 10.0 * 3))
	return clamp(rating, 1, 3)

static func build_visual(dog: Dog) -> Node2D:
	var node := Node2D.new()

	var size_name := ""
	if dog.size < 3.3:
		size_name = "small"
	elif dog.size < 6.6:
		size_name = "middle"
	else:
		size_name = "big"

	for feature in FEATURES:
		var rating := stat_to_rating(dog.get(feature))
		var path := ASSET_FMT % [size_name, feature, rating]

		if ResourceLoader.exists(path):
			var sprite := Sprite2D.new()
			sprite.texture = load(path)
			sprite.centered = true

			if feature == "fur" or feature == "tail":
				sprite.modulate = dog.hsv

			node.add_child(sprite)

	# Adjust scale based on size stat
	var scale_factor = lerp(1.2, 0.8, dog.size / 10.0)
	node.scale = Vector2.ONE * scale_factor

	return node
