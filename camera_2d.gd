extends Camera2D

@export var decay: float = 10.0

# Zoom settings
@export var zoom_step: float = 0.1
@export var min_zoom: float = 2.5
@export var max_zoom: float = 3.5
@export var zoom_lerp: float = 12.0

var target_zoom: Vector2

func _ready() -> void:
	target_zoom = zoom

func _process(delta: float) -> void:

	# Zoom with scroll
	if Input.is_action_just_pressed("zoom_in"):
		_change_zoom(-zoom_step)
	if Input.is_action_just_pressed("zoom_out"):
		_change_zoom(zoom_step)

	# Smooth zoom
	zoom = zoom.lerp(target_zoom, clamp(zoom_lerp * delta, 0.0, 1.0))

func _change_zoom(step: float) -> void:
	target_zoom = Vector2(
		clamp(target_zoom.x + step, min_zoom, max_zoom),
		clamp(target_zoom.y + step, min_zoom, max_zoom)
	)
