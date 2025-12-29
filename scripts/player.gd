# player.gd
#######################################################
# Spēlētāja kontroles un kustības skripts.
# Nodrošina spēlētāja pārvietošanos, lēkšanu, dash,
# sienas slidēšanu, dimensiju maiņu un nāves/respawn sistēmu.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Dimensiju pārslēgšana un vienreizējs dash
# Mainīts:   v1.1; 2025.10.01. - Uzsākts tutorial līmenis
# Mainīts:   v1.2; 2025.11.10. - Uzlabots Wall-jump
# Mainīts:   v1.3; 2025.11.28. - Mēģinājums labot spēlētāja kolīzijas
# Mainīts:   v1.4; 2025.12.11. - Pievienota galvenā izvēlne un cutscene
# Mainīts:   v1.5; 2025.12.15. - Pievienotas skaņas, pauzes izvēlne
# Mainīts:   v1.6; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends CharacterBody2D

@onready var GS: Node = get_node("/root/GameState")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Skaņu efekti
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var dimension_swap_sound: AudioStreamPlayer2D = $DimensionSwapSound
@onready var fade_canvas: CanvasLayer = $FadeCanvas
@onready var fade_rect: ColorRect = $FadeCanvas/FadeRect

# Lēciena skaņu variācijas
var jump_sounds: Array[AudioStream] = [
	preload("res://audio/sfx/Player-jump.mp3"),
	preload("res://audio/sfx/player-jump2.mp3"),
	preload("res://audio/sfx/Player-jump3.mp3"),
]

# Nāve un atdzimšana
var is_dead: bool = false
var spawn_position: Vector2 = Vector2.ZERO

#######################################################
# Spēlētāja kustības konfigurācija
#######################################################
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var dash_speed: float = 500.0
@export var dash_time: float = 0.2
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Sienas mehānika
@export var wall_slide_speed: float = 80.0
@export var wall_jump_velocity: Vector2 = Vector2(250, -400)
@export var wall_jump_lock_time: float = 0.15
var wall_jump_lock_timer: float = 0.0
var can_wall_jump: bool = true
var last_wall_normal: Vector2 = Vector2.ZERO

# Mainīgs lēciena augstums
@export var jump_cut_multiplier: float = 0.5

# Stūra korekcija
@export var corner_correction_height: float = 6.0
@export var corner_correction_push: float = 4.0

# Stāvoklis
var is_dashing: bool = false
var dash_timer: float = 0.0
var is_wall_sliding: bool = false
var can_dash: bool = true
var facing: int = 1

# Lēciena palīdzība (coyote time un jump buffer)
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Dimensiju maiņas atvēsināšanas laiks
@export var switch_cooldown: float = 0.15
var switch_cd_timer: float = 0.0

# Kolīziju slāņi
const LAYER_COMMON: int  = 1 << 0   # 1. slānis - kopīgais
const LAYER_HOPE: int    = 1 << 1   # 2. slānis - Hope dimensija
const LAYER_DESPAIR: int = 1 << 2   # 3. slānis - Despair dimensija

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
var game_hud_scene = preload("res://scenes/ui/GameHUD.tscn")
var is_paused: bool = false
var game_hud: CanvasLayer = null

# Inicializē spēlētāju - savieno signālus, iestata sākotnējo stāvokli
func _ready() -> void:
	GS.dimension_changed.connect(_on_dimension_changed)
	_on_dimension_changed(GS.current_dimension)
	is_dashing = false
	is_wall_sliding = false
	# Saglabā sākuma pozīciju atdzimšanai pēc nāves
	spawn_position = global_position
	# Pakāpeniski parādās no melna ekrāna līmeņa sākumā
	_fade_in_on_start()
	# Pievieno HUD
	_setup_hud()

# Apstrādā neapstrādātos ievades notikumus (pauzes izvēlne)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_paused:
		_open_pause_menu()

# Atver pauzes izvēlni un aptur spēli
func _open_pause_menu() -> void:
	is_paused = true
	var pause_menu = pause_menu_scene.instantiate()
	pause_menu.current_level = get_tree().current_scene.scene_file_path
	get_tree().root.add_child(pause_menu)
	pause_menu.closed.connect(_on_pause_menu_closed)

# Izsaukts, kad pauzes izvēlne tiek aizvērta
func _on_pause_menu_closed() -> void:
	is_paused = false

