# PauseMenu.gd
#######################################################
# Pauzes izvēlnes skripts.
# Ļauj apturēt spēli, saglabāt, mainīt iestatījumus
# vai atgriezties galvenajā izvēlnē.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidota pauzes izvēlne
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends CanvasLayer

signal closed

@onready var control: Control = $Control
@onready var resume_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/ResumeButton
@onready var save_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var options_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/OptionsButton
@onready var main_menu_button: Button = $Control/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer/MainMenuButton

var options_menu_scene = preload("res://scenes/ui/OptionsMenu.tscn")
var save_menu_scene = preload("res://scenes/ui/SaveMenu.tscn")
var current_level: String = ""

# Pogas skaņas
var click_sound: AudioStreamPlayer

# Inicializācija - iestata pogas un aptur spēli
func _ready() -> void:
	# Iestata pogu skaņas
	_setup_sounds()
	
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Aptur spēli
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

# Iestata skaņu atskanņotājus
func _setup_sounds() -> void:
	# Klikšķa skaņa
	click_sound = AudioStreamPlayer.new()
	click_sound.stream = preload("res://audio/sfx/click.mp3")
	click_sound.bus = "SFX"
	add_child(click_sound)

# Atskaņo klikšķa skaņu
func _play_click() -> void:
	if click_sound:
		click_sound.play()

# Apstrādā ESC taustiņu pauzes izvēlnē
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

# Turpina spēli - aizver pauzes izvēlni
func _on_resume_pressed() -> void:
	_play_click()
	get_tree().paused = false
	emit_signal("closed")
	queue_free()

# Atver saglabāšanas izvēlni
func _on_save_pressed() -> void:
	_play_click()
	var save_menu = save_menu_scene.instantiate()
	save_menu.mode = "save"
	save_menu.current_level = current_level
	control.add_child(save_menu)
	save_menu.closed.connect(_on_submenu_closed)

# Atver iestatījumu izvēlni
func _on_options_pressed() -> void:
	_play_click()
	var options_menu = options_menu_scene.instantiate()
	control.add_child(options_menu)
	options_menu.options_closed.connect(_on_submenu_closed)

# Izsaukts, kad apaizvērta iekšējā izvēlne
func _on_submenu_closed() -> void:
	pass

# Atgriežas galvenajā izvēlnē
func _on_main_menu_pressed() -> void:
	_play_click()
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
