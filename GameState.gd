extends Node

signal dimension_changed(new_dimension: int)

enum Dimension { HOPE, DESPAIR }
var current_dimension: int = Dimension.DESPAIR

func switch_dimension():
	current_dimension = Dimension.HOPE if current_dimension == Dimension.DESPAIR else Dimension.DESPAIR
	emit_signal("dimension_changed", current_dimension)

func is_hope() -> bool:
	return current_dimension == Dimension.HOPE
