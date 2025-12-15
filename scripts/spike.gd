extends Node2D

@onready var area: Area2D = $Spike
@onready var anim: AnimatedSprite2D = $Spike/AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $Spike/AudioStreamPlayer2D

var triggered: bool = false

func _ready() -> void:
	# Connect the body_entered signal to detect player
	area.body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	# Start with spikes hidden (frame 0 of spike animation)
	anim.stop()
	anim.frame = 0

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	# Check if it's the player (CharacterBody2D with die method)
	if body is CharacterBody2D and body.has_method("die"):
		triggered = true
		# Play spike animation (plays once)
		anim.play("spike")
		# Play spike death sound
		audio.play()
		# Tell the player to die
		body.die()

func _on_animation_finished() -> void:
	# Reset spike after animation completes so it can trigger again
	if anim.animation == "spike":
		triggered = false
		anim.stop()
		anim.frame = 0
