extends Node

signal money_changed(new_amount: float)

@export var starting_money: float = 50.0

var money: float = 50.0 :
	set(val):
		money = val
		money_changed.emit(money)

func _ready() -> void:
	money = starting_money

func add_money(amount: float) -> void:
	money += amount

func deduct_money(amount: float) -> bool:
	if has_enough_money(amount):
		money -= amount
		return true
	return false

func has_enough_money(amount: float) -> bool:
	return money >= amount
