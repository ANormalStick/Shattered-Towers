# cutscene.gd
#######################################################
# Starpscēnu (cutscene) skripts.
# Attēlo slaidu prezentāciju ar tekstu un audio,
# nodrošina pārejas starp slaidiem un uz nākamo scēnu.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.11. - Izveidota cutscene sistēma
# Mainīts:   v1.1; 2025.12.15. - Pievienots audio un uzlabojumi
# Mainīts:   v1.2; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Control

@export_file("*.tscn") var next_scene : String

var slides := [
	{
		"texture": preload("res://assets/cutscene/slide1.jpg"),
		"subtitle": "After the Split, when the world tore into light and dark, they built a tower of tests.",
		"audio": preload("res://audio/cutscene/slide1.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide2.jpg"),
		"subtitle": "The Wardens called it a trial, but it was built to make people fall.",
		"audio": preload("res://audio/cutscene/slide2.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide3.jpg"),
		"subtitle": "You saw steps no one else could see. The Wardens noticed. So they dropped you in.",
		"audio": preload("res://audio/cutscene/slide3.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide4.jpg"),
		"subtitle": "You jump. You miss. You climb again. Every reset feels like the Tower is laughing.",
		"audio": preload("res://audio/cutscene/slide4.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide5.jpg"),
		"subtitle": "Mid-fall, the other layer snaps into view—ghost platforms hanging in the dark.",
		"audio": preload("res://audio/cutscene/slide5.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide6.jpg"),
		"subtitle": "You reach for the glitch and the world splits on command. The Tower was built to watch you fall. Now it has to watch you climb.",
		"audio": preload("res://audio/cutscene/slide6.mp3"),
	},
	{
		"texture": preload("res://assets/cutscene/slide7.jpg"),
		"subtitle": "", # or "SHATTERED TOWERS"
		"audio": preload("res://audio/cutscene/slide7.mp3"),
	},
]

var current_slide : int = 0
var can_advance   : bool = false

@onready var slide_image      : TextureRect       = $SlideImage
@onready var subtitle_label   : Label             = $SubtitleContainer/PanelContainer/SubtitleLabel
@onready var subtitle_panel   : PanelContainer    = $SubtitleContainer/PanelContainer
@onready var narration_player : AudioStreamPlayer = $NarrationPlayer
@onready var fade_rect        : ColorRect         = $FadeRect

# Inicializācija - sāk ar melnu ekrānu un parāda pirmo slaidu
func _ready() -> void:
	# Sāk pilnigā melnā, pakāpeniski parādās
	fade_rect.modulate = Color(0, 0, 0, 1.0)

	narration_player.finished.connect(_on_narration_finished)
	set_process_unhandled_input(true)

	_apply_slide(0)
	_fade_in_current_slide()

# Piemēro slaidu - iestata attēlu, tekstu un audio
func _apply_slide(index: int) -> void:
	current_slide = index
	var s = slides[current_slide]

	slide_image.texture = s["texture"]
	subtitle_label.text = s["subtitle"]
	
	# Paslēpj paneli, ja nav subtitru
	subtitle_panel.visible = s["subtitle"] != ""

	narration_player.stop()
	if s["audio"] != null:
		narration_player.stream = s["audio"]
		narration_player.play()

# Pakāpeniska parādīšanās pašreizējam slaidam
func _fade_in_current_slide() -> void:
	can_advance = false
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.6)
	tween.tween_callback(Callable(self, "_enable_advance"))

# Pāreja uz nākamo slaidu ar fade efektu
func _fade_to_slide(index: int) -> void:
	can_advance = false
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Pāreja uz melnu
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	# Nomaina slaidu, kad pilnigi melns
	tween.tween_callback(Callable(self, "_apply_slide").bind(index))
	# Pakāpeniska parādīšanās
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(self, "_enable_advance"))

# Atļauj pāriet uz nākamo slaidu
func _enable_advance() -> void:
	can_advance = true

# Izsaukts, kad narrācijas audio beidzas
func _on_narration_finished() -> void:
	_next_slide()

# Apstrādā lietotāja ievadi - ļauj izlaist slaidus
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if not can_advance:
		return

	if event is InputEventMouseButton \
		or event.is_action_pressed("ui_accept") \
		or event.is_action_pressed("ui_cancel"):
		if narration_player.playing:
			narration_player.stop()
		_next_slide()

# Pāriet uz nākamo slaidu vai beidz cutscene
func _next_slide() -> void:
	if current_slide + 1 >= slides.size():
		_end_cutscene()
	else:
		_fade_to_slide(current_slide + 1)

# Beidz cutscene un pāriet uz nākamo scēnu
func _end_cutscene() -> void:
	can_advance = false
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	tween.tween_callback(Callable(self, "_really_end"))


func _really_end() -> void:
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		get_tree().quit()
