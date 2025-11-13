extends Node
class_name DogVisual

const ASSET_FMT := "res://assets/dogs/%s%d.png"
const FEATURES := ["tail","eyes", "nose", "fur"]

static func stat_to_rating(stat: float) -> int:
	var rating = int(ceil(stat / 10.0 * 3))
	return clamp(rating, 1, 3)

static func build_visual(dog: Dog) -> Node2D:
	var node := Node2D.new()

	for feature in FEATURES:
		var rating := stat_to_rating(dog.get(feature))
		var path := ASSET_FMT % [feature, rating]
		if ResourceLoader.exists(path):
			var sprite := Sprite2D.new()
			sprite.texture = load(path)
			sprite.centered = true
			node.add_child(sprite)
			
	var scale_factor = lerp(1.2, 0.8, dog.size / 10.0)
	node.scale = Vector2.ONE * scale_factor

	return node
