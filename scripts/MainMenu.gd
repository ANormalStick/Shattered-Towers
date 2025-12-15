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

func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect hover effects
	for button in [start_button, load_button, options_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	# Setup fade rect
	fade_rect.color = Color(0, 0, 0, 0)
	
	# Animate title on start
	_animate_intro()

func _animate_intro() -> void:
	# Start with elements invisible
	title_label.modulate.a = 0
	subtitle_label.modulate.a = 0
	start_button.modulate.a = 0
	load_button.modulate.a = 0
	options_button.modulate.a = 0
	quit_button.modulate.a = 0
	
	# Fade in title
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_property(start_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(load_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(options_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(quit_button, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)

func _on_button_hover(button: Button) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)

func _on_button_unhover(button: Button) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	# Fade to black then start game
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/ui/Cutscene.tscn")

func _on_load_pressed() -> void:
	var save_menu = save_menu_scene.instantiate()
	save_menu.mode = "load"
	add_child(save_menu)
	save_menu.closed.connect(_on_submenu_closed)

func _on_options_pressed() -> void:
	var options_menu = options_menu_scene.instantiate()
	add_child(options_menu)
	options_menu.options_closed.connect(_on_options_closed)

func _on_quit_pressed() -> void:
	# Fade out and quit
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().quit()

func _on_options_closed() -> void:
	# Options menu closed, nothing special needed
	pass

func _on_submenu_closed() -> void:
	pass
