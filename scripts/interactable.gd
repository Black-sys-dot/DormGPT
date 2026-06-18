extends Area2D
class_name Interactable

signal interacted

@export var prompt_message: String = "[E] Interact"
@export var prompt_offset: Vector2 = Vector2(0, -25)

var label: Label
var is_player_in_range: bool = false

func _ready() -> void:
	# Configure Area2D collision monitoring
	monitoring = true
	monitorable = false
	
	# Create prompt label dynamically
	label = Label.new()
	label.text = prompt_message
	label.visible = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Create label styling for standard pixel font rendering
	var settings = LabelSettings.new()
	settings.font_size = 12
	settings.font_color = Color.WHITE
	settings.outline_color = Color.BLACK
	settings.outline_size = 3
	label.label_settings = settings
	
	add_child(label)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Simple defer to let label calculate its size for positioning
	call_deferred("align_label")

func align_label() -> void:
	if label:
		# Detect if child shapes/sprites are offset inside the Area2D
		var center_offset := Vector2.ZERO
		for child in get_children():
			if child is CollisionShape2D:
				center_offset = child.position
				break
			elif child is Sprite2D:
				center_offset = child.position
		
		label.position = center_offset + prompt_offset - Vector2(label.size.x / 2.0, label.size.y / 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("register_interactable"):
		is_player_in_range = true
		body.register_interactable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_interactable"):
		is_player_in_range = false
		body.unregister_interactable(self)
		hide_prompt()

func show_prompt() -> void:
	if label:
		align_label()
		label.visible = true

func hide_prompt() -> void:
	if label:
		label.visible = false

func interact() -> void:
	interacted.emit()

func get_interaction_position() -> Vector2:
	for child in get_children():
		if child is CollisionShape2D:
			return child.global_position
	return global_position
