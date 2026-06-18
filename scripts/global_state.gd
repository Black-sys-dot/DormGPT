extends Node

signal money_changed(new_amount: float)
signal training_started
signal training_completed(reward_amount: float)

@export var initial_money: float = 100.0
@export var training_cost: float = 20.0
@export var training_reward: float = 35.0
@export var training_duration: float = 3.0 # seconds

var money: float = 100.0 :
	set(val):
		money = val
		money_changed.emit(money)

var is_training: bool = false

func _ready() -> void:
	money = initial_money

func can_start_training() -> bool:
	return not is_training and money >= training_cost

func start_training() -> bool:
	if not can_start_training():
		return false
	
	is_training = true
	money -= training_cost
	training_started.emit()
	return true

func complete_training() -> void:
	if not is_training:
		return
	
	is_training = false
	money += training_reward
	training_completed.emit(training_reward)
