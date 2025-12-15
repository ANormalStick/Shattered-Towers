extends Node

const SAVE_PATH = "user://saves/"
const MAX_SAVES = 3

func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_PATH)

func save_game(slot: int, level_path: String) -> bool:
	var save_data = {
		"slot": slot,
		"level": level_path,
		"timestamp": Time.get_datetime_string_from_system(),
		"dimension": GameState.current_dimension
	}
	
	var file_path = SAVE_PATH + "save_" + str(slot) + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to save game: " + str(FileAccess.get_open_error()))
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return true

func load_game(slot: int) -> Dictionary:
	var file_path = SAVE_PATH + "save_" + str(slot) + ".json"
	
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse save file")
		return {}
	
	return json.data

func get_all_saves() -> Array:
	var saves = []
	for i in range(MAX_SAVES):
		var save_data = load_game(i)
		saves.append(save_data)
	return saves

func delete_save(slot: int) -> void:
	var file_path = SAVE_PATH + "save_" + str(slot) + ".json"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

func has_any_save() -> bool:
	for i in range(MAX_SAVES):
		var file_path = SAVE_PATH + "save_" + str(i) + ".json"
		if FileAccess.file_exists(file_path):
			return true
	return false

func get_level_display_name(level_path: String) -> String:
	match level_path:
		"res://scenes/levels/level_1.tscn":
			return "Level 1 - The Beginning"
		"res://scenes/levels/level_2.tscn":
			return "Level 2 - Dimensions"
		"res://scenes/levels/level_end.tscn":
			return "Final Level"
		"res://scenes/levels/level_tutorial.tscn":
			return "Tutorial"
		_:
			return level_path.get_file().replace(".tscn", "").capitalize()
