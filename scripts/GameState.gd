extends Node

signal dimension_changed(new_dimension: int)

enum Dimension { HOPE, DESPAIR }
var current_dimension: int = Dimension.DESPAIR

# Key/Door system
var has_key: bool = false

# Dimension switching control
var dimension_switching_enabled: bool = true

func switch_dimension():
	if not dimension_switching_enabled:
		return
	current_dimension = Dimension.HOPE if current_dimension == Dimension.DESPAIR else Dimension.DESPAIR
	emit_signal("dimension_changed", current_dimension)

func is_hope() -> bool:
	return current_dimension == Dimension.HOPE

# Call this when loading a new level to reset key state
func reset_level_state() -> void:
	has_key = false

# Enable or disable dimension switching (for level 1)
func set_dimension_switching(enabled: bool) -> void:
	dimension_switching_enabled = enabled
