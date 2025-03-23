extends CharacterBody3D

## Speed of character movement (in meters per second).
@export var move_speed:float = 5.0

## Speed of cahracter acceleration (in meters per second squared).
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

# Velocity due to plaeyr input (movement)
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

@onready var _camera_controller = $Head as CameraController
@onready var _body:Node3D = $Body as Node3D
@onready var _animation_tree:AnimationTree = $AnimationTree as AnimationTree

## Current player animation state
var _anim_state:AnimState = AnimState.Idle
var _anim_state_machine:AnimationNodeStateMachinePlayback

## Various goal states for player animation.
enum AnimState { Idle, Walking, Falling, Jumping }

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	MenuBus.menu_opened.connect(_on_menu_opened)
	MenuBus.menu_closed.connect(_on_menu_closed)
	allow_movement = true

	# rotate player body in direction of camera
	_body.rotation = _get_desired_yaw().get_euler()

	# Animation state machine
	_anim_state_machine = _animation_tree["parameters/playback"]

func _exit_tree():
	MenuBus.menu_opened.disconnect(_on_menu_opened)
	MenuBus.menu_closed.disconnect(_on_menu_closed)

func _process(_delta) -> void:
	# Have camera follow camera controller
	var cam = get_viewport().get_camera_3d()
	cam.position = _camera_controller.get_target_position()
	cam.rotation = _camera_controller.get_target_rotation()

	# rotate player towards direction of movement (this is just visual, so complete
	# update with each frame instead of physics update).
	var target_anim_state:AnimState = AnimState.Idle
	var input_dir:Vector2 = _input_direction()
	var blend_position:Vector2 = _animation_tree.get("parameters/Walking/blend_position")
	if input_dir.length() >= 0.001:
		# rotate player to face in direction of camera.
		blend_position = blend_position.move_toward(Vector2(input_dir.x, -input_dir.y), _delta)
		var desired:Quaternion = _get_desired_yaw()
		var body_rotation:Quaternion = Quaternion(_body.basis)
		var delta_to_target:float = body_rotation.angle_to(desired)
		var weight:float = min(1.0, deg_to_rad(_delta * rotation_speed) / delta_to_target)
		_body.basis = Basis(body_rotation.slerp(desired, weight))
		target_anim_state = AnimState.Walking
	else:
		blend_position = blend_position.move_toward(Vector2.ZERO, _delta)

	_animation_tree.set("parameters/Walking/blend_position", blend_position)

	# If player is not on ground, set target state to falling
	if _can_jump and _input_jump:
		target_anim_state = AnimState.Jumping
	elif is_on_floor() == false:
		target_anim_state = AnimState.Falling

	# Update anim state if needed
	if _anim_state != target_anim_state:
		_anim_state = target_anim_state
		_anim_state_machine.travel(AnimState.keys()[_anim_state])

func _physics_process(_delta) -> void:
	# Add the gravity.
	if not is_on_floor():
		world_velocity -= self.up_direction * gravity * _delta
	elif is_on_floor() and not _moving_up():
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
	if is_on_floor():
		move *= Quaternion(get_floor_normal(), self.up_direction)

	velocity = move + world_velocity
	move_and_slide()

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
	# If the player is on ground, allow to jump
	if is_on_floor():
		_can_jump = true

	if _input_jump and _can_jump:
		# Toggle jumped flag to prevent jump again until they are back on the ground
		_can_jump = false
		_apply_jump()

func _apply_jump():
	world_velocity = self.up_direction * jump_velocity

	# Update animation
	_anim_state = AnimState.Jumping
	_anim_state_machine.travel(AnimState.keys()[_anim_state])

func _moving_up() -> bool:
	return world_velocity.dot(self.up_direction) > 0.001
