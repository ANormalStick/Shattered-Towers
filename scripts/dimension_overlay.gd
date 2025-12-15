extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var GS: Node = get_node("/root/GameState")

@export var transition_duration: float = 0.3

# Hope: warm bright tint (semi-transparent white/yellow)
var hope_color: Color = Color(1.0, 0.98, 0.85, 0.12)

# Despair: dark purple tint (semi-transparent purple)
var despair_color: Color = Color(0.3, 0.2, 0.5, 0.25)

func _ready() -> void:
	# Connect to dimension changes
	GS.dimension_changed.connect(_on_dimension_changed)
	
	# Set initial state
	var is_hope = GS.current_dimension == GS.Dimension.HOPE
	color_rect.color = hope_color if is_hope else despair_color

func _on_dimension_changed(new_dimension: int) -> void:
	var target_color = hope_color if new_dimension == GS.Dimension.HOPE else despair_color
	
	# Smooth transition
	var tween = create_tween()
	tween.tween_property(color_rect, "color", target_color, transition_duration)
