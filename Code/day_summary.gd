extends Node2D

@onready var money_label = $VBoxContainer/MoneyLabel
@onready var rent_label = $VBoxContainer/RentLabel
@onready var needs_label = $VBoxContainer/NeedsLabel
@onready var food_label = $VBoxContainer/FoodLabel
@onready var total_label = $VBoxContainer/TotalLabel
@onready var button = $Button

const duration = 1.0
const steps = 30
const delay = duration / steps

var ready_for_exit = false

func _ready() -> void:
	print('boom')
	GameManager.time_paused = true
	GameManager.hour = 0
	button.disabled = true
	var rent = GameManager.RENT_COST
	var food = GameManager.FOOD_COST * GameManager.dogs.size()
	var needs = 20
	var total_expenses = rent + food + needs
	var final_balance = GameManager.money - total_expenses

	var summary = {
		"day": GameManager.day,
		"money": GameManager.money,
		"rent": rent,
		"food": food,
		"needs": needs,
		"total_expenses": total_expenses,
		"balance": final_balance
	}
	
	'''money_label.text = "€%s" % summary["money"] if summary['money'] >= 0 else "-€%s" % abs(summary["money"])
	rent_label.text = "-€%s" % summary["rent"]
	needs_label.text = "-€%s" % summary["needs"]
	food_label.text = "-€%s" % summary["food"] if summary['food'] < 0 else "€%s" % summary["food"]
	total_label.text = "€%s" % summary["balance"] if summary['balance'] >= 0 else "-€%s" % abs(summary["balance"])'''
	
	$SavingsLabel.text = '#%s' % summary['day']
	
	for i in range(1, steps+1):
		
		var t = float(i) / steps
		
		money_label.text = "€%s" % int(lerp(0, summary['money'], t)) if summary['money'] >= 0 else "-€%s" % abs(int(lerp(0, summary['money'], t)))
		rent_label.text = "-€%s" % int(lerp(0, summary['rent'], t))
		needs_label.text = "-€%s" % int(lerp(0, summary['needs'], t))
		food_label.text = "-€%s" % int(lerp(0, summary['food'], t)) if summary['food'] > 0 else "€%s" % int(lerp(0, summary['food'], t))
		total_label.text = "€%s" % int(lerp(0, summary['balance'], t)) if summary['balance'] >= 0 else "-€%s" % abs(int(lerp(0, summary['balance'], t)))
		
		await get_tree().create_timer(delay).timeout
		
		
	await get_tree().create_timer(1.0).timeout
	
	ready_for_exit = true
	
	button.disabled = !ready_for_exit
	
func _input(event: InputEvent) -> void:
	'''if ready_for_exit and event is InputEventKey and event.is_pressed() and not event.is_echo():
		get_tree().change_scene_to_file("res://Scenes/the_shop.tscn")
	'''

func _on_button_pressed() -> void:
	# GameManager.let_that_sink_in = false
	get_tree().change_scene_to_file("res://Scenes/the_shop.tscn")
	GameManager.day_summary_shown = false
	queue_free()
	