# Iestata spēles HUD (heads-up display)
func _setup_hud() -> void:
	# Pievieno HUD tikai ja tas vēl nav pievienots
	if game_hud == null:
		game_hud = game_hud_scene.instantiate()
		get_tree().root.call_deferred("add_child", game_hud)

# Iztīra resursus, kad spēlētājs tiek noņemts no koka
func _exit_tree() -> void:
	# Noņem HUD, kad spēlētājs tiek izņemts
	if game_hud and is_instance_valid(game_hud):
		game_hud.queue_free()
		game_hud = null

# Atskaņo nejaušu lēciena skaņu no pieejamajām variācijām
func _play_random_jump_sound() -> void:
	if jump_sound and not jump_sounds.is_empty():
		jump_sound.stream = jump_sounds[randi() % jump_sounds.size()]
		jump_sound.play()

#######################################################
# Procesa cikls (dimensiju pārslēgšana)
#######################################################
# Apstrādā dimensiju maiņu katru kadru
func _process(delta: float) -> void:
	if is_dead:
		return
	
	switch_cd_timer = max(0.0, switch_cd_timer - delta)
	if Input.is_action_just_pressed("shift_dimension") and switch_cd_timer == 0.0:
		# Pārslēdz tikai ja dimensiju maiņa ir iespējota
		if not GS.dimension_switching_enabled:
			return
		switch_cd_timer = switch_cooldown
		GS.switch_dimension()
		# Atskaņo dimensijas maiņas skaņu
		if dimension_swap_sound:
			dimension_swap_sound.play()

#######################################################
# Fizikas cikls (kustība, lēciens, dash, sienas slidēšana)
#######################################################
# Apstrādā spēlētāja kustību, lēcienus un citas darbības
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var input_x: float = Input.get_axis("ui_left", "ui_right")
	if input_x != 0.0:
		facing = sign(input_x)

	# Pielieto gravitāciju, ja nav uz grīdas, dashū vai sienas slidēšanā
	if not is_on_floor() and not is_dashing and not is_wall_sliding:
		velocity.y += gravity * delta

	# Coyote laiks un sienas lēciena atiestate uz grīdas
	if is_on_floor():
		coyote_timer = coyote_time
		can_wall_jump = true
		last_wall_normal = Vector2.ZERO
		can_dash = true
	else:
		coyote_timer -= delta

	# Lēciena buferis
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Sienas lēciena bloķēšanas taimeris
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	# Sienas slidēšana (automātiska, kad pieskaras sienai un krīt)
	is_wall_sliding = false
	if not is_on_floor() and not is_dashing and wall_jump_lock_timer <= 0.0:
		if is_on_wall() and velocity.y > 0.0:
			is_wall_sliding = true
			velocity.y = wall_slide_speed

	# Dash loģika
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
		velocity = Vector2(dash_speed * facing, velocity.y)
	else:
		velocity.x = input_x * speed

	# Lēciens no grīdas (coyote + buferis)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		can_dash = true
		# Atskaņo nejaušu lēciena skaņu
		_play_random_jump_sound()

	# Sienas lēciens
	elif is_wall_sliding and jump_buffer_timer > 0.0 and can_wall_jump:
		var wall_normal: Vector2 = _get_wall_collision_normal()
		if wall_normal != last_wall_normal:
			var wall_dir: int = -1 if wall_normal.x > 0.0 else 1
			velocity = Vector2(wall_jump_velocity.x * wall_dir, wall_jump_velocity.y)
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			wall_jump_lock_timer = wall_jump_lock_time
			can_wall_jump = false
			is_wall_sliding = false
			last_wall_normal = wall_normal
			can_dash = true
			# Atskaņo nejaušu lēciena skaņu arī sienas lēcienam
			_play_random_jump_sound()

	# Sāk dash (tikai 1 reizi gaisā). Atļauj dash arī stāvot uz vietas, izmantojot facing
	if Input.is_action_just_pressed("dash") and can_dash and not is_wall_sliding:
		is_dashing = true
		dash_timer = dash_time
		velocity.x = dash_speed * facing
		can_dash = false
		# Atskaņo dash skaņu
		if dash_sound:
			dash_sound.play()

	# Lēciena pārtraukšana (mainīgs lēciena augstums)
	if not is_on_floor() and velocity.y < 0.0 and Input.is_action_just_released("ui_accept"):
		velocity.y *= jump_cut_multiplier

	# Stūra korekcija
	_corner_correction()

	# Animācijas
	if is_dashing:
		_play_anim("dash")
	elif is_wall_sliding:
		_play_anim("wall_slide")
	elif not is_on_floor():
		_play_anim("jump" if velocity.y < 0.0 else "fall")
	elif input_x != 0.0:
		_play_anim("run")
	else:
		_play_anim("idle")

	# Pagriezt spritu
	if input_x != 0.0:
		anim.flip_h = input_x < 0.0

	# Pārvietoties
	move_and_slide()

