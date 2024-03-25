extends OpenKCCBody3DPQ

@export var move_speed:float = 5.0
@export var jump_velocity:float = 5.0

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

# Player's move input
var _input_component_forward:float
var _input_component_back:float
var _input_component_left:float
var _input_component_right:float

# Only allow the player to jump once until they land on solid ground
var _input_jump:bool = false
var _can_jump:bool = false

@onready var cam = $Head/Camera3d as Camera3D

func _ready() -> void:
	setup_shape()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	allow_movement = true

func _physics_process(_delta) -> void:
	# Check for overlapping objects.
	push_out_overlapping()

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
		_attempt_jump()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom
		# gameplay actions.
		var input_x := _input_component_right - _input_component_left
		var input_y := _input_component_back - _input_component_forward
		direction = transform.basis * Vector3(input_x, 0, input_y)
		direction = direction.normalized()

	if direction:
		move_velocity.x = direction.x * move_speed
		move_velocity.z = direction.z * move_speed
	else:
		move_velocity.x = move_toward(move_velocity.x, 0, move_speed)
		move_velocity.z = move_toward(move_velocity.z, 0, move_speed)

	var move:Vector3 = move_velocity
	if is_on_floor() and not is_sliding():
		move *= Quaternion(_ground_normal, up)

	move_and_slide(move * _delta, false)
	move_and_slide(world_velocity * _delta, false)

func _input(event:InputEvent) -> void:
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

	if event.is_action("Jump"):
		_input_jump = event.is_pressed()

	if event.is_action("Forward"):
		_input_component_forward = event.get_action_strength("Forward")
	if event.is_action("Back"):
		_input_component_back = event.get_action_strength("Back")
	if event.is_action("Left"):
		_input_component_left = event.get_action_strength("Left")
	if event.is_action("Right"):
		_input_component_right = event.get_action_strength("Right")

	if event is InputEventMouseMotion:
		# Only rotate player if input is allowed
		# Adjust rotation based on player input
		if allow_movement:
			rotation.y -= event.relative.x / mouse_sensibility
			$Head/Camera3d.rotation.x -= event.relative.y / mouse_sensibility
			$Head/Camera3d.rotation.x = clamp($Head/Camera3d.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _attempt_jump():
	# If the player is on ground and not sliding, allow to jump again
	if is_on_floor() and not is_sliding():
		_can_jump = true

	if _input_jump and is_on_floor() and _can_jump:
		# Toggle jumped flag to prevent jump again until they are back on the ground
		_can_jump = false
		_apply_jump()

func _apply_jump():
	world_velocity = up * jump_velocity

func moving_up() -> bool:
	return world_velocity.dot(up) > 0

func capture_mouse() -> void:
	if allow_movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
