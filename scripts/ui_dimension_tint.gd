# ui_dimension_tint.gd
#######################################################
# UI dimensiju toņa skripts ar shader atbalstu.
# Pārvalda shader parametrus atkarībā no dimensijas.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Izveidots shader tonis
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends ColorRect

@onready var mat: ShaderMaterial = material
@onready var GS: Node = get_node("/root/GameState")

# Inicializācija - savieno dimensiju signālu
func _ready() -> void:
	GS.dimension_changed.connect(_on_dim)
	_on_dim(GS.current_dimension)

# Apstrādā dimensijas maiņu - atjaunina shader parametrus
# Pieņem int VAI "hope"/"despair"
func _on_dim(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	if mat:
		mat.set_shader_parameter("is_hope", dim == GS.Dimension.HOPE)

# Pārveido dimensijas vērtību uz enum
func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)
