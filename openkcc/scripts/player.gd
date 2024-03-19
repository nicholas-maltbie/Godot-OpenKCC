extends OpenKCCBodyGD

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Velocity due to world forces (like gravity)
var world_velocity:Vector3 = Vector3.ZERO

# Velocity due to plaeyr input (movement)
var move_velocity:Vector3 = Vector3.ZERO

# Mouse sensitivity
var mouse_sensibility = 1200

# Allow player movement
var allow_movement:bool = true

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

	move_and_slide(world_velocity * _delta, false)
	move_and_slide(move * _delta)

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

func moving_up() -> bool:
	return world_velocity.dot(up) > 0

func capture_mouse() -> void:
	if allow_movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
