extends CharacterBody2D

@onready var GS: Node = get_node("/root/GameState")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

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
@export var switch_cooldown: float = 0.35
var switch_cd_timer: float = 0.0

# Collision layers (adjust to your project)
const LAYER_COMMON: int  = 1 << 0   # Layer 1
const LAYER_HOPE: int    = 1 << 1   # Layer 2
const LAYER_DESPAIR: int = 1 << 2   # Layer 3

func _ready() -> void:
	GS.dimension_changed.connect(_on_dimension_changed)
	_on_dimension_changed(GS.current_dimension)
	is_dashing = false
	is_wall_sliding = false

#######################################################
# Process loop (dimension switching)
#######################################################
func _process(delta: float) -> void:
	switch_cd_timer = max(0.0, switch_cd_timer - delta)
	if Input.is_action_just_pressed("shift_dimension") and switch_cd_timer == 0.0:
		switch_cd_timer = switch_cooldown
		GS.switch_dimension()

#######################################################
# Physics loop (movement, jump, dash, wall slide)
#######################################################
func _physics_process(delta: float) -> void:
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

	# Start dash (only 1 per air sequence). Allow dash at standstill using facing.
	if Input.is_action_just_pressed("dash") and can_dash and not is_wall_sliding:
		is_dashing = true
		dash_timer = dash_time
		velocity.x = dash_speed * facing
		can_dash = false

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
