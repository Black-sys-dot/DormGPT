extends Node2D

@onready var ui: Control = $CanvasLayer/GameUI

func _ready() -> void:
	# Register the tier containers with UpgradeManager
	UpgradeManager.register_laptop_tiers($laptop_tiers)
	UpgradeManager.register_gpu_tiers($gpu_tiers)

	# Dynamically connect all GPU tier interactables
	for tier in $gpu_tiers.get_children():
		for child in tier.get_children():
			if child is Area2D and child.has_signal("interacted"):
				child.interacted.connect(_on_gpu_interacted)

func _on_laptop_interacted() -> void:
	ui.open_training_ui()

func _on_table_interacted() -> void:
	ui.open_laptop_upgrade_ui()

func _on_gpu_interacted() -> void:
	ui.open_gpu_upgrade_ui()
