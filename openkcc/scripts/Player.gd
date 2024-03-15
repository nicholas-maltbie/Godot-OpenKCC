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
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouse_sensibility = 1200
var velocity = Vector3.ZERO

var allow_movement = true

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

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	allow_movement = true
	_collision = KinematicCollision3D.new();

func check_grounded():
	_ground_hit = test_move(global_transform, Vector3.DOWN * grounded_dist, _collision, EPSILON)
	if _ground_hit:
		_ground_object = _collision.get_collider()
		_ground_dist = _collision.get_travel().length()
		_ground_angle = _collision.get_angle()
		_ground_normal = _collision.get_normal()
		_ground_position = _collision.get_position()
		return is_on_floor()

	_ground_object = null
	_ground_dist = 0
	_ground_angle = 0
	_ground_normal = Vector3.ZERO
	_ground_position = Vector3.ZERO
	return false

func is_on_floor():
	return _ground_hit and _ground_dist <= grounded_dist and _ground_angle <= max_walk_angle

func move_and_slide(movement):
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
		bounce += 1

	global_position = start.origin

func _physics_process(_delta):
	# Add the gravity.
	var grounded = check_grounded()
	if not grounded:
		velocity.y -= gravity * _delta
	elif Vector3.UP.dot(velocity) <= 0:
		velocity.y = 0

	# If we allow input, let the player jump and move.
	var direction = Vector3(0, 0, 0)
	if allow_movement:
		# Handle Jump.
		if Input.is_action_just_pressed("Jump") and grounded:
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom
		# gameplay actions.
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
		direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		direction = direction.normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide(velocity * _delta)

func capture_mouse():
	if allow_movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
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
