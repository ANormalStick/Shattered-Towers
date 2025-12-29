# dimension_overlay.gd
#######################################################
# Dimensiju krāsu pārklājuma skripts.
# Pievieno krāsainu filtru ekrānam atkarībā no
# aktīvās dimensijas (Hope - silts, Despair - tumšs).
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Izveidots pārklājums
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var GS: Node = get_node("/root/GameState")

@export var transition_duration: float = 0.3

# Hope: silts, gaiss tonis (daļēji caurspīdīgs balts/dzeltens)
var hope_color: Color = Color(1.0, 0.98, 0.85, 0.12)

# Despair: tumšs violets tonis (daļēji caurspīdīgs violets)
var despair_color: Color = Color(0.3, 0.2, 0.5, 0.25)

# Inicializācija - savieno dimensiju maiņas signālu
func _ready() -> void:
	# Savieno ar dimensiju maiņu
	GS.dimension_changed.connect(_on_dimension_changed)
	
	# Iestata sākotnējo stāvokli
	var is_hope = GS.current_dimension == GS.Dimension.HOPE
	color_rect.color = hope_color if is_hope else despair_color

# Izsaukts pie dimensijas maiņas - plūstoša krāsu pāreja
func _on_dimension_changed(new_dimension: int) -> void:
	var target_color = hope_color if new_dimension == GS.Dimension.HOPE else despair_color
	
	# Plūstoša pāreja
	var tween = create_tween()
	tween.tween_property(color_rect, "color", target_color, transition_duration)
