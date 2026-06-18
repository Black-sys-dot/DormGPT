extends CharacterBody2D

@export var speed: float = 180.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: String = "down"
var nearby_interactables: Array = []

func _ready() -> void:
	# Register E key as the "interact" action programmatically if it isn't defined
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event = InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)
	
	# Start with down idle animation
	sprite.play("down_idle")

func _physics_process(_delta: float) -> void:
	# Get movement direction using WASD (mapped to ui actions by default in Godot, or keyboard events)
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# Set velocity and move
	velocity = input_dir * speed
	move_and_slide()
	
	# Update sprite animations
	update_animation(input_dir)
	
	if input_dir.length() > 0:
		AudioManager.set_walking(true)
	else:
		AudioManager.set_walking(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_with_closest()

func update_animation(direction: Vector2) -> void:
	if direction.length() > 0:
		# Determine dominant direction
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				sprite.play("right_walk")
				last_direction = "right"
			else:
				sprite.play("left_walk")
				last_direction = "left"
		else:
			if direction.y > 0:
				sprite.play("front_walk")
				last_direction = "down"
			else:
				sprite.play("back_walk")
				last_direction = "up"
	else:
		# Play idle animation based on last direction
		match last_direction:
			"left":
				sprite.play("left_idle")
			"right":
				sprite.play("right_idle")
			"up":
				sprite.play("up_idle")
			"down":
				sprite.play("down_idle")

func register_interactable(interactable) -> void:
	if not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
		update_interactable_prompts()

func unregister_interactable(interactable) -> void:
	if nearby_interactables.has(interactable):
		nearby_interactables.erase(interactable)
		update_interactable_prompts()

func update_interactable_prompts() -> void:
	# Hide all prompts first
	for item in nearby_interactables:
		if item.has_method("hide_prompt"):
			item.hide_prompt()
	
	# Show prompt for the closest one
	var closest = get_closest_interactable()
	if closest and closest.has_method("show_prompt"):
		closest.show_prompt()

func get_closest_interactable():
	if nearby_interactables.is_empty():
		return null
	
	var closest = nearby_interactables[0]
	var closest_pos = closest.get_interaction_position() if closest.has_method("get_interaction_position") else closest.global_position
	var min_dist = global_position.distance_to(closest_pos)
	for i in range(1, nearby_interactables.size()):
		var item = nearby_interactables[i]
		var item_pos = item.get_interaction_position() if item.has_method("get_interaction_position") else item.global_position
		var dist = global_position.distance_to(item_pos)
		if dist < min_dist:
			min_dist = dist
			closest = item
	return closest

func interact_with_closest() -> void:
	var closest = get_closest_interactable()
	if closest and closest.has_method("interact"):
		closest.interact()
