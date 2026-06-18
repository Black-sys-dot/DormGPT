extends Node

signal active_model_changed(new_model_idx: int)
signal training_started(model_idx: int, duration: float)
signal training_progress_updated(percent: float)
signal training_completed(model_idx: int)

@export var training_duration: float = 5.0 # configurable, default 5 seconds

# Define exactly the 10 models with their income, training cost, and hardware requirements
var models: Array = [
	{ "name": "TinyGPT", "income": 1.0, "cost": 0.0, "req_laptop": 1, "req_gpu": 1 },
	{ "name": "MiniGPT", "income": 3.0, "cost": 20.0, "req_laptop": 2, "req_gpu": 1 },
	{ "name": "PicoGPT", "income": 7.0, "cost": 60.0, "req_laptop": 1, "req_gpu": 2 },
	{ "name": "NanoGPT", "income": 15.0, "cost": 150.0, "req_laptop": 3, "req_gpu": 1 },
	{ "name": "BaseGPT", "income": 30.0, "cost": 350.0, "req_laptop": 1, "req_gpu": 3 },
	{ "name": "SmartGPT", "income": 55.0, "cost": 700.0, "req_laptop": 4, "req_gpu": 1 },
	{ "name": "UltraGPT", "income": 90.0, "cost": 1400.0, "req_laptop": 1, "req_gpu": 4 },
	{ "name": "MegaGPT", "income": 140.0, "cost": 2800.0, "req_laptop": 5, "req_gpu": 1 },
	{ "name": "OmniGPT", "income": 210.0, "cost": 5500.0, "req_laptop": 1, "req_gpu": 5 },
	{ "name": "AGI-X", "income": 300.0, "cost": 10000.0, "req_laptop": 5, "req_gpu": 5 }
]

var active_model_idx: int = -1 :
	set(val):
		active_model_idx = val
		active_model_changed.emit(active_model_idx)

var is_training: bool = false
var training_timer: float = 0.0
var target_model_idx: int = -1
var passive_timer: Timer

func _ready() -> void:
	# Setup passive income timer (ticks every 1.0 second)
	passive_timer = Timer.new()
	passive_timer.wait_time = 1.0
	passive_timer.autostart = true
	passive_timer.timeout.connect(_on_passive_income_tick)
	add_child(passive_timer)

func _process(delta: float) -> void:
	if is_training:
		training_timer += delta
		var percent = clamp((training_timer / training_duration) * 100.0, 0.0, 100.0)
		training_progress_updated.emit(percent)
		
		if training_timer >= training_duration:
			complete_training()

func _on_passive_income_tick() -> void:
	if active_model_idx >= 0 and active_model_idx < models.size():
		var income = models[active_model_idx]["income"]
		MoneyManager.add_money(income)

func start_training(model_idx: int) -> bool:
	if is_training:
		return false
	if model_idx < 0 or model_idx >= models.size():
		return false
	
	var model = models[model_idx]
	
	# Verify hardware requirements using UpgradeManager
	if not UpgradeManager.meets_requirements(model["req_laptop"], model["req_gpu"]):
		return false
		
	# Verify money and deduct
	if not MoneyManager.deduct_money(model["cost"]):
		return false
	
	is_training = true
	training_timer = 0.0
	target_model_idx = model_idx
	AudioManager.play_spending()
	training_started.emit(model_idx, training_duration)
	return true

func complete_training() -> void:
	if not is_training:
		return
	
	is_training = false
	active_model_idx = target_model_idx
	training_completed.emit(active_model_idx)
	target_model_idx = -1
