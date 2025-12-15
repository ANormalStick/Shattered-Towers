extends Node2D

@onready var area: Area2D = $Key
@onready var sprite: Sprite2D = $Key/Sprite2D
@onready var collision: CollisionShape2D = $Key/CollisionShape2D
@onready var audio: AudioStreamPlayer2D = $Key/AudioStreamPlayer2D

var collected: bool = false
var player_in_area: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_area and not collected and Input.is_action_just_pressed("interact"):
		_collect_key()

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player
	if body is CharacterBody2D and body.has_method("die"):
		player_in_area = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_in_area = false
		player_ref = null

func _collect_key() -> void:
	if collected or player_ref == null:
		return
	
	collected = true
	
	# Play pickup sound
	audio.play()
	
	# Hide the key
	sprite.visible = false
	collision.set_deferred("disabled", true)
	
	# Set checkpoint at key location
	if player_ref.has_method("set_spawn_point"):
		player_ref.set_spawn_point(global_position)
	
	# Tell GameState player has the key
	var GS = get_node_or_null("/root/GameState")
	if GS:
		GS.has_key = true
	
	# Remove key after sound finishes
	await audio.finished
	queue_free()
