# player.gd

# Autors:  Jānis Mārtiņš Īvāns
# Radīts:  v.1.0.; 2025.09.19.
# Mainīts: v.1.1.; 2025.09.21.
#   - pielikta stūra korekcija un sienas lēciena fiksācija
# Mainīts: v.1.2.; 2025.09.22.
#   - pievienotas animācijas (idle, run, jump, fall, dash, wall_slide)
# Mainīts: v.1.3.; 2025.09.24.
#   - fiksēta sienas slīdēšanas ātruma konsekvence
#   - salabota dash lietošana uz sienas slīdēšanas lai "pielīmētu" sevi pie sienas
#   - salabota "lidošana" ar dash
#   - pievienots (dimention_shift), kas ļauj mainīt spēlētāju starp dimensijām (hope/despair)
#   - spēlētājs var redzēt specifiskas platformas savai dimensijai

extends CharacterBody2D

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

# Jump assistance
@export var coyote_time: float = 0.15
@export var jump_buffer_time: float = 0.15
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Dimension switching
enum Dimension { HOPE, DESPAIR }
var current_dimension: Dimension = Dimension.DESPAIR
@onready var tilemap: TileMap = get_parent().get_node("TileMap")

# Animations
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

#######################################################
# Ready
#######################################################
func _ready() -> void:
	_update_dimension_tiles()

#######################################################
# Process loop (dimension switching)
#######################################################
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("shift_dimension"):
		_switch_dimension()

#######################################################
# Physics loop (movement, jump, dash, wall slide)
#######################################################
func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")

	# Apply gravity if not on floor, dashing, or wall sliding
	if not is_on_floor() and not is_dashing and not is_wall_sliding:
		velocity.y += gravity * delta

	# Coyote time and reset wall jump info on floor
	if is_on_floor():
		coyote_timer = coyote_time
		can_wall_jump = true
		last_wall_normal = Vector2.ZERO
		can_dash = true  # reset dash on ground
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# Wall jump lock timer
	if wall_jump_lock_timer > 0:
		wall_jump_lock_timer -= delta

	# Wall sliding (automatic when touching wall and falling)
	is_wall_sliding = false
	if not is_on_floor() and not is_dashing and wall_jump_lock_timer <= 0:
		if is_on_wall() and velocity.y > 0:
			is_wall_sliding = true
			velocity.y = wall_slide_speed

	# Dash logic
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		velocity = Vector2(dash_speed * sign(input_vector.x), velocity.y)
	elif not is_dashing:
		velocity.x = input_vector.x * speed

	# Jump from floor (coyote + buffer)
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
		can_dash = true  # reset dash on jump from floor

	# Wall jump
	elif is_wall_sliding and jump_buffer_timer > 0 and can_wall_jump:
		var wall_normal = get_wall_collision_normal()
		if wall_normal != last_wall_normal:
			var wall_dir = -1 if wall_normal.x > 0 else 1
			velocity = Vector2(wall_jump_velocity.x * wall_dir, wall_jump_velocity.y)
			jump_buffer_timer = 0
			coyote_timer = 0
			wall_jump_lock_timer = wall_jump_lock_time
			can_wall_jump = false
			is_wall_sliding = false
			last_wall_normal = wall_normal
			can_dash = true  # reset dash on wall jump

	# Start dash (only 1 per air sequence)
	if Input.is_action_just_pressed("dash") and input_vector.x != 0 and can_dash and not is_wall_sliding:
		is_dashing = true
		dash_timer = dash_time
		velocity.x = dash_speed * sign(input_vector.x)
		can_dash = false

	# Jump cut
	if not is_on_floor() and velocity.y < 0:
		if Input.is_action_just_released("ui_accept"):
			velocity.y *= jump_cut_multiplier

	# Corner correction
	_corner_correction()

	# Animations
	if is_dashing:
		_play_anim("dash")
	elif is_wall_sliding:
		_play_anim("wall_slide")
	elif not is_on_floor():
		if velocity.y < 0:
			_play_anim("jump")
		else:
			_play_anim("fall")
	elif input_vector.x != 0:
		_play_anim("run")
	else:
		_play_anim("idle")

	# Flip sprite
	if input_vector.x != 0:
		anim.flip_h = input_vector.x < 0

	# Move
	move_and_slide()

#######################################################
# Dimension switching functions
#######################################################
func _switch_dimension() -> void:
	if current_dimension == Dimension.DESPAIR:
		current_dimension = Dimension.HOPE
	else:
		current_dimension = Dimension.DESPAIR
	_update_dimension_tiles()

func _update_dimension_tiles() -> void:
	if tilemap == null:
		return
	# HopeLayer assumed to be layer 1
	tilemap.set_layer_enabled(1, current_dimension == Dimension.HOPE)

#######################################################
# Helper functions
#######################################################

func _play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

func get_wall_collision_normal() -> Vector2:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_normal().x != 0:
			return collision.get_normal()
	return Vector2.ZERO

# Corner correction function (Godot 4 safe)
func _corner_correction():
	if is_on_ceiling():
		var up_pos = global_position - Vector2(0, corner_correction_height)
		var left_pos = up_pos + Vector2(-corner_correction_push, 0)
		var right_pos = up_pos + Vector2(corner_correction_push, 0)

		var left_query = PhysicsPointQueryParameters2D.new()
		left_query.position = left_pos
		left_query.collision_mask = 1  # adjust as needed

		var right_query = PhysicsPointQueryParameters2D.new()
		right_query.position = right_pos
		right_query.collision_mask = 1

		var left_hit = get_world_2d().direct_space_state.intersect_point(left_query)
		var right_hit = get_world_2d().direct_space_state.intersect_point(right_query)

		if left_hit.size() == 0:
			global_position.x -= corner_correction_push
		elif right_hit.size() == 0:
			global_position.x += corner_correction_push
