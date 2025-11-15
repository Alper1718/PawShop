extends Resource
class_name Customer

@export var asset_path: String = ""
@export var name: String = ""
@export var day: int = 0
@export var is_first: bool = false
@export var feature: String = ""
@export var min_value: float = 0.0
@export var max_price: int = 0
@export var will_accept_paying_more: bool = false

@export var dialogues: Dictionary = {
	"opening1": "",
	"opening2": "",
	"opening3": "",
	"happy": "",
	"sad": "",
	"pazarlik": ""
}

static func from_dict(data: Dictionary) -> Customer:
	var c := Customer.new()
	c.asset_path = String(data.get("asset_path", ""))
	c.name = String(data.get("name", ""))
	c.day = int(data.get("day", 0))
	c.is_first = bool(data.get("is_first", false))
	c.feature = String(data.get("feature", ""))
	c.min_value = float(data.get("min_value", 0.0))
	c.max_price = int(data.get("max_price", 0))
	c.will_accept_paying_more = bool(data.get("will_accept_paying_more", false))

	var dd = data.get("dialogues", {})
	if typeof(dd) == TYPE_DICTIONARY:
		for k in dd.keys():
			c.dialogues[String(k)] = String(dd[k])
	return c

func get_openings() -> Array:
	return [
		dialogues.get("opening1", ""),
		dialogues.get("opening2", ""),
		dialogues.get("opening3", "")
	]

func get_line(key: String) -> String:
	return String(dialogues.get(key, ""))
