extends CharacterBody2D

@onready var GS: Node = get_node("/root/GameState")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Sound effects
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound
@onready var dimension_swap_sound: AudioStreamPlayer2D = $DimensionSwapSound
@onready var fade_canvas: CanvasLayer = $FadeCanvas
@onready var fade_rect: ColorRect = $FadeCanvas/FadeRect

# Death and respawn
var is_dead: bool = false
var spawn_position: Vector2 = Vector2.ZERO

#######################################################
# Player movement configuration
#######################################################
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var dash_speed: float = 500.0
@export var dash_time: float = 0.2
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Wall mechanics
@export var wall_slide_speed: float = 80.0
@export var wall_jump_velocity: Vector2 = Vector2(250, -400)
@export var wall_jump_lock_time: float = 0.15
var wall_jump_lock_timer: float = 0.0
var can_wall_jump: bool = true
var last_wall_normal: Vector2 = Vector2.ZERO

# Variable jump height
@export var jump_cut_multiplier: float = 0.5

# Corner correction
@export var corner_correction_height: float = 6.0
@export var corner_correction_push: float = 4.0

# State
var is_dashing: bool = false
var dash_timer: float = 0.0
var is_wall_sliding: bool = false
var can_dash: bool = true
var facing: int = 1

# Jump assistance
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Switch cooldown
@export var switch_cooldown: float = 0.15
var switch_cd_timer: float = 0.0

# Collision layers (adjust to your project)
const LAYER_COMMON: int  = 1 << 0   # Layer 1
const LAYER_HOPE: int    = 1 << 1   # Layer 2
const LAYER_DESPAIR: int = 1 << 2   # Layer 3

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
var is_paused: bool = false

func _ready() -> void:
	GS.dimension_changed.connect(_on_dimension_changed)
	_on_dimension_changed(GS.current_dimension)
	is_dashing = false
	is_wall_sliding = false
	# Store spawn position for respawning after death
	spawn_position = global_position
	# Fade in from black on level start
	_fade_in_on_start()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_paused:
		_open_pause_menu()

func _open_pause_menu() -> void:
	is_paused = true
	var pause_menu = pause_menu_scene.instantiate()
	pause_menu.current_level = get_tree().current_scene.scene_file_path
	get_tree().root.add_child(pause_menu)
	pause_menu.closed.connect(_on_pause_menu_closed)

func _on_pause_menu_closed() -> void:
	is_paused = false

#######################################################
# Process loop (dimension switching)
#######################################################
func _process(delta: float) -> void:
	if is_dead:
		return
	
	switch_cd_timer = max(0.0, switch_cd_timer - delta)
	if Input.is_action_just_pressed("shift_dimension") and switch_cd_timer == 0.0:
		# Only switch if enabled
		if not GS.dimension_switching_enabled:
			return
		switch_cd_timer = switch_cooldown
		GS.switch_dimension()
		# Play dimension swap sound
		if dimension_swap_sound:
			dimension_swap_sound.play()

#######################################################
# Physics loop (movement, jump, dash, wall slide)
#######################################################
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	var input_x: float = Input.get_axis("ui_left", "ui_right")
	if input_x != 0.0:
		facing = sign(input_x)

	# Apply gravity if not on floor, dashing, or wall sliding
	if not is_on_floor() and not is_dashing and not is_wall_sliding:
		velocity.y += gravity * delta

	# Coyote time and reset wall jump info on floor
	if is_on_floor():
		coyote_timer = coyote_time
		can_wall_jump = true
		last_wall_normal = Vector2.ZERO
		can_dash = true
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Wall jump lock timer
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	# Wall sliding (automatic when touching wall and falling)
	is_wall_sliding = false
	if not is_on_floor() and not is_dashing and wall_jump_lock_timer <= 0.0:
		if is_on_wall() and velocity.y > 0.0:
			is_wall_sliding = true
			velocity.y = wall_slide_speed

	# Dash logic
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
		velocity = Vector2(dash_speed * facing, velocity.y)
	else:
		velocity.x = input_x * speed

	# Jump from floor (coyote + buffer)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		can_dash = true
		# Play jump sound
		if jump_sound:
			jump_sound.play()

	# Wall jump
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
			# Play jump sound for wall jump too
			if jump_sound:
				jump_sound.play()

	# Start dash (only 1 per air sequence). Allow dash at standstill using facing.
	if Input.is_action_just_pressed("dash") and can_dash and not is_wall_sliding:
		is_dashing = true
		dash_timer = dash_time
		velocity.x = dash_speed * facing
		can_dash = false
		# Play dash sound
		if dash_sound:
			dash_sound.play()

	# Jump cut
	if not is_on_floor() and velocity.y < 0.0 and Input.is_action_just_released("ui_accept"):
		velocity.y *= jump_cut_multiplier

	# Corner correction
	_corner_correction()

	# Animations
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

	# Flip sprite
	if input_x != 0.0:
		anim.flip_h = input_x < 0.0

	# Move
	move_and_slide()

