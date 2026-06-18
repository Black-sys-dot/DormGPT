extends Control

@onready var money_hud_label: Label = $HUD/MoneyLabel
@onready var popup: Panel = $LaptopPopup
@onready var train_button: Button = $LaptopPopup/VBox/HBox/TrainButton
@onready var close_button: Button = $LaptopPopup/VBox/HBox/CloseButton
@onready var upgrade_laptop_button: Button = $LaptopPopup/VBox/HBox/UpgradeLaptopButton
@onready var progress_bar: ProgressBar = $LaptopPopup/VBox/ProgressBar
@onready var status_label: Label = $LaptopPopup/VBox/StatusLabel

# Dynamic HUD elements
var model_hud_label: Label
var income_hud_label: Label

# Dynamic Training Popup labels
var lbl_current_model: Label
var lbl_current_income: Label
var lbl_next_model: Label
var lbl_training_cost: Label
var lbl_requirements: Label

# Dynamic Upgrade Popup
var upgrade_popup: Panel
var upgrade_title: Label
var upgrade_level_info: Label
var upgrade_cost_info: Label
var upgrade_status: Label
var upgrade_btn: Button
var upgrade_close_btn: Button

# Upgrade state
var current_upgrade_type: String = ""

func _ready() -> void:
	# Reset container layout to full-rect and centered
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	
	# Instantiate extra HUD readouts dynamically so we don't disrupt your scene file
	model_hud_label = Label.new()
	model_hud_label.text = "Model: None"
	model_hud_label.position = Vector2(30, 70)
	model_hud_label.label_settings = money_hud_label.label_settings
	$HUD.add_child(model_hud_label)
	
	income_hud_label = Label.new()
	income_hud_label.text = "Income: $0/sec"
	income_hud_label.position = Vector2(30, 110)
	income_hud_label.label_settings = money_hud_label.label_settings
	$HUD.add_child(income_hud_label)
	
	# Instantiate instruction labels dynamically on the right side of the HUD
	var movement_hud_label = Label.new()
	movement_hud_label.text = "Movement: W, A, S, D"
	movement_hud_label.label_settings = money_hud_label.label_settings
	movement_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	movement_hud_label.anchor_left = 1.0
	movement_hud_label.anchor_right = 1.0
	movement_hud_label.offset_left = -500
	movement_hud_label.offset_right = -30
	movement_hud_label.offset_top = 30
	movement_hud_label.offset_bottom = 70
	$HUD.add_child(movement_hud_label)
	
	var interact_hud_label = Label.new()
	interact_hud_label.text = "Interact: E (Laptop/GPU)"
	interact_hud_label.label_settings = money_hud_label.label_settings
	interact_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	interact_hud_label.anchor_left = 1.0
	interact_hud_label.anchor_right = 1.0
	interact_hud_label.offset_left = -500
	interact_hud_label.offset_right = -30
	interact_hud_label.offset_top = 70
	interact_hud_label.offset_bottom = 110
	$HUD.add_child(interact_hud_label)
	
	# Clear out the obsolete placeholder labels from LaptopPopup VBox
	var vbox = $LaptopPopup/VBox
	if vbox.has_node("MoneyLabel"):
		vbox.get_node("MoneyLabel").queue_free()
	if vbox.has_node("CostLabel"):
		vbox.get_node("CostLabel").queue_free()
	
	# Create our detailed training labels dynamically
	var label_settings = $LaptopPopup/VBox/TitleLabel.label_settings.duplicate()
	label_settings.font_size = 15
	
	lbl_current_model = Label.new()
	lbl_current_model.label_settings = label_settings
	vbox.add_child(lbl_current_model)
	vbox.move_child(lbl_current_model, 2)
	
	lbl_current_income = Label.new()
	lbl_current_income.label_settings = label_settings
	vbox.add_child(lbl_current_income)
	vbox.move_child(lbl_current_income, 3)
	
	lbl_next_model = Label.new()
	lbl_next_model.label_settings = label_settings
	vbox.add_child(lbl_next_model)
	vbox.move_child(lbl_next_model, 4)
	
	lbl_training_cost = Label.new()
	lbl_training_cost.label_settings = label_settings
	vbox.add_child(lbl_training_cost)
	vbox.move_child(lbl_training_cost, 5)
	
	lbl_requirements = Label.new()
	lbl_requirements.label_settings = label_settings
	vbox.add_child(lbl_requirements)
	vbox.move_child(lbl_requirements, 6)
	
	# Dynamically setup the Hardware Upgrade popup panel
	setup_upgrade_popup()
	
	# Connect to all manager signals
	MoneyManager.money_changed.connect(_on_money_changed)
	ModelManager.active_model_changed.connect(_on_active_model_changed)
	ModelManager.training_started.connect(_on_training_started)
	ModelManager.training_progress_updated.connect(_on_training_progress)
	ModelManager.training_completed.connect(_on_training_completed)
	
	# Bind buttons
	train_button.pressed.connect(_on_train_pressed)
	close_button.pressed.connect(func(): popup.visible = false)
	upgrade_laptop_button.pressed.connect(open_laptop_upgrade_ui)
	
	# Initial updates
	update_hud()
	popup.visible = false
	progress_bar.visible = false

