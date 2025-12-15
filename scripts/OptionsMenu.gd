extends Control

signal options_closed

# Tab buttons
@onready var audio_tab_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/AudioTabBtn
@onready var controls_tab_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/ControlsTabBtn

# Tab containers
@onready var audio_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer
@onready var controls_container: ScrollContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/ControlsContainer

# Volume sliders
@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/SFXVolume/HSlider

# Volume labels
@onready var master_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MasterVolume/ValueLabel
@onready var music_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MusicVolume/ValueLabel
@onready var sfx_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/SFXVolume/ValueLabel

# Keybind container
@onready var keybind_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/ControlsContainer/KeybindContainer

@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

# For rebinding
var waiting_for_input: bool = false
var action_to_rebind: String = ""
var button_to_update: Button = null
var current_tab: String = "audio"

# Actions that can be rebound
var rebindable_actions = {
	"ui_left": "Move Left",
	"ui_right": "Move Right",
	"ui_accept": "Jump",
	"dash": "Dash",
	"shift_dimension": "Switch Dimension",
	"interact": "Interact"
}

func _ready() -> void:
	# Connect tab buttons
	audio_tab_btn.pressed.connect(_on_audio_tab_pressed)
	controls_tab_btn.pressed.connect(_on_controls_tab_pressed)
	
	# Connect volume sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	back_button.pressed.connect(_on_back_pressed)
	
	# Load saved settings
	_load_settings()
	
	# Setup keybind buttons
	_setup_keybinds()
	
	# Start on audio tab
	_switch_tab("audio")

func _switch_tab(tab: String) -> void:
	current_tab = tab
	audio_container.visible = tab == "audio"
	controls_container.visible = tab == "controls"
	
	# Update button styles
	_update_tab_button_style(audio_tab_btn, tab == "audio")
	_update_tab_button_style(controls_tab_btn, tab == "controls")

func _update_tab_button_style(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	else:
		button.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))

func _on_audio_tab_pressed() -> void:
	_switch_tab("audio")

func _on_controls_tab_pressed() -> void:
	_switch_tab("controls")

func _load_settings() -> void:
	# Load from config or use defaults
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		master_slider.value = config.get_value("audio", "master", 100)
		music_slider.value = config.get_value("audio", "music", 100)
		sfx_slider.value = config.get_value("audio", "sfx", 100)
	else:
		master_slider.value = 100
		music_slider.value = 100
		sfx_slider.value = 100
	
	# Apply loaded values
	_on_master_volume_changed(master_slider.value)
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)

func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.save("user://settings.cfg")

func _on_master_volume_changed(value: float) -> void:
	master_value.text = str(int(value)) + "%"
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	if value == 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	_save_settings()

func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, value == 0)
	_save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, value == 0)
	_save_settings()

func _setup_keybinds() -> void:
	# Clear existing
	for child in keybind_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create keybind rows
	for action in rebindable_actions:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label = Label.new()
		label.text = rebindable_actions[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 40)
		button.text = _get_action_key_name(action)
		button.pressed.connect(_on_keybind_button_pressed.bind(action, button))
		_style_keybind_button(button)
		
		row.add_child(label)
		row.add_child(button)
		keybind_container.add_child(row)

func _style_keybind_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))

func _get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return event.as_text().replace("(Physical)", "").strip_edges()
	return "Unbound"

func _on_keybind_button_pressed(action: String, button: Button) -> void:
	waiting_for_input = true
	action_to_rebind = action
	button_to_update = button
	button.text = "Press any key..."

func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	
	if event is InputEventKey and event.pressed:
		# Remove old binding
		var old_events = InputMap.action_get_events(action_to_rebind)
		for old_event in old_events:
			if old_event is InputEventKey:
				InputMap.action_erase_event(action_to_rebind, old_event)
		
		# Add new binding
		InputMap.action_add_event(action_to_rebind, event)
		
		# Update button text
		button_to_update.text = event.as_text().replace("(Physical)", "").strip_edges()
		
		# Save keybind
		_save_keybinds()
		
		waiting_for_input = false
		action_to_rebind = ""
		button_to_update = null
		
		get_viewport().set_input_as_handled()

func _save_keybinds() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	
	for action in rebindable_actions:
		var events = InputMap.action_get_events(action)
		for event in events:
			if event is InputEventKey:
				config.set_value("keybinds", action, event.physical_keycode)
				break
	
	config.save("user://settings.cfg")

func _load_keybinds() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	for action in rebindable_actions:
		if config.has_section_key("keybinds", action):
			var keycode = config.get_value("keybinds", action)
			
			# Remove old key events
			var old_events = InputMap.action_get_events(action)
			for old_event in old_events:
				if old_event is InputEventKey:
					InputMap.action_erase_event(action, old_event)
			
			# Add new binding
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			InputMap.action_add_event(action, new_event)

func _on_back_pressed() -> void:
	_save_settings()
	emit_signal("options_closed")
	queue_free()
