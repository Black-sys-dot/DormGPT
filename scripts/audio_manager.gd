extends Node

var track_player: AudioStreamPlayer
var walking_player: AudioStreamPlayer
var spending_player: AudioStreamPlayer

var base_track_vol: float = -5.0
var duck_amount: float = -5.0

var is_walking: bool = false
var is_spending: bool = false

func _ready() -> void:
	# Initialize players
	track_player = AudioStreamPlayer.new()
	var track_stream = load("res://sounds/track_of_game.mp3") as AudioStreamMP3
	if track_stream:
		track_stream.loop = true
	track_player.stream = track_stream
	track_player.volume_db = base_track_vol
	add_child(track_player)
	
	walking_player = AudioStreamPlayer.new()
	var walking_stream = load("res://sounds/walking.mp3") as AudioStreamMP3
	if walking_stream:
		walking_stream.loop = true
	walking_player.stream = walking_stream
	# We don't want walking sound to be too loud compared to base volumes
	walking_player.volume_db = -5.0 
	add_child(walking_player)
	
	spending_player = AudioStreamPlayer.new()
	spending_player.stream = load("res://sounds/money_spending.mp3")
	add_child(spending_player)
	
	# Start game track
	track_player.play()
	
	spending_player.finished.connect(_on_spending_finished)

func _process(delta: float) -> void:
	var target_duck = 0.0
	if is_walking or is_spending:
		target_duck = duck_amount
		
	# Smoothly interpolate volume for ducking effect
	track_player.volume_db = lerpf(track_player.volume_db, base_track_vol + target_duck, 10.0 * delta)

func set_walking(walking: bool) -> void:
	if walking and not is_walking:
		walking_player.play()
	elif not walking and is_walking:
		walking_player.stop()
	is_walking = walking

func play_spending() -> void:
	spending_player.play()
	is_spending = true

func _on_spending_finished() -> void:
	is_spending = false
