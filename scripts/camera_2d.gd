# camera_2d.gd
#######################################################
# Kameras skripts ar zoom funkcionalitāti.
# Nodrošina plūstošu kameras tuvināšanu un tālināšanu
# ar peles riteni vai taustiņiem.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.10.01. - Izveidota kamera
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Camera2D

@export var decay: float = 10.0

# Tuvināšanas iestatījumi
@export var zoom_step: float = 0.1
@export var min_zoom: float = 2.5
@export var max_zoom: float = 3.5
@export var zoom_lerp: float = 12.0

var target_zoom: Vector2

# Inicializācija - iestata sākotnējo tuvinājumu
func _ready() -> void:
	target_zoom = zoom

# Apstrādā katru kadru - tuvināšanas kontrole
func _process(delta: float) -> void:

	# Tuvināšana ar peles riteni vai taustiņiem
	if Input.is_action_just_pressed("zoom_in"):
		_change_zoom(-zoom_step)
	if Input.is_action_just_pressed("zoom_out"):
		_change_zoom(zoom_step)

	# Plūstoša tuvināšana
	zoom = zoom.lerp(target_zoom, clamp(zoom_lerp * delta, 0.0, 1.0))

# Maina tuvinājumu norādītajā solī
func _change_zoom(step: float) -> void:
	target_zoom = Vector2(
		clamp(target_zoom.x + step, min_zoom, max_zoom),
		clamp(target_zoom.y + step, min_zoom, max_zoom)
	)
