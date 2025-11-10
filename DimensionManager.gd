extends Node

@export var use_hit_stop: bool = true
@export var hit_stop_time: float = 0.06
@onready var GS: Node = get_node("/root/GameState")

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

	# Toggle arbitrary nodes via groups
	for n in get_tree().get_nodes_in_group("HopeOnly"):
		n.visible = hope
		if n is CollisionObject2D:
			n.set_deferred("collision_layer", int(hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 1)))
	for n in get_tree().get_nodes_in_group("DespairOnly"):
		n.visible = not hope
		if n is CollisionObject2D:
			n.set_deferred("collision_layer", int(not hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 2)))

	if use_hit_stop:
		_hit_stop()

func _hit_stop() -> void:
	var prev: float = Engine.time_scale
	Engine.time_scale = 0.0
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	Engine.time_scale = prev

func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)
