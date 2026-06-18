extends StaticBody2D

func _ready() -> void:
	# Register this table node with the UpgradeManager during gameplay
	UpgradeManager.register_table(self)
