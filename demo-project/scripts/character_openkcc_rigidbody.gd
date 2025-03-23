extends OpenKCCBody3D

## Speed of character movement (in meters per second).
@export var move_speed:float = 5.0

## Speed of character acceleration (in meters per second squared).
@export var move_acceleration:float = 15.0

## Velocity of player when jumping (in meters per second).
@export var jump_velocity:float = 5.0

## Speed at which the player can snap down (in meters per second).
@export var snap_down_speed:float = 2.5

## Speed at which the player rotates towards the direction of motion (in degrees per second).
@export var rotation_speed:float = 720.0

# Has the player snapped down as of the previous frame
var snapped_down:bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity:float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Velocity due to world forces (like gravity)
var world_velocity:Vector3 = Vector3.ZERO

# Velocity due to player input (movement)
var move_velocity:Vector3 = Vector3.ZERO

# Mouse sensitivity
var mouse_sensibility = 1200

# Mouse zoom speed
var mouse_zoom_speed = 0.25

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

# Character animator object
var _character_animator:CharacterAnimator

@onready var _camera_controller = $Head as CameraController

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	MenuBus.menu_opened.connect(_on_menu_opened)
	MenuBus.menu_closed.connect(_on_menu_closed)
	allow_movement = true

	_character_animator = CharacterAnimator.create( \
		$AnimationTree as AnimationTree, $Body as Node3D, rotation_speed, _get_desired_yaw())

func _exit_tree():
	MenuBus.menu_opened.disconnect(_on_menu_opened)
	MenuBus.menu_closed.disconnect(_on_menu_closed)

func _process(_delta) -> void:
	# Have camera follow camera controller
	var cam = get_viewport().get_camera_3d()
	cam.position = _camera_controller.get_target_position()
	cam.rotation = _camera_controller.get_target_rotation()

	var jumping:bool = _can_jump and _input_jump
	_character_animator.process(_input_direction(), _get_desired_yaw(), jumping, is_on_floor(), _delta)

func _physics_process(_delta: float) -> void:
	# Add the gravity.
	if not grounded() or is_sliding():
		world_velocity -= up * gravity * _delta
	elif grounded() and !moving_up():
		# If player is not moving up and hit the ground, stop world velocity
		world_velocity = world_velocity.move_toward(Vector3.ZERO, move_acceleration * _delta)

	# If we allow input, let the player jump and move.
	var direction = Vector3(0, 0, 0)
	if allow_movement:
		# Handle Jump.
		_attempt_jump()

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom
		# gameplay actions.
		var input_dir = _input_direction()
		direction = Quaternion.from_euler(Vector3(0, _camera_controller.yaw, 0)) * Vector3(input_dir.x, 0, input_dir.y)
		direction = direction.normalized()

	if direction:
		move_velocity = move_velocity.move_toward(direction * move_speed, move_acceleration * _delta)
	else:
		move_velocity = move_velocity.move_toward(Vector3.ZERO, move_acceleration * _delta)

	var move:Vector3 = move_velocity
	if grounded() and not is_sliding():
		move *= Quaternion(_ground_normal, up)

	move_and_slide((move + world_velocity) * _delta, false, true)

	if is_on_floor() and not moving_up():
		snap_to_ground()

func _get_desired_yaw() -> Quaternion:
	return Quaternion.from_euler(Vector3(0, deg_to_rad(180) + _camera_controller.yaw, 0))

func _input_direction() -> Vector2:
	var input_x := _input_component_right - _input_component_left
	var input_y := _input_component_back - _input_component_forward
	return Vector2(input_x, input_y)

func _on_menu_opened() -> void:
	allow_movement = false

func _on_menu_closed() -> void:
	allow_movement = true

func _input(event:InputEvent) -> void:
	# On web platform, mouse needs to be clicked in order to be
	# captured properly. Or as a direct input response like pressing a key.
	if OS.get_name() == "Web":
		if event is InputEventMouseButton:
			allow_movement = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
			_camera_controller.yaw -= event.relative.x / mouse_sensibility
			_camera_controller.pitch -= event.relative.y / mouse_sensibility
	elif event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_camera_controller.zoom -= mouse_zoom_speed
			# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_camera_controller.zoom += mouse_zoom_speed

func _attempt_jump():
	# If the player is on ground and not sliding, allow to jump again
	if grounded() and not is_sliding():
		_can_jump = true

	if _input_jump and grounded() and _can_jump:
		# Toggle jumped flag to prevent jump again until they are back on the ground
		_can_jump = false
		_apply_jump()

func _apply_jump():
	world_velocity = up * jump_velocity
	_character_animator.jump()

func grounded() -> bool:
	return is_on_floor() or snapped_down

func moving_up() -> bool:
	return world_velocity.dot(up) > EPSILON

func moving_vertically() -> bool:
	return world_velocity.project(up).length() > EPSILON
