extends Node  # Assuming DimensionManager is attached to the main node

@export var use_hit_stop: bool = false
@export var hit_stop_time: float = 0.02
@onready var GS: Node = get_node("/root/GameState")
@onready var player: CharacterBody2D = $Player  # Assuming player is a CharacterBody2D

func _ready() -> void:
	GS.dimension_changed.connect(_on_dim)
	_on_dim(GS.current_dimension)

# Accepts int OR "hope"/"despair"
func _on_dim(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	var hope: bool = (dim == GS.Dimension.HOPE)

	# Toggle TileMaps (optional, if present)
	var hope_map := get_node_or_null("TileMap_Hope")
	var despair_map := get_node_or_null("TileMap_Despair")
	if hope_map:    hope_map.visible = hope
	if despair_map: despair_map.visible = not hope

	# Toggle arbitrary nodes via groups and handle collisions properly
	for n in get_tree().get_nodes_in_group("HopeOnly"):
		n.visible = hope
		if n is CollisionObject2D:
			# Disable collision for objects not in the active dimension (Hope)
			n.set_deferred("collision_layer", int(hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 1)))
			# Optionally, disable the collision if inactive dimension
			if not hope:
				n.set_deferred("disabled", true)  # Disable collision shape

	for n in get_tree().get_nodes_in_group("DespairOnly"):
		n.visible = not hope
		if n is CollisionObject2D:
			# Disable collision for objects not in the active dimension (Despair)
			n.set_deferred("collision_layer", int(not hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 2)))
			# Optionally, disable the collision if inactive dimension
			if hope:
				n.set_deferred("disabled", true)  # Disable collision shape

	# Handle player stuck in new dimension
	_handle_player_stuck_in_block()

	if use_hit_stop:
		_hit_stop()

# Function to move the player out of any collision
func _handle_player_stuck_in_block() -> void:
	# Check if the player is stuck in a block in the new dimension
	if player.is_on_floor():  # Check if the player is on the floor
		var direction = Vector2.ZERO
		if player.is_on_wall():
			direction = Vector2.UP  # Move the player up slightly if stuck on a wall

		# If the player is stuck, move them out slightly in the opposite direction
		if direction != Vector2.ZERO:
			player.position += direction * 10  # Increase the move distance to 10 to ensure they get unstuck
			print("Player was stuck, moved out!")
	
# Simple hit stop functionality
func _hit_stop() -> void:
	var prev: float = Engine.time_scale
	Engine.time_scale = 0.0
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	Engine.time_scale = prev

# Convert the dimension input (either string or integer) to the dimension enum
func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)
