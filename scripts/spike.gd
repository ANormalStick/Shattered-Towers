# spike.gd
#######################################################
# Smailes (spike) šķēršļa skripts.
# Nogalina spēlētāju pie saskares, atskaņo animāciju
# un skaņu, pēc tam atgriežas sākotnējā stāvoklī.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.11.10. - Izveidotas smailes
# Mainīts:   v1.1; 2025.12.15. - Pievienotas skaņas
# Mainīts:   v1.2; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node2D

@onready var area: Area2D = $Spike
@onready var anim: AnimatedSprite2D = $Spike/AnimatedSprite2D
@onready var audio: AudioStreamPlayer2D = $Spike/AudioStreamPlayer2D

var triggered: bool = false

# Inicializācija - savieno signālus un iestata sākotnējo stāvokli
func _ready() -> void:
	# Savieno body_entered signālu, lai uztvertu spēlētāju
	area.body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	# Sāk ar paslēptām smailem (0. kadrs)
	anim.stop()
	anim.frame = 0

# Izsaukts, kad spēlētājs pieskaras smailēm
func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	
	# Pārbauda, vai tas ir spēlētājs (CharacterBody2D ar die metodi)
	if body is CharacterBody2D and body.has_method("die"):
		triggered = true
		# Atskaņo smailēu animāciju (tiek atskaņota vienreiz)
		anim.play("spike")
		# Atskaņo smailēu nāves skaņu
		audio.play()
		# Paziņo spēlētājam par nāvi
		body.die()

# Izsaukts, kad animācija beidzas - atiestata smailes
func _on_animation_finished() -> void:
	# Atiestata smailes pēc animācijas, lai varētu atkal aktivēties
	if anim.animation == "spike":
		triggered = false
		anim.stop()
		anim.frame = 0