#######################################################
# Dimensiju reakcija
#######################################################
# Apstrādā dimensijas maiņu - atjaunina kolīzijas un pārbauda iestrēgšanu
# Pieņem int VAI "hope"/"despair"
func _on_dimension_changed(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	# Atjaunina kolīzijas: kopīgais + pašreizējais slānis
	if dim == GS.Dimension.HOPE:
		collision_mask = LAYER_COMMON | LAYER_HOPE
	else:
		collision_mask = LAYER_COMMON | LAYER_DESPAIR
	# Atiestata pagaidu kustības stāvokļus
	is_wall_sliding = false
	is_dashing = false
	wall_jump_lock_timer = 0.0
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	# Pārbauda, vai spēlētājs ir iestrēdzis ģeometrijā
	call_deferred("_check_stuck_in_geometry")

# Pārbauda, vai spēlētājs ir iestrēdzis dimensijas flizēs un mēģina izstumšanu
func _check_stuck_in_geometry() -> void:
	if is_dead:
		return
	
	# Iegūst tikko aktivizēto dimensijas TileMap
	var tilemap_name = "TileMap_Hope" if GS.is_hope() else "TileMap_Despair"
	var tilemap = get_tree().current_scene.get_node_or_null(tilemap_name)
	
	if tilemap == null:
		return  # Nav atrasta dimensijas TileMap
	
	# Pārbauda, vai spēlētāja centrs ir flizē
	var player_center = global_position
	var local_pos = tilemap.to_local(player_center)
	var tile_coords = tilemap.local_to_map(local_pos)
	
	# Pārbauda flizi spēlētāja pozīcijā un blakus (spēlētāja augstumam)
	var collision_shape: CollisionShape2D = $CollisionShape2D
	var shape_height = 16.0  # Noklusējums
	if collision_shape.shape is RectangleShape2D:
		shape_height = collision_shape.shape.size.y
	elif collision_shape.shape is CapsuleShape2D:
		shape_height = collision_shape.shape.height
	
	# Pārbauda flizes pie spēlētāja kājām, centra un galvas
	var tiles_to_check = [
		tile_coords,
		tilemap.local_to_map(tilemap.to_local(player_center + Vector2(0, -shape_height / 2))),  # Galva
		tilemap.local_to_map(tilemap.to_local(player_center + Vector2(0, shape_height / 2 - 2))),  # Kājas
	]
	
	var is_stuck = false
	for tile_coord in tiles_to_check:
		# Pārbauda visus tilemap slāņus
		for layer in range(tilemap.get_layers_count()):
			var cell_data = tilemap.get_cell_source_id(layer, tile_coord)
			if cell_data != -1:  # -1 nozīmē nav flizes
				is_stuck = true
				break
		if is_stuck:
			break
	
	if not is_stuck:
		return
	
	# Spēlētājs ir iestrēdzis! Mēģina izstumšanu
	var pushed_out = _try_push_out_of_dimension_tiles(tilemap)
	
	if not pushed_out:
		# Nevar atrast drošu vietu, nogalina spēlētāju
		die()

# Mēģina izstum spēlētāju no dimensijas flizēm
func _try_push_out_of_dimension_tiles(tilemap: TileMap) -> bool:
	var original_pos = global_position
	
	var collision_shape: CollisionShape2D = $CollisionShape2D
	var shape_height = 16.0
	if collision_shape.shape is RectangleShape2D:
		shape_height = collision_shape.shape.size.y
	elif collision_shape.shape is CapsuleShape2D:
		shape_height = collision_shape.shape.height
	
	# Mēģina stumt dažādos virzienos (prioritāte - uz augšu)
	var push_directions = [
		Vector2(0, -1),   # Uz augšu
		Vector2(-1, 0),   # Pa kreisi
		Vector2(1, 0),    # Pa labi
		Vector2(-1, -1).normalized(),  # Uz augšu-kreisi
		Vector2(1, -1).normalized(),   # Uz augšu-labi
		Vector2(0, 1),    # Uz leju (pēdējais variants)
	]
	
	# Izmanto mazus pieaugumus flizēm balšātiem līmeņiem
	for distance in range(1, 81, 1):
		for dir in push_directions:
			var test_pos = original_pos + dir * distance
			
			if _is_position_safe_in_tilemap(test_pos, tilemap, shape_height):
				global_position = test_pos
				return true
	
	return false

# Pārbauda, vai pozīcija ir droša (nav dimensijas flizēs)
func _is_position_safe_in_tilemap(pos: Vector2, tilemap: TileMap, shape_height: float) -> bool:
	var tiles_to_check = [
		tilemap.local_to_map(tilemap.to_local(pos)),
		tilemap.local_to_map(tilemap.to_local(pos + Vector2(0, -shape_height / 2))),
		tilemap.local_to_map(tilemap.to_local(pos + Vector2(0, shape_height / 2 - 2))),
	]
	
	for tile_coord in tiles_to_check:
		for layer in range(tilemap.get_layers_count()):
			var cell_data = tilemap.get_cell_source_id(layer, tile_coord)
			if cell_data != -1:
				return false
	
	return true

#######################################################
# Palīgfunkcijas
#######################################################
# Pārveido dimensijas vērtību uz enum
func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)

