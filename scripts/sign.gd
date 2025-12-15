extends Area2D

@export_multiline var message: String = "Sign text here"

@onready var panel: PanelContainer = $CanvasLayer/CenterContainer/PanelContainer
@onready var label: Label = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	panel.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		label.text = message
		panel.visible = true
		# Fade in
		panel.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		# Fade out
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		await tween.finished
		panel.visible = false