#######################################################
# Dimension reaction
#######################################################
# Accepts int OR "hope"/"despair"
func _on_dimension_changed(v: Variant) -> void:
	var dim: int = _to_dim_enum(v)
	# Update collisions: common + current layer
	if dim == GS.Dimension.HOPE:
		collision_mask = LAYER_COMMON | LAYER_HOPE
	else:
		collision_mask = LAYER_COMMON | LAYER_DESPAIR
	# Kill transient movement states to avoid cheese
	is_wall_sliding = false
	is_dashing = false
	wall_jump_lock_timer = 0.0
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	# Check if player is now stuck inside geometry
	call_deferred("_check_stuck_in_geometry")

# Check if player is stuck inside dimension tiles and try to push them out
func _check_stuck_in_geometry() -> void:
	if is_dead:
		return
	
	# Get the dimension tilemap that just became active
	var tilemap_name = "TileMap_Hope" if GS.is_hope() else "TileMap_Despair"
	var tilemap = get_tree().current_scene.get_node_or_null(tilemap_name)
	
	if tilemap == null:
		return  # No dimension tilemap found
	
	# Check if player center is inside a tile
	var player_center = global_position
	var local_pos = tilemap.to_local(player_center)
	var tile_coords = tilemap.local_to_map(local_pos)
	
	# Check the tile at player's position and nearby tiles (for player height)
	var collision_shape: CollisionShape2D = $CollisionShape2D
	var shape_height = 16.0  # Default
	if collision_shape.shape is RectangleShape2D:
		shape_height = collision_shape.shape.size.y
	elif collision_shape.shape is CapsuleShape2D:
		shape_height = collision_shape.shape.height
	
	# Check tiles at player's feet, center, and head
	var tiles_to_check = [
		tile_coords,
		tilemap.local_to_map(tilemap.to_local(player_center + Vector2(0, -shape_height / 2))),  # Head
		tilemap.local_to_map(tilemap.to_local(player_center + Vector2(0, shape_height / 2 - 2))),  # Feet (slightly up to avoid floor)
	]
	
	var is_stuck = false
	for tile_coord in tiles_to_check:
		# Check all layers of the tilemap
		for layer in range(tilemap.get_layers_count()):
			var cell_data = tilemap.get_cell_source_id(layer, tile_coord)
			if cell_data != -1:  # -1 means no tile
				is_stuck = true
				break
		if is_stuck:
			break
	
	if not is_stuck:
		return
	
	# Player is stuck! Try to push them out
	var pushed_out = _try_push_out_of_dimension_tiles(tilemap)
	
	if not pushed_out:
		# Can't find safe spot, kill the player
		die()

# Try to push player out of dimension tiles
func _try_push_out_of_dimension_tiles(tilemap: TileMap) -> bool:
	var original_pos = global_position
	
	var collision_shape: CollisionShape2D = $CollisionShape2D
	var shape_height = 16.0
	if collision_shape.shape is RectangleShape2D:
		shape_height = collision_shape.shape.size.y
	elif collision_shape.shape is CapsuleShape2D:
		shape_height = collision_shape.shape.height
	
	# Try pushing in various directions (prioritize up)
	var push_directions = [
		Vector2(0, -1),   # Up
		Vector2(-1, 0),   # Left
		Vector2(1, 0),    # Right
		Vector2(-1, -1).normalized(),  # Up-left
		Vector2(1, -1).normalized(),   # Up-right
		Vector2(0, 1),    # Down (last resort)
	]
	
	# Use small increments for tile-based levels
	for distance in range(1, 81, 1):
		for dir in push_directions:
			var test_pos = original_pos + dir * distance
			
			if _is_position_safe_in_tilemap(test_pos, tilemap, shape_height):
				global_position = test_pos
				return true
	
	return false

# Check if a position is safe (not inside dimension tiles)
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
# Helpers
#######################################################
func _to_dim_enum(v: Variant) -> int:
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_STRING:
		var s: String = String(v).to_lower()
		return GS.Dimension.HOPE if s == "hope" else GS.Dimension.DESPAIR
	return int(GS.current_dimension)

func _play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

func _get_wall_collision_normal() -> Vector2:
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c.get_normal().x != 0.0:
			return c.get_normal()
	return Vector2.ZERO

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
# Death and Respawn
#######################################################
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	velocity = Vector2.ZERO
	
	# Play death animation
	anim.play("death")
	anim.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

func _on_death_animation_finished() -> void:
	# Respawn at start position
	respawn()

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
	
	# Play idle animation after respawn
	anim.play("idle")

# Call this to set a new spawn point (e.g., at checkpoints)
func set_spawn_point(pos: Vector2) -> void:
	spawn_position = pos

# Fade in from black when level starts
func _fade_in_on_start() -> void:
	if not fade_rect:
		return
	
	# Start fully black
	fade_rect.color = Color(0, 0, 0, 1)
	fade_canvas.visible = true
	
	# Wait a frame for everything to load
	await get_tree().process_frame
	
	# Fade to transparent
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	
	fade_canvas.visible = false
