extends Node

signal dimension_changed(new_dimension: String)

var current_dimension: String = "hope"

func switch_dimension():
	if current_dimension == "hope":
		current_dimension = "despair"
	else:
		current_dimension = "hope"
	emit_signal("dimension_changed", current_dimension)
