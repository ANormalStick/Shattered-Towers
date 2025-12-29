# SwapVFX.gd
#######################################################
# Dimensiju maiņas vizuālā efekta skripts.
# Atskaņo daļiņu efektu, kad notiek dimensijas maiņa.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Izveidots VFX efekts
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends GPUParticles2D

@onready var GS: Node = get_node("/root/GameState")
@export var camera_path: NodePath
var cam: Camera2D

# Inicializācija - savieno dimensiju signālu
func _ready() -> void:
	if camera_path != NodePath(): cam = get_node(camera_path)
	GS.dimension_changed.connect(_on_dim)

# Izsaukts pie dimensijas maiņas - atskaņo daļiņu efektu
func _on_dim(_v: Variant) -> void:
	emitting = false
	emitting = true