# Atskaņo animāciju, ja tā vēl netiek atskaņota
func _play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

# Iegūst sienas kolīzijas normāli
func _get_wall_collision_normal() -> Vector2:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c.get_normal().x != 0.0:
			return c.get_normal()
	return Vector2.ZERO

# Stūra korekcija - ļauj spēlētājam izslīdēt gar stūriem lecot
func _corner_correction() -> void:
	if is_on_ceiling():
		var up_pos: Vector2 = global_position - Vector2(0.0, corner_correction_height)
		var left_pos: Vector2  = up_pos + Vector2(-corner_correction_push, 0.0)
		var right_pos: Vector2 = up_pos + Vector2( corner_correction_push, 0.0)

		var mask: int = collision_mask
		var left_q := PhysicsPointQueryParameters2D.new()
		left_q.position = left_pos
		left_q.collision_mask = mask
		var right_q := PhysicsPointQueryParameters2D.new()
		right_q.position = right_pos
		right_q.collision_mask = mask

		var left_hit := get_world_2d().direct_space_state.intersect_point(left_q)
		var right_hit := get_world_2d().direct_space_state.intersect_point(right_q)

		if left_hit.is_empty():
			global_position.x -= corner_correction_push
		elif right_hit.is_empty():
			global_position.x += corner_correction_push

#######################################################
# Nāve un atdzimšana
#######################################################
# Nogalina spēlētāju - atskaņo nāves animāciju
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	
	# Atskaņo nāves animāciju
	anim.play("death")
	anim.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

# Izsaukts, kad nāves animācija beidzas
func _on_death_animation_finished() -> void:
	# Atdzimšana sākuma pozīcijā
	respawn()

# Atdzimšanas funkcija - atiestata spēlētāja stāvokli
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_dead = false
	is_dashing = false
	is_wall_sliding = false
	can_dash = true
	can_wall_jump = true
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	wall_jump_lock_timer = 0.0
	
	# Atskaņo miera animāciju pēc atdzimšanas
	anim.play("idle")

# Iestata jaunu atdzimšanas punktu (piem., pie kontrolpunktiem)
func set_spawn_point(pos: Vector2) -> void:
	spawn_position = pos

# Pakāpeniski parādās no melna ekrāna līmeņa sākumā
func _fade_in_on_start() -> void:
	if not fade_rect:
		return
	
	# Sāk pilnigā melnā
	fade_rect.color = Color(0, 0, 0, 1)
	fade_canvas.visible = true
	
	# Gaida kadru, lai viss ielādējas
	await get_tree().process_frame
	
	# Pāreja uz caurspīdīgu
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	
	fade_canvas.visible = false
