extends GPUParticles2D

@onready var GS: Node = get_node("/root/GameState")
@export var camera_path: NodePath
var cam: Camera2D

func _ready() -> void:
	if camera_path != NodePath(): cam = get_node(camera_path)
	GS.dimension_changed.connect(_on_dim)

func _on_dim(_v: Variant) -> void:
	emitting = false
	emitting = true
	if cam and cam.has_method("add_shake"):
		cam.add_shake(6.0)
