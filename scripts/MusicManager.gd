# MusicManager.gd
#######################################################
# Mūzikas pārvaldnieks (Autoload).
# Nodrošina Minecraft-stila nejaušu mūzikas atskaņošanu
# ar pauzēm starp dziesmām un fade efektiem.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidota mūzikas sistēma
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node

# Minecraft-stila nejauša mūzikas sistēma
# Mūzika tiek atskaņota nejauši ar pauzēm starp dziesmam

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Mūzikas ceļiņi
var music_tracks: Array[AudioStream] = []
var track_names: Array[String] = [
	"res://audio/music/Climbing Clouds.mp3",
	"res://audio/music/Climbing Shadows.mp3",
	"res://audio/music/Pixel Trails.mp3",
	"res://audio/music/Shattered Ascent.mp3",
	"res://audio/music/Shattered Climb.mp3",
	"res://audio/music/Skyward Clouds.mp3",
	"res://audio/music/Skyward Realms.mp3",
	"res://audio/music/Skyward Steps.mp3",
	"res://audio/music/The Lament of the Tower.mp3",
	"res://audio/music/The Tower's Echo.mp3",
	"res://audio/music/Tower of Shadows.mp3",
]

# Laika iestatījumi (sekundēs)
@export var min_pause_time: float = 30.0  # Minimālais pārtraukums starp dziesmam
@export var max_pause_time: float = 120.0  # Maksimālais pārtraukums
@export var fade_duration: float = 2.0  # Fade in/out ilgums

var is_playing: bool = false
var is_fading: bool = false
var current_track_index: int = -1
var pause_timer: float = 0.0
var waiting_for_next: bool = false
var music_enabled: bool = true

# Skaļuma iestatījumi
var base_volume_db: float = -10.0  # Bāzes skaļums mūzikai (klusak nekā SFX)
var current_volume_db: float = -10.0

# Inicializācija - iestata mūzikas atskaņotāju
func _ready() -> void:
	# Pievieno mūzikas atskaņotāju kā bērnu
	add_child(music_player)
	music_player.bus = "Music"
	music_player.volume_db = base_volume_db
	
	# Savieno signālu, kad dziesma beidzas
	music_player.finished.connect(_on_music_finished)
	
	# Ielādē visus mūzikas ceļiņus
	_load_tracks()
	
	# Sāk ar garāku sākotnējo pauzi (~1 minūte pirmajai dziesmai)
	pause_timer = randf_range(50.0, 70.0)
	waiting_for_next = true

# Ielādē mūzikas ceļiņus un jauc tos
func _load_tracks() -> void:
	for track_path in track_names:
		var track = load(track_path)
		if track:
			music_tracks.append(track)
		else:
			push_warning("Failed to load music track: " + track_path)
	
	# Jauc ceļiņus
	music_tracks.shuffle()

# Apstrādā katru kadru - pārvalda pauzes taimeri
func _process(delta: float) -> void:
	if not music_enabled:
		return
	
	# Apstrādā pauzes taimeri
	if waiting_for_next:
		pause_timer -= delta
		if pause_timer <= 0:
			waiting_for_next = false
			_play_next_track()

# Sāk pauzi starp dziesmām
func _start_pause() -> void:
	waiting_for_next = true
	pause_timer = randf_range(min_pause_time, max_pause_time)

# Atskaņo nākamo ceļiņu
func _play_next_track() -> void:
	if music_tracks.is_empty():
		return
	
	# Izvēlas nejaušu ceļiņu (atšķirīgu no pašreizējā)
	var new_index = current_track_index
	if music_tracks.size() > 1:
		while new_index == current_track_index:
			new_index = randi() % music_tracks.size()
	else:
		new_index = 0
	
	current_track_index = new_index
	music_player.stream = music_tracks[current_track_index]
	
	# Pakāpeniska parādīšanās
	_fade_in()

# Pakāpeniska mūzikas parādīšanās
func _fade_in() -> void:
	is_fading = true
	music_player.volume_db = -80.0
	music_player.play()
	is_playing = true
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", base_volume_db, fade_duration)
	tween.tween_callback(func(): is_fading = false)

# Pakāpeniska mūzikas izslēgšana
func _fade_out() -> void:
	if not is_playing:
		return
	
	is_fading = true
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(_on_fade_out_complete)

# Izsaukts, kad fade out beidzas
func _on_fade_out_complete() -> void:
	music_player.stop()
	is_playing = false
	is_fading = false
	_start_pause()

# Izsaukts, kad mūzika beidzas
func _on_music_finished() -> void:
	is_playing = false
	_start_pause()

# Publiskas metodes mūzikas kontrolei
# Aptur mūziku
func stop_music() -> void:
	music_enabled = false
	waiting_for_next = false
	if is_playing:
		_fade_out()

# Sāk mūziku
func start_music() -> void:
	music_enabled = true
	if not is_playing and not waiting_for_next:
		_start_pause()

# Iestata mūzikas skaļumu (0-100%)
func set_music_volume(volume_percent: float) -> void:
	# Pārveido procentus uz dB
	if volume_percent <= 0:
		base_volume_db = -80.0
	else:
		base_volume_db = linear_to_db(volume_percent / 100.0) - 10.0
	
	if is_playing and not is_fading:
		music_player.volume_db = base_volume_db

# Izlaiž pašreizējo ceļiņu
func skip_track() -> void:
	if is_playing:
		_fade_out()
	else:
		waiting_for_next = false
		_play_next_track()
