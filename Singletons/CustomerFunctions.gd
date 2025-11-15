extends Node

const default_opening : String = "Hello there!"
const default_sad : String = "Ohh.. That's... sad."

func _ready() -> void:
	pass
	
func generate_customer(data: Dictionary) -> Customer:
	var customer = Customer.new()
	# var props = customer.get_property_list()
	
	for key in data.keys():
		'''for p in props:
			if p.name == key:
				customer.set(key, data[key])
				break'''
				
		if key in customer:
			customer.set(key, data[key])
	return customer
	
func get_opening(cst: Customer, index: int) -> String:
	var number : int = index+1
	var key : String = 'opening' + str(number) 
	if key in cst.dialogues:
		return cst.dialogues[key].strip_escapes()
	else:
		number = randi_range(1, 2)
		key = 'opening' + str(number)
		if key in cst.dialogues:
			return cst.dialogues[key].strip_escapes()
		else:
			key = "opening1"
			if key in cst.dialogues:
				return cst.dialogues[key].strip_escapes()
			else:
				print('default opening')
				return default_opening.strip_escapes()
				
func get_sad(cst: Customer, index: int) -> String:
	var number : int = index + 1
	var key : String = 'sad' + str(number)
	
	if key in cst.dialogues:
		return cst.dialogues[key].strip_escapes()
	else:
		key = "sad1"
		if key in cst.dialogues:
			return cst.dialogues[key].strip_escapes()
		else:
			return default_sad.strip_escapes()
			
func get_happy(cst: Customer) -> String:
	return cst.dialogues['happy'].strip_escapes()
	
func get_pazarlik(cst: Customer) -> String:
	return cst.dialogues['pazarlik'].strip_escapes()
	
func get_random_opening_index() -> int:
	return randi_range(0, 2)
	
func get_random_sad_index() -> int:
	return randi_range(0, 1)		
		
	
