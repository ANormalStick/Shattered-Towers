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

func _ready() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# Pause the game
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	emit_signal("closed")
	queue_free()

func _on_save_pressed() -> void:
	var save_menu = save_menu_scene.instantiate()
	save_menu.mode = "save"
	save_menu.current_level = current_level
	control.add_child(save_menu)
	save_menu.closed.connect(_on_submenu_closed)

func _on_options_pressed() -> void:
	var options_menu = options_menu_scene.instantiate()
	control.add_child(options_menu)
	options_menu.options_closed.connect(_on_submenu_closed)

func _on_submenu_closed() -> void:
	pass

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
