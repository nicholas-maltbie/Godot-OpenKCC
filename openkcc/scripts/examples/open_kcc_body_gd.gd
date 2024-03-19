class_name OpenKCCBodyGD
extends StaticBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DEFAULT_GROUNDED_HEIGHT = 0.01
const DEFAULT_MAX_WALK_ANGLE = 60
const MAX_BOUNCES:int = 5
const BUFFER_SHOVE_RADIANS:float = PI
const MAX_SHOVE_RADIANS:float = PI/2
const EPSILON:float = 0.001

# Direction of up vector
var up:Vector3 = Vector3.UP

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
var _collision:KinematicCollision3D = KinematicCollision3D.new();

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

func is_on_floor() -> bool:
	return _ground_hit and _ground_dist <= grounded_dist

func is_sliding() -> bool:
	return is_on_floor() and _ground_angle > deg_to_rad(max_walk_angle)

func move_and_slide(movement:Vector3, stop_slide_up_walls:bool=true) -> void:
	var bounce:int = 0;
	var remaining:Vector3 = movement;
	var start:Transform3D = global_transform

	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Check if player collides with anything due to bounce
		var hit := test_move(start, remaining, _collision, EPSILON)
		if not hit:
			global_position = start.origin + remaining
			return

		# Move player by distance traveled if colliding
		start.origin += _collision.get_travel()
		var normal = _collision.get_normal()

		# Get angle between surface normal and remaining movement
		var angle_between := normal.angle_to(remaining)
		var remaining_dist := _collision.get_remainder().length() * get_angle_factor(angle_between)

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(normal).project(_collision.get_remainder()).normalized() * remaining_dist

		# Don't let player slide backwards (dot checks if facing same direction
		# than the player's initial movement).
		if remaining.dot(movement) < 0:
			# Cleanly stop movement to avoid backwards jitter
			break;

		# If the player is sliding up a wall, stop the player from sliding up or down walls
		if stop_slide_up_walls and normal.dot(up) >= 0:
			# Remove vertical component of remaining movement
			remaining = Plane(up).project(remaining)

		# Increment bounce count
		bounce += 1

	global_position = start.origin

func get_angle_factor(angle_between:float) -> float:
	# Normalize angle between to be between 0 and 1
	var normalized_angle:float = clamp( \
		abs(angle_between - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)

	# Reduce the remaining movement by the remaining movement that ocurred
	return pow(normalized_angle, 0.5)
