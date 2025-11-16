extends Node

const default_opening : String = "Hi!"
const default_sad : String = "Okay then."

func _ready() -> void:
	pass
	
func generate_customer(data: Dictionary) -> Customer:
	var customer = Customer.new()
	
	for key in data.keys():
		if customer.has_property(key):
			customer.set(key, data[key])
	return customer

func _is_integer_string(s: String) -> bool:
	if s == "":
		return false
	for ch in s:
		if ch < "0" or ch > "9":
			return false
	return true
	
func _collect_variants(cst: Customer, prefix: String) -> Array:
	var out := []
	if not (cst and cst.dialogues):
		return out
	for key in cst.dialogues.keys():
		if str(key).begins_with(prefix):
			var raw = str(cst.dialogues[key])
			var text = raw.strip_escapes().strip_edges()
			if text != "":
				var suffix = key.substr(prefix.length())
				var order := 1
				if suffix != "":
					order = int(suffix) if _is_integer_string(suffix) else 1
				out.append({"order": order, "text": text})
	out.sort_custom(func(a, b):
		return int(a["order"]) - int(b["order"])
	)
	var texts := []
	for item in out:
		texts.append(item["text"])
	return texts

func get_opening(cst: Customer, index: int) -> String:
	var openings = _collect_variants(cst, "opening")
	if openings.size() == 0:
		return default_opening.strip_escapes()
	if index >= 0 and index < openings.size():
		return openings[index]
	var idx := randi_range(0, openings.size() - 1)
	return openings[idx]
				
func get_sad(cst: Customer, index: int) -> String:
	var sads = _collect_variants(cst, "sad")
	if sads.size() == 0:
		if cst and cst.dialogues and "sad" in cst.dialogues and str(cst.dialogues["sad"]).strip_edges() != "":
			return str(cst.dialogues["sad"]).strip_escapes().strip_edges()
		return default_sad.strip_escapes()
	if index >= 0 and index < sads.size():
		return sads[index]
	var idx := randi_range(0, sads.size() - 1)
	return sads[idx]
			
func get_happy(cst: Customer) -> String:
	if cst and cst.dialogues and "happy" in cst.dialogues and str(cst.dialogues["happy"]).strip_edges() != "":
		return str(cst.dialogues["happy"]).strip_escapes().strip_edges()
	if cst and cst.dialogues and "happy1" in cst.dialogues and str(cst.dialogues["happy1"]).strip_edges() != "":
		return str(cst.dialogues["happy1"]).strip_escapes().strip_edges()
	return default_opening.strip_escapes()

func get_pazarlik(cst: Customer) -> String:
	var pazs = _collect_variants(cst, "pazarlik")
	if pazs.size() > 0:
		return pazs[0]
	if cst and cst.dialogues and "pazarlik" in cst.dialogues and str(cst.dialogues["pazarlik"]).strip_edges() != "":
		return str(cst.dialogues["pazarlik"]).strip_escapes().strip_edges()
	return ""
	
func get_random_opening_index(cst: Customer) -> int:
	var openings = _collect_variants(cst, "opening")
	if openings.size() == 0:
		return 0
	return randi_range(0, openings.size() - 1)

func get_random_sad_index(cst: Customer) -> int:
	var sads = _collect_variants(cst, "sad")
	if sads.size() == 0:
		return 0
	return randi_range(0, sads.size() - 1)
		
	