func setup_upgrade_popup() -> void:
	upgrade_popup = Panel.new()
	upgrade_popup.custom_minimum_size = Vector2(400, 320)
	upgrade_popup.name = "UpgradePopup"
	upgrade_popup.visible = false
	
	# Center it inside the viewport
	upgrade_popup.anchors_preset = PRESET_CENTER
	upgrade_popup.anchor_left = 0.5
	upgrade_popup.anchor_top = 0.5
	upgrade_popup.anchor_right = 0.5
	upgrade_popup.anchor_bottom = 0.5
	upgrade_popup.offset_left = -200
	upgrade_popup.offset_top = -160
	upgrade_popup.offset_right = 200
	upgrade_popup.offset_bottom = 160
	
	var panel_style = popup.get_theme_stylebox("panel")
	if panel_style:
		upgrade_popup.add_theme_stylebox_override("panel", panel_style)
		
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = PRESET_FULL_RECT
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 25
	vbox.offset_top = 25
	vbox.offset_right = -25
	vbox.offset_bottom = -25
	vbox.add_theme_constant_override("separation", 15)
	upgrade_popup.add_child(vbox)
	
	upgrade_title = Label.new()
	upgrade_title.text = "HARDWARE UPGRADE"
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_title.label_settings = $LaptopPopup/VBox/TitleLabel.label_settings
	vbox.add_child(upgrade_title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	upgrade_level_info = Label.new()
	upgrade_level_info.label_settings = lbl_current_model.label_settings
	vbox.add_child(upgrade_level_info)
	
	upgrade_cost_info = Label.new()
	upgrade_cost_info.label_settings = lbl_current_model.label_settings
	vbox.add_child(upgrade_cost_info)
	
	upgrade_status = Label.new()
	upgrade_status.text = ""
	upgrade_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_status.label_settings = status_label.label_settings
	vbox.add_child(upgrade_status)
	
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(spacer2)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var btn_normal = train_button.get_theme_stylebox("normal")
	var btn_hover = train_button.get_theme_stylebox("hover")
	var btn_pressed = train_button.get_theme_stylebox("pressed")
	var btn_disabled = train_button.get_theme_stylebox("disabled")
	
	upgrade_btn = Button.new()
	upgrade_btn.custom_minimum_size = Vector2(130, 42)
	upgrade_btn.text = "Upgrade"
	if btn_normal: upgrade_btn.add_theme_stylebox_override("normal", btn_normal)
	if btn_hover: upgrade_btn.add_theme_stylebox_override("hover", btn_hover)
	if btn_pressed: upgrade_btn.add_theme_stylebox_override("pressed", btn_pressed)
	if btn_disabled: upgrade_btn.add_theme_stylebox_override("disabled", btn_disabled)
	hbox.add_child(upgrade_btn)
	
	upgrade_close_btn = Button.new()
	upgrade_close_btn.custom_minimum_size = Vector2(130, 42)
	upgrade_close_btn.text = "Close"
	if btn_normal: upgrade_close_btn.add_theme_stylebox_override("normal", btn_normal)
	if btn_hover: upgrade_close_btn.add_theme_stylebox_override("hover", btn_hover)
	if btn_pressed: upgrade_close_btn.add_theme_stylebox_override("pressed", btn_pressed)
	hbox.add_child(upgrade_close_btn)
	
	add_child(upgrade_popup)
	
	upgrade_btn.pressed.connect(_on_upgrade_confirm_pressed)
	upgrade_close_btn.pressed.connect(func(): upgrade_popup.visible = false)

func update_hud() -> void:
	money_hud_label.text = "Money: $" + str(MoneyManager.money)
	
	var active_idx = ModelManager.active_model_idx
	if active_idx == -1:
		model_hud_label.text = "Model: None"
		income_hud_label.text = "Income: $0/sec"
	else:
		var model = ModelManager.models[active_idx]
		model_hud_label.text = "Model: " + model["name"]
		income_hud_label.text = "Income: $" + str(model["income"]) + "/sec"

func open_training_ui() -> void:
	upgrade_popup.visible = false
	popup.visible = true
	update_training_popup_details()

func update_training_popup_details() -> void:
	if ModelManager.is_training:
		lbl_current_model.text = "Current Model: Training..."
		lbl_current_income.text = "Current Income: --"
		lbl_next_model.text = "Next Model: --"
		lbl_training_cost.text = "Training Cost: --"
		lbl_requirements.text = "Requirements: --"
		train_button.disabled = true
		status_label.text = "Training..."
		progress_bar.visible = true
		return
	
	progress_bar.visible = false
	var active_idx = ModelManager.active_model_idx
	
	if active_idx == -1:
		lbl_current_model.text = "Current Model: None"
		lbl_current_income.text = "Current Income: $0/sec"
	else:
		var current_model = ModelManager.models[active_idx]
		lbl_current_model.text = "Current Model: " + current_model["name"]
		lbl_current_income.text = "Current Income: $" + str(current_model["income"]) + "/sec"
	
	var next_idx = active_idx + 1
	if next_idx >= ModelManager.models.size():
		lbl_next_model.text = "Next Model: Maxed Out"
		lbl_training_cost.text = "Training Cost: --"
		lbl_requirements.text = "Requirements: --"
		train_button.disabled = true
		status_label.text = "All AI models trained!"
	else:
		var next_model = ModelManager.models[next_idx]
		lbl_next_model.text = "Next Model: " + next_model["name"]
		lbl_training_cost.text = "Training Cost: " + ("Free" if next_model["cost"] == 0.0 else "$" + str(next_model["cost"]))
		
		# Build requirements
		var reqs = []
		if next_model["req_laptop"] > 1:
			reqs.append("Laptop Lv %d" % next_model["req_laptop"])
		if next_model["req_gpu"] > 1:
			reqs.append("GPU Lv %d" % next_model["req_gpu"])
		
		var req_str = "None"
		if reqs.size() > 0:
			req_str = ", ".join(reqs)
		lbl_requirements.text = "Requirements: " + req_str
		
		# Check requirements and funds
		var meets_hw = UpgradeManager.meets_requirements(next_model["req_laptop"], next_model["req_gpu"])
		if not meets_hw:
			train_button.disabled = true
			status_label.text = "Required hardware: " + req_str
		else:
			train_button.disabled = false
			status_label.text = "System: Ready"

func open_laptop_upgrade_ui() -> void:
	popup.visible = false
	upgrade_popup.visible = true
	current_upgrade_type = "laptop"
	update_upgrade_popup_details()

func open_gpu_upgrade_ui() -> void:
	popup.visible = false
	upgrade_popup.visible = true
	current_upgrade_type = "gpu"
	update_upgrade_popup_details()

func update_upgrade_popup_details() -> void:
	upgrade_status.text = ""
	
	if current_upgrade_type == "laptop":
		upgrade_title.text = "LAPTOP UPGRADE"
		var current_lv = UpgradeManager.laptop_level
		var next_lv = current_lv + 1
		var cost = UpgradeManager.get_laptop_upgrade_cost()
		
		upgrade_level_info.text = "Current Level: %d" % current_lv
		if cost > 0:
			upgrade_level_info.text += " -> Next Level: %d" % next_lv
			upgrade_cost_info.text = "Upgrade Cost: $%d" % cost
			upgrade_btn.disabled = false
			upgrade_btn.text = "Upgrade Laptop"
		else:
			upgrade_level_info.text += " (MAX)"
			upgrade_cost_info.text = "Upgrade Cost: --"
			upgrade_btn.disabled = true
			upgrade_btn.text = "Maxed Out"
			
	elif current_upgrade_type == "gpu":
		upgrade_title.text = "GPU UPGRADE"
		var current_lv = UpgradeManager.gpu_level
		var next_lv = current_lv + 1
		var cost = UpgradeManager.get_gpu_upgrade_cost()
		
		upgrade_level_info.text = "Current Level: %d" % current_lv
		if cost > 0:
			upgrade_level_info.text += " -> Next Level: %d" % next_lv
			upgrade_cost_info.text = "Upgrade Cost: $%d" % cost
			upgrade_btn.disabled = false
			upgrade_btn.text = "Upgrade GPU"
		else:
			upgrade_level_info.text += " (MAX)"
			upgrade_cost_info.text = "Upgrade Cost: --"
			upgrade_btn.disabled = true
			upgrade_btn.text = "Maxed Out"

func _on_train_pressed() -> void:
	var next_idx = ModelManager.active_model_idx + 1
	if next_idx >= ModelManager.models.size():
		return
	
	var cost = ModelManager.models[next_idx]["cost"]
	if not MoneyManager.has_enough_money(cost):
		status_label.text = "Not enough money."
		return
		
	var _ok = ModelManager.start_training(next_idx)

func _on_upgrade_confirm_pressed() -> void:
	if current_upgrade_type == "laptop":
		var cost = UpgradeManager.get_laptop_upgrade_cost()
		if cost > 0:
			if MoneyManager.has_enough_money(cost):
				if UpgradeManager.upgrade_laptop():
					update_upgrade_popup_details()
					upgrade_status.text = "Laptop upgraded successfully!"
			else:
				upgrade_status.text = "Not enough money."
				
	elif current_upgrade_type == "gpu":
		var cost = UpgradeManager.get_gpu_upgrade_cost()
		if cost > 0:
			if MoneyManager.has_enough_money(cost):
				if UpgradeManager.upgrade_gpu():
					update_upgrade_popup_details()
					upgrade_status.text = "GPU upgraded successfully!"
			else:
				upgrade_status.text = "Not enough money."
	update_hud()

func _on_money_changed(_new_money: float) -> void:
	update_hud()
	if popup.visible:
		update_training_popup_details()
	if upgrade_popup.visible:
		update_upgrade_popup_details()

func _on_active_model_changed(_model_idx: int) -> void:
	update_hud()
	if popup.visible:
		update_training_popup_details()

func _on_training_started(_model_idx: int, _duration: float) -> void:
	progress_bar.visible = true
	progress_bar.value = 0.0
	train_button.disabled = true
	status_label.text = "Training..."
	update_training_popup_details()

func _on_training_progress(percent: float) -> void:
	progress_bar.value = percent
	status_label.text = "Training... %d%%" % int(percent)

func _on_training_completed(_model_idx: int) -> void:
	progress_bar.visible = false
	status_label.text = "Model Training Complete"
	update_training_popup_details()
	update_hud()
