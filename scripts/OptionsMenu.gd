# OptionsMenu.gd
#######################################################
# Iestatījumu izvēlnes skripts.
# Nodrošina audio skaļuma regulēšanu un taustiņu
# pārdefinēšanu ar cilņu (tab) navigāciju.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidota iestatījumu izvēlne
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Control

signal options_closed

# Cilnes pogas
@onready var audio_tab_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/AudioTabBtn
@onready var controls_tab_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/TabButtons/ControlsTabBtn

# Cilnes konteineri
@onready var audio_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer
@onready var controls_container: ScrollContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/ControlsContainer

# Skaļuma slīdņi
@onready var master_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MasterVolume/HSlider
@onready var music_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MusicVolume/HSlider
@onready var sfx_slider: HSlider = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/SFXVolume/HSlider

# Skaļuma etiķetes
@onready var master_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MasterVolume/ValueLabel
@onready var music_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/MusicVolume/ValueLabel
@onready var sfx_value: Label = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/AudioContainer/SFXVolume/ValueLabel

# Taustiņu piesaistes konteiners
@onready var keybind_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ContentContainer/ControlsContainer/KeybindContainer

@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

# Piesaistes mainīgumi
var waiting_for_input: bool = false
var action_to_rebind: String = ""
var button_to_update: Button = null
var current_tab: String = "audio"

# Darbības, kuras var pārdefinēt
var rebindable_actions = {
	"ui_left": "Kustība pa kreisi",
	"ui_right": "Kustība pa labi",
	"ui_accept": "Lēkt",
	"dash": "Dash",
	"shift_dimension": "Mainīt dimensiju",
	"interact": "Mijiedarboties"
}

# Inicializācija - iestata cilnes, slīderus un taustiņu pogas
func _ready() -> void:
	# Savieno cilnes pogas
	audio_tab_btn.pressed.connect(_on_audio_tab_pressed)
	controls_tab_btn.pressed.connect(_on_controls_tab_pressed)
	
	# Savieno skaļuma slīderus
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	back_button.pressed.connect(_on_back_pressed)
	
	# Ielādē saglabātos iestatījumus
	_load_settings()
	
	# Iestata taustiņu pogas
	_setup_keybinds()
	
	# Sāk ar audio cilni
	_switch_tab("audio")

# Pārslēdz starp cilnēm
func _switch_tab(tab: String) -> void:
	current_tab = tab
	audio_container.visible = tab == "audio"
	controls_container.visible = tab == "controls"
	
	# Atjaunina pogu stilus
	_update_tab_button_style(audio_tab_btn, tab == "audio")
	_update_tab_button_style(controls_tab_btn, tab == "controls")

# Atjaunina cilnes pogas stilu (aktīva/neaktīva)
func _update_tab_button_style(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	else:
		button.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))

# Pārslēdzas uz audio cilni
func _on_audio_tab_pressed() -> void:
	_switch_tab("audio")

# Pārslēdzas uz vadības cilni
func _on_controls_tab_pressed() -> void:
	_switch_tab("controls")

# Ielādē saglabātos iestatījumus no konfigurācijas faila
func _load_settings() -> void:
	# Ielādē no config vai izmanto noklusējumus
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
	
	# Piemēro ielādētās vērtības
	_on_master_volume_changed(master_slider.value)
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)

# Saglabā iestatījumus konfigurācijas failā
func _save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.save("user://settings.cfg")

# Maina galveno skaļumu
func _on_master_volume_changed(value: float) -> void:
	master_value.text = str(int(value)) + "%"
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	if value == 0:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	_save_settings()

# Maina mūzikas skaļumu
func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value)) + "%"
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, value == 0)
	_save_settings()

# Maina SFX skaļumu
func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value)) + "%"
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, value == 0)
	_save_settings()

# Izveido taustiņu pārdefinēšanas pogas
func _setup_keybinds() -> void:
	# Notīra esošos
	for child in keybind_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Izveido taustiņu rindas
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

# Stilo taustiņu pogu
func _style_keybind_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))

# Iegūst darbības taustiņa nosaukumu
func _get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return event.as_text().replace("(Physical)", "").strip_edges()
	return "Nav piesaistīts"

# Izsaukts, kad taustiņu poga tiek nospiesta
func _on_keybind_button_pressed(action: String, button: Button) -> void:
	waiting_for_input = true
	action_to_rebind = action
	button_to_update = button
	button.text = "Nospiediet jebkuru taustiņu..."

# Apstrādā lietotāja ievadi taustiņu pārdefinēšanai
func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	
	if event is InputEventKey and event.pressed:
		# Noņem veco piesaisti
		var old_events = InputMap.action_get_events(action_to_rebind)
		for old_event in old_events:
			if old_event is InputEventKey:
				InputMap.action_erase_event(action_to_rebind, old_event)
		
		# Pievieno jauno piesaisti
		InputMap.action_add_event(action_to_rebind, event)
		
		# Atjaunina pogas tekstu
		button_to_update.text = event.as_text().replace("(Physical)", "").strip_edges()
		
		# Saglabā taustiņu piesaistes
		_save_keybinds()
		
		waiting_for_input = false
		action_to_rebind = ""
		button_to_update = null
		
		get_viewport().set_input_as_handled()

# Saglabā taustiņu piesaistes konfigurācijas failā
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

# Ielādē taustiņu piesaistes no konfigurācijas faila
func _load_keybinds() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	for action in rebindable_actions:
		if config.has_section_key("keybinds", action):
			var keycode = config.get_value("keybinds", action)
			
			# Noņem veco taustiņu piesaisti
			var old_events = InputMap.action_get_events(action)
			for old_event in old_events:
				if old_event is InputEventKey:
					InputMap.action_erase_event(action, old_event)
			
			# Pievieno jauno piesaisti
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			InputMap.action_add_event(action, new_event)

# Aizver iestatījumu izvēlni
func _on_back_pressed() -> void:
	_save_settings()
	emit_signal("options_closed")
	queue_free()
