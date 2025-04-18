extends OpenKCCBody3DPhysicsQuery

@export var move_speed:float = 5.0
@export var move_acceleration:float = 15.0
@export var jump_velocity:float = 5.0
@export var snap_down_speed:float = 2.5

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

@onready var camera_controller = $Head as OpenKCCCameraController

func _ready() -> void:
	setup_shape()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	MenuBus.menu_opened.connect(_on_menu_opened)
	MenuBus.menu_closed.connect(_on_menu_closed)
	allow_movement = true

func _exit_tree():
	MenuBus.menu_opened.disconnect(_on_menu_opened)
	MenuBus.menu_closed.disconnect(_on_menu_closed)

func _process(_delta) -> void:
	# Have camera follow camera controller
	var cam = get_viewport().get_camera_3d()
	cam.position = camera_controller.get_target_position()
	cam.rotation = camera_controller.get_target_rotation()

func _physics_process(_delta) -> void:
	# Check for overlapping objects.
	push_out_overlapping()

	# Add the gravity.
	check_grounded()
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
		var input_x := _input_component_right - _input_component_left
		var input_y := _input_component_back - _input_component_forward
		direction = Quaternion.from_euler(Vector3(0, camera_controller.yaw, 0)) * Vector3(input_x, 0, input_y)
		direction = direction.normalized()

	if direction:
		move_velocity = move_velocity.move_toward(direction * move_speed, move_acceleration * _delta)
	else:
		move_velocity = move_velocity.move_toward(Vector3.ZERO, move_acceleration * _delta)

	var move:Vector3 = move_velocity
	if grounded() and not is_sliding():
		move *= Quaternion(_ground_normal, up)

	move_and_slide(move * _delta, grounded() and not moving_up(), true)
	move_and_slide(world_velocity * _delta, false)

	if grounded() and not is_sliding() and not moving_vertically():
		snapped_down = snap_down(-up, vertical_snap_down)
	else:
		snapped_down = false

func grounded() -> bool:
	return is_on_floor() or snapped_down

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
			camera_controller.yaw -= event.relative.x / mouse_sensibility
			camera_controller.pitch -= event.relative.y / mouse_sensibility
	elif event is InputEventMouseButton:
		if event.is_pressed():
			# zoom in
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_controller.zoom -= mouse_zoom_speed
			# zoom out
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_controller.zoom += mouse_zoom_speed

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

func moving_up() -> bool:
	return world_velocity.dot(up) > EPSILON

func moving_vertically() -> bool:
	return world_velocity.project(up).length() > EPSILON
