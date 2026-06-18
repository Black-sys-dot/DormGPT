extends Node

signal hardware_upgraded(type: String, new_level: int)

var laptop_level: int = 1
var gpu_level: int = 1

# Upgrade costs tables
var laptop_costs: Dictionary = {
	2: 50.0,
	3: 200.0,
	4: 800.0,
	5: 2500.0
}

var gpu_costs: Dictionary = {
	2: 100.0,
	3: 400.0,
	4: 1500.0,
	5: 5000.0
}

# Container node references (NOT sprites, NOT @tool)
var laptop_tiers_node: Node
var gpu_tiers_node: Node

func register_laptop_tiers(container: Node) -> void:
	laptop_tiers_node = container
	_toggle_tiers(laptop_tiers_node, "laptop_tier_", laptop_level)

func register_gpu_tiers(container: Node) -> void:
	gpu_tiers_node = container
	_toggle_tiers(gpu_tiers_node, "gpu_tier_", gpu_level)

func meets_requirements(req_laptop: int, req_gpu: int) -> bool:
	return laptop_level >= req_laptop and gpu_level >= req_gpu

func get_laptop_upgrade_cost() -> float:
	var next_lv = laptop_level + 1
	if laptop_costs.has(next_lv):
		return laptop_costs[next_lv]
	return -1.0

func get_gpu_upgrade_cost() -> float:
	var next_lv = gpu_level + 1
	if gpu_costs.has(next_lv):
		return gpu_costs[next_lv]
	return -1.0

func can_upgrade_laptop() -> bool:
	var cost = get_laptop_upgrade_cost()
	return cost > 0 and MoneyManager.has_enough_money(cost)

func can_upgrade_gpu() -> bool:
	var cost = get_gpu_upgrade_cost()
	return cost > 0 and MoneyManager.has_enough_money(cost)

func upgrade_laptop() -> bool:
	if not can_upgrade_laptop():
		return false
	var cost = get_laptop_upgrade_cost()
	if MoneyManager.deduct_money(cost):
		laptop_level += 1
		_toggle_tiers(laptop_tiers_node, "laptop_tier_", laptop_level)
		hardware_upgraded.emit("laptop", laptop_level)
		AudioManager.play_spending()
		return true
	return false

func upgrade_gpu() -> bool:
	if not can_upgrade_gpu():
		return false
	var cost = get_gpu_upgrade_cost()
	if MoneyManager.deduct_money(cost):
		gpu_level += 1
		_toggle_tiers(gpu_tiers_node, "gpu_tier_", gpu_level)
		hardware_upgraded.emit("gpu", gpu_level)
		AudioManager.play_spending()
		return true
	return false

# Core visibility toggle: hides/disables ALL non-active children, shows/enables ONLY the matching one
func _toggle_tiers(container: Node, prefix: String, level: int) -> void:
	if not container:
		return
	
	var target_name = prefix + str(level - 1)
	
	# Loop through all tier nodes
	for child in container.get_children():
		if child.name.begins_with(prefix):
			var is_active = (child.name == target_name)
			child.visible = is_active
			
			if is_active:
				child.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				child.process_mode = Node.PROCESS_MODE_DISABLED
			
			# CRITICAL: Recursively enable/disable ALL collision shapes.
			# process_mode=DISABLED does NOT remove StaticBody2D from the physics world,
			# so hidden tiers still block the player unless we explicitly disable their shapes.
			_set_collision_shapes_recursive(child, is_active)

# Recursively enable/disable collision shapes and physics bodies in the node subtree
func _set_collision_shapes_recursive(node: Node, enabled: bool) -> void:
	if node is CollisionShape2D:
		node.disabled = not enabled
	
	# Also toggle collision layer/mask on physics bodies so they are
	# truly invisible to the physics engine when inactive
	if node is StaticBody2D or node is Area2D:
		if enabled:
			# Restore default layer/mask (layer 1)
			node.collision_layer = 1
			node.collision_mask = 1
		else:
			node.collision_layer = 0
			node.collision_mask = 0
		# For Area2D, also toggle monitoring so signals fire/stop
		if node is Area2D:
			node.monitoring = enabled
			node.monitorable = enabled
	
	for child in node.get_children():
		_set_collision_shapes_recursive(child, enabled)
