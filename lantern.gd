extends PointLight2D

@export var hope_scale: float = 3.0
@export var hope_energy: float = 1.35
@export var hope_color: Color = Color(1.0, 0.97, 0.90, 1.0)

@export var despair_scale: float = 2.2
@export var despair_energy: float = 1.0
@export var despair_color: Color = Color(0.90, 0.95, 1.0, 1.0)

@export var use_zoom_compensation: bool = false
@export var camera_group: String = "main_camera"
var _cam: Camera2D

@onready var GS: Node = get_node("/root/GameState")

func _ready() -> void:
	# circular (radial) light texture
	texture = _make_radial_light_texture(256, 1.8)
	texture_scale = despair_scale
	energy = despair_energy
	color = despair_color

	shadow_enabled = true
	shadow_filter = PointLight2D.SHADOW_FILTER_PCF13 # or PCF5

	if GS.has_signal("dimension_changed"):
		GS.dimension_changed.connect(_on_dimension_changed)
	_on_dimension_changed(GS.current_dimension)

	if use_zoom_compensation:
		_cam = get_tree().get_first_node_in_group(camera_group) as Camera2D

func _process(_delta: float) -> void:
	if use_zoom_compensation and _cam:
		scale = Vector2.ONE / _cam.zoom

func _on_dimension_changed(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	if dim == GS.Dimension.HOPE:
		color = hope_color
		energy = hope_energy
		texture_scale = hope_scale
	else:
		color = despair_color
		energy = despair_energy
		texture_scale = despair_scale

func pulse(scale_add: float = 0.6, energy_add: float = 0.3, time: float = 0.15) -> void:
	var start_scale := texture_scale
	var start_energy := energy
	var tw := create_tween()
	tw.tween_property(self, "texture_scale", start_scale + scale_add, time)
	tw.parallel().tween_property(self, "energy", start_energy + energy_add, time)
	tw.tween_property(self, "texture_scale", start_scale, time)
	tw.parallel().tween_property(self, "energy", start_energy, time)

func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)

# --- circular alpha falloff texture (Godot 4: no lock/unlock) ---
func _make_radial_light_texture(size: int = 256, softness_power: float = 1.6) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	var cx: float = float(size - 1) * 0.5
	var cy: float = float(size - 1) * 0.5
	var max_r: float = max(cx, cy)

	for y in range(size):
		for x in range(size):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var r: float = sqrt(dx * dx + dy * dy) / max_r   # 0 center → 1 edge
			var a: float = clamp(1.0 - r, 0.0, 1.0)
			a = pow(a, softness_power)                        # soften edge
			img.set_pixel(x, y, Color(1, 1, 1, a))

	return ImageTexture.create_from_image(img)
