# DimensionManager.gd
#######################################################
# Dimensiju pārvaldības skripts līmeņa objektiem.
# Pārvalda TileMap un objektu redzamību un kolīzijas
# atkarībā no aktīvās dimensijas (Hope/Despair).
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Dimensiju pārslēgšana
# Mainīts:   v1.1; 2025.09.24. - Uzlabojums dimensiju kodam
# Mainīts:   v1.2; 2025.11.28. - Labota kolīziju pārvaldība
# Mainīts:   v1.3; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node  # DimensionManager tiek pievienots galvenajam līmeņa mezglam

@export var use_hit_stop: bool = false
@export var hit_stop_time: float = 0.02
@onready var GS: Node = get_node("/root/GameState")
@onready var player: CharacterBody2D = $Player

# Inicializācija - savieno dimensiju mainīt signālu
func _ready() -> void:
	GS.dimension_changed.connect(_on_dim)
	_on_dim(GS.current_dimension)

# Apstrādā dimensijas maiņu - piemēro redzamību un kolīzijas
# Pieņem int VAI "hope"/"despair"
func _on_dim(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	var hope: bool = (dim == GS.Dimension.HOPE)

	# Pārslēdz TileMap redzamību (ja ir pieejams)
	var hope_map := get_node_or_null("TileMap_Hope")
	var despair_map := get_node_or_null("TileMap_Despair")
	if hope_map:    hope_map.visible = hope
	if despair_map: despair_map.visible = not hope

	# Pārslēdz objektus pa grupām un apstrādā kolīzijas
	for n in get_tree().get_nodes_in_group("HopeOnly"):
		n.visible = hope
		if n is CollisionObject2D:
			# Atslēdz kolīziju objektiem, kas nav aktīvajā dimensijā
			n.set_deferred("collision_layer", int(hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 1)))
			if not hope:
				n.set_deferred("disabled", true)

	for n in get_tree().get_nodes_in_group("DespairOnly"):
		n.visible = not hope
		if n is CollisionObject2D:
			# Atslēdz kolīziju objektiem, kas nav aktīvajā dimensijā
			n.set_deferred("collision_layer", int(not hope) * (n.collision_layer if n.collision_layer != 0 else (1 << 2)))
			if hope:
				n.set_deferred("disabled", true)

	# Apstrādā gadījumu, kad spēlētājs ir iestrēdzis jaunā dimensijā
	_handle_player_stuck_in_block()

	if use_hit_stop:
		_hit_stop()

# Pārvieto spēlētāju ārā no kolīzijas, ja iestrēdzis
func _handle_player_stuck_in_block() -> void:
	# Pārbauda, vai spēlētājs ir iestrēdzis blokā jaunajā dimensijā
	if player.is_on_floor():
		var direction = Vector2.ZERO
		if player.is_on_wall():
			direction = Vector2.UP  # Pārvieto spēlētāju nedaudz uz augšu

		# Ja spēlētājs ir iestrēdzis, pārvieto pretejā virzienā
		if direction != Vector2.ZERO:
			player.position += direction * 10
			print("Spēlētājs bija iestrēdzis, pārvietots!")
	
# Vienkrša hit-stop funkcionalitāte dimensiju maiņai
func _hit_stop() -> void:
	var prev: float = Engine.time_scale
	Engine.time_scale = 0.0
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	Engine.time_scale = prev

# Pārveido dimensijas ievadi (virkni vai skaitli) uz enum
func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)
