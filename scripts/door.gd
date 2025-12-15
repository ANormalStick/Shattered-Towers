extends Node2D

@onready var area: Area2D = $Door
@onready var anim: AnimatedSprite2D = $Door/AnimatedSprite2D
@onready var door_audio: AudioStreamPlayer2D = $Door/AudioStreamPlayer2D
@onready var stairs_audio: AudioStreamPlayer2D = $Door/StairsAudio
@onready var fade_rect: ColorRect = $FadeRect

@export var next_level: String = ""  # e.g., "res://level_2.tscn"

var is_open: bool = false
var player_in_door: bool = false
var player_ref: Node2D = null
var transitioning: bool = false
var message_label: Label = null

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	anim.animation_finished.connect(_on_animation_finished)
	
	# Start on frame 0 (closed door)
	anim.stop()
	anim.frame = 0
	
	# Initialize fade rect (fully transparent)
	if fade_rect:
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.visible = true
	
	# Create message label for "Key Required"
	_create_message_label()

func _create_message_label() -> void:
	message_label = Label.new()
	message_label.text = "Key Required"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(1, 0.8, 0.5, 1))
	message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	message_label.add_theme_constant_override("outline_size", 3)
	message_label.position = Vector2(-50, -70)
	message_label.size = Vector2(100, 30)
	message_label.modulate.a = 0.0
	add_child(message_label)

func _process(_delta: float) -> void:
	if not player_in_door or transitioning:
		return
	
	if Input.is_action_just_pressed("interact"):
		if not is_open:
			_try_open_door()
		else:
			_enter_door()

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body is CharacterBody2D and body.has_method("die"):
		player_in_door = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_in_door = false
		player_ref = null

func _try_open_door() -> void:
	if is_open:
		return
	
	var GS = get_node_or_null("/root/GameState")
	if GS and GS.has_key:
		is_open = true
		GS.has_key = false  # Use the key
		
		# Play door opening animation and sound
		door_audio.play()
		anim.play("Door")
	else:
		# Show "Key Required" message
		_show_key_required_message()

func _show_key_required_message() -> void:
	if message_label:
		var tween = create_tween()
		tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
		tween.tween_interval(1.5)
		tween.tween_property(message_label, "modulate:a", 0.0, 0.5)

func _enter_door() -> void:
	if not is_open or transitioning:
		return
	
	transitioning = true
	
	# Disable player movement
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process(false)
		player_ref.velocity = Vector2.ZERO
	
	# Fade to black
	await _fade_to_black(0.5)
	
	# Play stairs sound
	if stairs_audio:
		stairs_audio.play()
		await stairs_audio.finished
	
	# Transition to next level
	if next_level != "":
		get_tree().change_scene_to_file(next_level)

func _fade_to_black(duration: float) -> void:
	if not fade_rect:
		return
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

func _on_animation_finished() -> void:
	pass  # Door stays open after animation
