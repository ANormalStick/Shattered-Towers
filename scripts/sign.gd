# sign.gd
#######################################################
# Zīmes (sign) objekta skripts.
# Attēlo teksta ziņojumu, kad spēlētājs tuvojas,
# ar fade-in/fade-out animāciju.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.10.01. - Izveidotas zīmes tutorial līmenī
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Area2D

@export_multiline var message: String = "Sign text here"

@onready var panel: PanelContainer = $CanvasLayer/CenterContainer/PanelContainer
@onready var label: Label = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/Label

# Inicializācija - savieno signālus
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	panel.visible = false

# Izsaukts, kad spēlētājs tuvojas zīmei - parāda tekstu
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		label.text = message
		panel.visible = true
		# Pakāpeniska parādīšanās
		panel.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)

# Izsaukts, kad spēlētājs atstāj zīmes zonu - paslēpj tekstu
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		# Pakāpeniska izzūdēšana
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.2)
		await tween.finished
		panel.visible = false
