extends StaticBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DEFAULT_GROUNDED_HEIGHT = 0.01
const DEFAULT_MAX_WALK_ANGLE = 60

const MAX_BOUNCES:int = 5

const BUFFER_SHOVE_RADIANS:float = PI
const MAX_SHOVE_RADIANS:float = PI/2
const EPSILON:float = 0.001

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Direction of up vector
var up:Vector3 = Vector3.UP

# Velocity due to world forces (like gravity)
var world_velocity:Vector3 = Vector3.ZERO

# Velocity due to plaeyr input (movement)
var move_velocity:Vector3 = Vector3.ZERO

# Mouse sensitivity
var mouse_sensibility = 1200

# Allow player movement
var allow_movement:bool = true

# Grounded configuration
var grounded_dist = DEFAULT_GROUNDED_HEIGHT
var max_walk_angle = DEFAULT_MAX_WALK_ANGLE

# Grounded state
var _ground_hit:bool = false
var _ground_object:Object = null
var _ground_dist:float = 0
var _ground_angle:float = 0
var _ground_normal:Vector3 = Vector3.ZERO
var _ground_position:Vector3 = Vector3.ZERO

# Internal variable for computing collisions
var _collision:KinematicCollision3D

@onready var cam = $Head/Camera3d as Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	allow_movement = true
	_collision = KinematicCollision3D.new();

func _physics_process(_delta) -> void:
	# Add the gravity.
	check_grounded()
	if not is_on_floor() or is_sliding():
		world_velocity -= up * gravity * _delta
	elif is_on_floor() and !moving_up():
		# If player is not moving up and hit the ground, stop world velocity
		world_velocity = Vector3.ZERO

	# If we allow input, let the player jump and move.
	var direction = Vector3(0, 0, 0)
	if allow_movement:
		# Handle Jump.
		var jumping := Input.is_action_just_pressed("Jump")
		if jumping and is_on_floor():
			world_velocity = up * JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom
		# gameplay actions.
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
		direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		direction = direction.normalized()

	if direction:
		move_velocity.x = direction.x * SPEED
		move_velocity.z = direction.z * SPEED
	else:
		move_velocity.x = move_toward(move_velocity.x, 0, SPEED)
		move_velocity.z = move_toward(move_velocity.z, 0, SPEED)

	var move:Vector3 = move_velocity
	if is_on_floor() and not is_sliding():
		move *= Quaternion(_ground_normal, up)

	move_and_slide(move * _delta)
	move_and_slide(world_velocity * _delta)


func _input(event) -> void:
	# On web platform, mouse needs to be clicked in order to be
	# captured properly. Or as a direct input response like pressing a key.
	if OS.get_name() == "Web":
		if event is InputEventMouseButton:
			allow_movement = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("Exit"):
		# Set mouse to captured mode on input form player
		# This needs to be done in _input for web support
		allow_movement = !allow_movement
		capture_mouse()

	if event is InputEventMouseMotion:
		# Only rotate player if input is allowed
		# Adjust rotation based on player input
		if allow_movement:
			rotation.y -= event.relative.x / mouse_sensibility
			$Head/Camera3d.rotation.x -= event.relative.y / mouse_sensibility
			$Head/Camera3d.rotation.x = clamp($Head/Camera3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func check_grounded() -> bool:
	_ground_hit = test_move(global_transform, Vector3.DOWN * grounded_dist, _collision, EPSILON)
	if _ground_hit:
		_ground_object = _collision.get_collider()
		_ground_dist = _collision.get_travel().length()
		_ground_angle = _collision.get_normal().angle_to(up)
		_ground_normal = _collision.get_normal()
		_ground_position = _collision.get_position()
		return is_on_floor()

	_ground_object = null
	_ground_dist = 0
	_ground_angle = 0
	_ground_normal = Vector3.ZERO
	_ground_position = Vector3.ZERO
	return false

func moving_up() -> bool:
	return world_velocity.dot(up) > 0

func is_on_floor() -> bool:
	return _ground_hit and _ground_dist <= grounded_dist

func is_sliding() -> bool:
	return is_on_floor() and _ground_angle > deg_to_rad(max_walk_angle)

func move_and_slide(movement:Vector3) -> void:
	var bounce:int = 0;
	var remaining:Vector3 = movement;
	var start:Transform3D = global_transform

	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Check if player collides with anything due to bounce
		var hit:bool = test_move(start, remaining, _collision, EPSILON)
		if not hit:
			global_position = start.origin + remaining
			return

		# Move player by distance traveled if colliding
		start.origin += _collision.get_travel()
		var remaining_dist:float = _collision.get_remainder().length()

		# Get angle between surface normal and remaining movement
		var angle_between:float = _collision.get_normal().angle_to(remaining)

		# Normalize angle between to be between 0 and 1
		var normalized_angle:float = clamp( \
			abs(angle_between - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)

		# Reduce the remaining movement by the remaining movement that ocurred
		remaining_dist *= pow(normalized_angle, 0.5)

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(_collision.get_normal()).project(_collision.get_remainder()).normalized() * remaining_dist

		# If the player is sliding up a wall, stop it
		# Can check if dot to up vector is almost equal to 0 (perpendicular)
		if is_on_floor() and not moving_up() and abs(_collision.get_normal().dot(up)) <= EPSILON:
			# Remove vertical component of remaining movement
			var up_component := Vector3(up.x * remaining.x, up.y * remaining.y, up.z * remaining.z)
			remaining -= up_component

		bounce += 1

	global_position = start.origin

func capture_mouse() -> void:
	if allow_movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
