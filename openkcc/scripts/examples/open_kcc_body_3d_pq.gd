class_name OpenKCCBody3DPQ
extends Node3D

const DEFAULT_GROUNDED_HEIGHT:float = 0.15
const DEFAULT_MAX_WALK_ANGLE:float = 60
const MAX_BOUNCES:int = 5
const BUFFER_SHOVE_RADIANS:float = PI
const MAX_SHOVE_RADIANS:float = PI/2
const EPSILON:float = 0.001

@export var height:float = 2
@export var radius:float = 0.5
@export var skin_width:float = 0.01

# Grounded configuration
@export var grounded_dist:float = DEFAULT_GROUNDED_HEIGHT
@export var max_walk_angle:float = DEFAULT_MAX_WALK_ANGLE

# Direction of up vector
var up:Vector3 = Vector3.UP

# Grounded state
var _ground_hit:bool = false
var _ground_dist:float = 0
var _ground_angle:float = 0
var _ground_normal:Vector3 = Vector3.ZERO
var _ground_position:Vector3 = Vector3.ZERO

var _collision:OpenKCCCollision = OpenKCCCollision.new()
var _physics_query_params:PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
var _capsule:Shape3D

func push_out_overlapping():
	var space_state = get_world_3d().direct_space_state
	_physics_query_params.transform = global_transform
	var result := space_state.collide_shape(_physics_query_params, 3)

	# if not overlapping with anything, exist
	if result.is_empty():
		return

	# For each pair of points, compute how far to push the player out of them
	var delta:Vector3 = Vector3.ZERO
	var collision:int = result.size() / 2
	for collision_idx in range(0, collision):
		var idx_1 = collision_idx * 2
		var idx_2 = idx_1 + 1
		delta += result[idx_2] - result[idx_1]

	global_position += delta

func _get_collision(start:Transform3D, dir:Vector3, dist:float, collision:OpenKCCCollision) -> bool:
	var space_state = get_world_3d().direct_space_state
	_physics_query_params.transform = start
	_physics_query_params.motion = dir * (dist + skin_width)

	var result := space_state.cast_motion(_physics_query_params)
	var safe_portion = result[0]
	var unsafe_portion = result[1]

	if safe_portion == 1:
		return false

	_physics_query_params.transform.origin += _physics_query_params.motion * unsafe_portion
	var rest:Dictionary = space_state.get_rest_info(_physics_query_params)

	# If could not find bounce data, abort and report error
	if rest.is_empty():
		push_warning("Unable to compute bounce for _get_collision")
		collision.dist_traveled = 0
		collision.dist_remaining = 0
		collision.point = Vector3.ZERO
		collision.normal = Vector3.ZERO
		return true

	# Move player by distance traveled if bouncing off something
	collision.dist_traveled = max(0, dist * safe_portion - skin_width)
	collision.dist_remaining = dist - collision.dist_traveled
	collision.point = rest["point"]
	collision.normal = rest["normal"]
	return true

func setup_shape():
	_capsule = CapsuleShape3D.new()
	_capsule.height = height - skin_width
	_capsule.radius = radius - skin_width
	_physics_query_params.shape = _capsule
	_physics_query_params.margin = EPSILON

func move_and_slide(movement:Vector3, stop_slide_up_walls:bool=true) -> void:
	var bounce:int = 0
	var remaining:Vector3 = movement
	var start := global_transform

	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Helper value
		var move_dir:Vector3 = remaining.normalized()
		var move_dist:float = remaining.length()

		# Check if player collides with anything due to bounce
		var hit := _get_collision(start, move_dir, move_dist, _collision)

		# If we don't collide with anything, proceed forward
		if not hit:
			start.origin += remaining
			break

		# Otherwise this collided with something
		# Move the object to the collision position
		start.origin += move_dir * _collision.dist_traveled

		# Get angle between surface normal and remaining movement
		var angle_between:float = _collision.normal.angle_to(move_dir)

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(_collision.normal).project(remaining).normalized() * \
			_collision.dist_remaining * get_angle_factor(angle_between)

		# Don't let player slide backwards (dot checks if facing same direction
		# than the player's initial movement).
		if remaining.dot(movement) < 0:
			# Cleanly stop movement to avoid backwards jitter
			break

		# If the player is sliding up a wall, stop the player from sliding up or down walls
		if stop_slide_up_walls and _collision.normal.dot(up) <= EPSILON:
			# Remove vertical component of remaining movement
			remaining = Plane(up).project(remaining)

		# Increment bounce count
		bounce += 1

	global_position = start.origin

func check_grounded():
	_ground_hit = _get_collision(global_transform, Vector3.DOWN, grounded_dist, _collision)
	if _ground_hit and _collision.normal != Vector3.ZERO:
		_ground_dist = _collision.dist_remaining
		_ground_angle = _collision.normal.angle_to(up)
		_ground_normal = _collision.normal
		_ground_position = _collision.point
	else:
		_ground_dist = 0
		_ground_angle = 0
		_ground_normal = Vector3.ZERO
		_ground_position = Vector3.ZERO

func is_on_floor() -> bool:
	return _ground_hit and _ground_dist <= grounded_dist

func is_sliding() -> bool:
	return is_on_floor() and _ground_angle > deg_to_rad(max_walk_angle)

func get_angle_factor(angle_between:float) -> float:
	# Normalize angle between to be between 0 and 1
	var normalized_angle:float = clamp( \
		abs(angle_between - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)

	# Reduce the remaining movement by the remaining movement that ocurred
	return pow(normalized_angle, 0.5)

class OpenKCCCollision:
	var dist_traveled:float
	var dist_remaining:float
	var normal:Vector3
	var point:Vector3
