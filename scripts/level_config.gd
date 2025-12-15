extends Node

# Attach this script to the root node of any level
# to configure dimension switching for that level

@export var enable_dimension_switching: bool = true

func _ready() -> void:
	var GS = get_node_or_null("/root/GameState")
	if GS:
		GS.set_dimension_switching(enable_dimension_switching)
		# Reset to Despair dimension at level start if switching is disabled
		if not enable_dimension_switching:
			GS.current_dimension = GS.Dimension.DESPAIR
