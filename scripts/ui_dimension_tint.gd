extends ColorRect

@onready var mat: ShaderMaterial = material
@onready var GS: Node = get_node("/root/GameState")

func _ready() -> void:
	GS.dimension_changed.connect(_on_dim)
	_on_dim(GS.current_dimension)

# Accepts int OR "hope"/"despair"
func _on_dim(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	if mat:
		mat.set_shader_parameter("is_hope", dim == GS.Dimension.HOPE)

func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)
