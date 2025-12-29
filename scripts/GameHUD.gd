# GameHUD.gd
#######################################################
# Spēles HUD (Heads-Up Display) skripts.
# Attēlo spēlētāja atslēgas statusu ekrānā.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidots HUD
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends CanvasLayer

@onready var key_container: HBoxContainer = $Control/MarginContainer/KeyContainer
@onready var key_icon: TextureRect = $Control/MarginContainer/KeyContainer/KeyIcon
@onready var key_label: Label = $Control/MarginContainer/KeyContainer/KeyLabel

var has_key_texture: Texture2D
var no_key_texture: Texture2D

# Inicializācija - ielādē tekstūras un savieno ar GameState
func _ready() -> void:
	# Ielādē atslēgas tekstūras
	has_key_texture = preload("res://assets/map/pixel_art_keys/key_small1.png")
	
	# Savieno ar GameState signālu
	var GS = get_node_or_null("/root/GameState")
	if GS:
		# Pārbauda sākotnējo stāvokli
		_update_key_display(GS.has_key)
	
	# Atjaunina attēlojumu (gadījumā ja signāls ir palaists garām)
	_update_key_display(false)

# Apstrādā katru kadru - pārbauda atslēgas statusu
func _process(_delta: float) -> void:
	# Aptauja GameState par atslēgas statusu
	var GS = get_node_or_null("/root/GameState")
	if GS:
		_update_key_display(GS.has_key)

# Atjaunina atslēgas attēlojumu HUD
func _update_key_display(has_key: bool) -> void:
	if has_key:
		key_icon.modulate = Color(1, 1, 1, 1)  # Pilnā krāsa
		key_label.text = "Atslēga"
		key_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))  # Zelta
	else:
		key_icon.modulate = Color(0.3, 0.3, 0.3, 0.5)  # Pelēka
		key_label.text = "Nav atslēgas"
		key_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))  # Pelēka
