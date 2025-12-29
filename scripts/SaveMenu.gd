# SaveMenu.gd
#######################################################
# Saglabāšanas/ielādes izvēlnes skripts.
# Attēlo 3 saglabāšanas slotus ar informāciju par
# līmeni un laiku, ļauj saglabāt, ielādēt un dzēst.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidota saglabāšanas izvēlne
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Control

signal closed

@export var mode: String = "save"  # "save" vai "load"
@export var current_level: String = ""

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Title
@onready var slots_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/SlotsContainer
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/BackButton

var SaveManager: Node

# Inicializācija - iestata virsrakstu un pievieno slotus
func _ready() -> void:
	SaveManager = get_node("/root/SaveManager")
	
	title_label.text = "SAGLABĀT SPĒLI" if mode == "save" else "IELĀDĒT SPĒLI"
	back_button.pressed.connect(_on_back_pressed)
	
	_populate_slots()

# Aizpilda saglabāšanas slotus
func _populate_slots() -> void:
	# Notīra esošos
	for child in slots_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var saves = SaveManager.get_all_saves()
	
	for i in range(SaveManager.MAX_SAVES):
		var slot_panel = _create_slot_panel(i, saves[i])
		slots_container.add_child(slot_panel)

# Izveido saglabāšanas slota paneli
func _create_slot_panel(slot: int, save_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 80)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.3, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var slot_label = Label.new()
	slot_label.add_theme_font_size_override("font_size", 22)
	slot_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	
	var detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 16)
	detail_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	
	if save_data.is_empty():
		slot_label.text = "Slots " + str(slot + 1) + " - Tukšs"
		detail_label.text = "Nav saglabāto datu"
	else:
		var level_name = SaveManager.get_level_display_name(save_data.get("level", ""))
		slot_label.text = "Slot " + str(slot + 1) + " - " + level_name
		detail_label.text = save_data.get("timestamp", "Unknown date")
	
	info_vbox.add_child(slot_label)
	info_vbox.add_child(detail_label)
	
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	hbox.add_child(button_container)
	
	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(100, 40)
	action_button.add_theme_font_size_override("font_size", 16)
	action_button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.12, 0.22)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.5, 0.45, 0.35)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	action_button.add_theme_stylebox_override("normal", btn_style)
	
	if mode == "save":
		action_button.text = "Saglabāt"
		action_button.pressed.connect(_on_save_slot.bind(slot))
	else:
		action_button.text = "Ielādēt"
		action_button.disabled = save_data.is_empty()
		if not save_data.is_empty():
			action_button.pressed.connect(_on_load_slot.bind(slot))
	
	button_container.add_child(action_button)
	
	# Dzēšanas poga (rāda tikai ja saglabāšana eksistē)
	if not save_data.is_empty():
		var delete_button = Button.new()
		delete_button.custom_minimum_size = Vector2(80, 40)
		delete_button.text = "Dzēst"
		delete_button.add_theme_font_size_override("font_size", 14)
		delete_button.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		
		var del_style = StyleBoxFlat.new()
		del_style.bg_color = Color(0.2, 0.1, 0.1)
		del_style.border_width_left = 1
		del_style.border_width_top = 1
		del_style.border_width_right = 1
		del_style.border_width_bottom = 1
		del_style.border_color = Color(0.5, 0.3, 0.3)
		del_style.corner_radius_top_left = 6
		del_style.corner_radius_top_right = 6
		del_style.corner_radius_bottom_right = 6
		del_style.corner_radius_bottom_left = 6
		delete_button.add_theme_stylebox_override("normal", del_style)
		delete_button.pressed.connect(_on_delete_slot.bind(slot))
		button_container.add_child(delete_button)
	
	return panel

# Saglabā spēli norādītajā slotā
func _on_save_slot(slot: int) -> void:
	if current_level.is_empty():
		# Mēģina iegūt pašreizējo scēnu
		current_level = get_tree().current_scene.scene_file_path
	
	SaveManager.save_game(slot, current_level)
	_populate_slots()

# Ielādē spēli no norādītā slota
func _on_load_slot(slot: int) -> void:
	var save_data = SaveManager.load_game(slot)
	if save_data.is_empty():
		return
	
	var level = save_data.get("level", "")
	if level.is_empty():
		return
	
	# Atjauno dimensijas stāvokli
	if save_data.has("dimension"):
		GameState.current_dimension = save_data.dimension
	
	get_tree().paused = false
	get_tree().change_scene_to_file(level)

# Dzēš saglabāšanu no norādītā slota
func _on_delete_slot(slot: int) -> void:
	SaveManager.delete_save(slot)
	_populate_slots()

func _on_back_pressed() -> void:
	emit_signal("closed")
	queue_free()
