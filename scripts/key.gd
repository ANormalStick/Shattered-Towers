# key.gd
#######################################################
# Atslēgas objekta skripts.
# Ļauj spēlētājam paņemt atslēgu, kas nepieciešama
# durvju atvēršanai. Iestata arī respawn punktu.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidota atslēgu sistēma
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node2D

@onready var area: Area2D = $Key
@onready var sprite: Sprite2D = $Key/Sprite2D
@onready var collision: CollisionShape2D = $Key/CollisionShape2D
@onready var audio: AudioStreamPlayer2D = $Key/AudioStreamPlayer2D

var collected: bool = false
var player_in_area: bool = false
var player_ref: Node2D = null

# Inicializācija - savieno signālus
func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

# Apstrādā katru kadru - pārbauda mijiedarbību
func _process(_delta: float) -> void:
	if player_in_area and not collected and Input.is_action_just_pressed("interact"):
		_collect_key()

# Izsaukts, kad spēlētājs ieiet atslēgas zonā
func _on_body_entered(body: Node2D) -> void:
	# Pārbauda, vai tas ir spēlētājs
	if body is CharacterBody2D and body.has_method("die"):
		player_in_area = true
		player_ref = body

# Izsaukts, kad spēlētājs iziet no atslēgas zonas
func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_in_area = false
		player_ref = null

# Savac atslēgu - atskaņo skaņu un iestata stāvokli
func _collect_key() -> void:
	if collected or player_ref == null:
		return
	
	collected = true
	
	# Atskaņo paņemšanas skaņu
	audio.play()
	
	# Paslēpj atslēgu
	sprite.visible = false
	collision.set_deferred("disabled", true)
	
	# Iestata kontrolpunktu pie atslēgas atrašanās vietas
	if player_ref.has_method("set_spawn_point"):
		player_ref.set_spawn_point(global_position)
	
	# Paziņo GameState, ka spēlētājam ir atslēga
	var GS = get_node_or_null("/root/GameState")
	if GS:
		GS.has_key = true
	
	# Noņem atslēgu pēc skaņas beigšanās
	await audio.finished
	queue_free()
