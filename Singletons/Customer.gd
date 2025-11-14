extends Resource
class_name Customer

@export var asset_path : String
@export var name: String
@export var day: int
@export var is_first: bool
@export var feature: String
@export var min_value: float
@export var max_price: int
@export var dialogues: Dictionary = {
	"opening" : "",
	"happy" : "",
	"sad" : ""
}
