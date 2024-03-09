extends StaticBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GROUNDED_HEIGHT = 0.1
const MAX_WALK_ANGLE = 60

const MAX_BOUNCES:int = 5

const BUFFER_SHOVE_RADIANS:float = PI
const MAX_SHOVE_RADIANS:float = PI/2
const EPSILON:float = 0.001

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouse_sensibility = 1200
var velocity = Vector3.ZERO

var allow_movement = true
var collision:KinematicCollision3D

@onready var cam = $Head/Camera3d as Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	allow_movement = true
	collision = KinematicCollision3D.new();

func is_on_floor():
	var hit:bool = test_move(global_transform, Vector3.DOWN * GROUNDED_HEIGHT, collision, EPSILON)
	if not hit:
		return false;
	
	var angle:float = collision.get_normal().angle_to(Vector3.UP)
	return hit && angle <= MAX_WALK_ANGLE

func move_and_slide(movement):
	var bounce:int = 0;
	var remaining:Vector3 = movement;
	var start:Transform3D = global_transform
	
	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Check if player collides with anything due to bounce
		var hit:bool = test_move(start, remaining, collision, EPSILON)
		if not hit:
			global_position = start.origin + remaining
			return
		
		# Move player by distance traveled if colliding
		start.origin += collision.get_travel()
		var remainingDist:float = collision.get_remainder().length()
		
		# Get angle between surface normal and remaining movement
		var angleBetween:float = collision.get_normal().angle_to(remaining)

		# Normalize angle between to be between 0 and 1
		var normalizedAngle:float = clamp(abs(angleBetween - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)
		
		# Reduce the remaining movement by the remaining movement that ocurred
		remainingDist *= pow(normalizedAngle, 0.5)

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(collision.get_normal()).project(collision.get_remainder()).normalized() * remainingDist
		bounce += 1

	global_position = start.origin

func _physics_process(_delta):
	# Add the gravity.
	var grounded = is_on_floor();
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
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

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
