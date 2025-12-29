# MainMenu.gd
#######################################################
# Galvenās izvēlnes skripts.
# Nodrošina spēles sākšanu, saglabāto spēļu ielādi,
# iestatījumu piekļuvi un iziešanu no spēles.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.11. - Izveidota galvenā izvēlne
# Mainīts:   v1.1; 2025.12.15. - Pievienotas skaņas un animācijas
# Mainīts:   v1.2; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Control

@onready var start_button: Button = $VBoxContainer/CenterContainer/ButtonContainer/StartButton
@onready var load_button: Button = $VBoxContainer/CenterContainer/ButtonContainer/LoadButton
@onready var options_button: Button = $VBoxContainer/CenterContainer/ButtonContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/CenterContainer/ButtonContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/TitleContainer/SubtitleLabel
@onready var fade_rect: ColorRect = $FadeRect

var hover_tween: Tween
var options_menu_scene = preload("res://scenes/ui/OptionsMenu.tscn")
var save_menu_scene = preload("res://scenes/ui/SaveMenu.tscn")

# Pogu skaņas
var click_sound: AudioStreamPlayer
var press_sound: AudioStreamPlayer

# Inicializācija - iestata pogas, skaņas un animācijas
func _ready() -> void:
	# Iestata pogu skaņas
	_setup_sounds()
	
	# Savieno pogu signālus
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Savieno hover efektus
	for button in [start_button, load_button, options_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	# Iestata fade tābulu
	fade_rect.color = Color(0, 0, 0, 0)
	
	# Animē virsrakstu sākumā
	_animate_intro()

# Animē ievada elementus ar pakāpenisku parādīšanos
func _animate_intro() -> void:
	# Sāk ar neredzamiem elementiem
	title_label.modulate.a = 0
	subtitle_label.modulate.a = 0
	start_button.modulate.a = 0
	load_button.modulate.a = 0
	options_button.modulate.a = 0
	quit_button.modulate.a = 0
	
	# Pakāpeniski parāda virsrakstu
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(load_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(options_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

# Iestata skaņu atskanņotājus
func _setup_sounds() -> void:
	# Klikšķa skaņa (parastām pogām)
	click_sound = AudioStreamPlayer.new()
	click_sound.stream = preload("res://audio/sfx/click.mp3")
	click_sound.bus = "SFX"
	add_child(click_sound)
	
	# Nospiediena skaņa (tikai jaunai spēlei)
	press_sound = AudioStreamPlayer.new()
	press_sound.stream = preload("res://audio/sfx/ui-press-button-start-new-game.mp3")
	press_sound.bus = "SFX"
	add_child(press_sound)

# Atskaņo klikšķa skaņu
func _play_click() -> void:
	if click_sound:
		click_sound.play()

# Atskaņo nospiediena skaņu
func _play_press() -> void:
	if press_sound:
		press_sound.play()

# Pogas hover efekts - palielina pogu
func _on_button_hover(button: Button) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)

# Pogas unhover efekts - atgriež sākotnējo izmēru
func _on_button_unhover(button: Button) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

# Sākt spēli - pakāpeniska pāreja uz cutscene
func _on_start_pressed() -> void:
	_play_press()
	# Pāreja uz melnu, tad sāk spēli
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/ui/Cutscene.tscn")

# Atver saglabāto spēļu ielādes izvēlni
func _on_load_pressed() -> void:
	_play_click()
	var save_menu = save_menu_scene.instantiate()
	save_menu.mode = "load"
	add_child(save_menu)
	save_menu.closed.connect(_on_submenu_closed)

# Atver iestatījumu izvēlni
func _on_options_pressed() -> void:
	_play_click()
	var options_menu = options_menu_scene.instantiate()
	add_child(options_menu)
	options_menu.options_closed.connect(_on_options_closed)

# Iziet no spēles ar pakāpenisku aizvēršanu
func _on_quit_pressed() -> void:
	_play_click()
	# Pāreja uz melnu un iziet
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().quit()

func _on_options_closed() -> void:
	# Opciju izvēlne aizvērta, nekas papildus nav nepieciešams
	pass

func _on_submenu_closed() -> void:
	pass
