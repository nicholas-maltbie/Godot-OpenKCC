class_name OpenKCCRigidBody3D extends RigidBody3D
## Implementation of the OpenKCC that uses the
## the [RigidBody3D] to directly
## interact with the physics world.

## Implementation of basic bounce and grounded movement
const DEFAULT_GROUNDED_HEIGHT = 0.01
const DEFAULT_MAX_WALK_ANGLE = 60
const MAX_BOUNCES:int = 5
const BUFFER_SHOVE_RADIANS:float = PI
const MAX_SHOVE_RADIANS:float = PI/2
const EPSILON:float = 0.001

# Direction of up vector
var up:Vector3 = Vector3.UP

#region Export Parameters
## Distance at which player is considered on the ground and no longer falling, defaults to
## [constant DEFAULT_GROUNDED_HEIGHT].
@export var grounded_dist = DEFAULT_GROUNDED_HEIGHT

## Maximum angle at which the player can walk up slopes in degrees, defaults to
## [constant DEFAULT_MAX_WALK_ANGLE].
@export var max_walk_angle = DEFAULT_MAX_WALK_ANGLE

## Vertical snap up distance the player can snap up.
@export var vertical_snap_up:float = 0.3

## Minimum depth required for a stair when moving onto a step.
@export var step_up_depth:float = 0.3
#endregion

#region Grounded state
var _ground_hit:bool = false
var _ground_object:Object = null
var _ground_dist:float = 0
var _ground_angle:float = 0
var _ground_normal:Vector3 = Vector3.ZERO
var _ground_position:Vector3 = Vector3.ZERO
#endregion

# Internal variable for computing collisions
var _collision:KinematicCollision3D = KinematicCollision3D.new();

func _can_snap_up(distance_to_snap:float, momentum:Vector3, position:Vector3) -> bool:
	# If the character were to snap up and move forward, would they hit something?
	var snap_pos:Vector3 = position + distance_to_snap * up;
	var snap_transform:Transform3D = Transform3D(global_transform.basis, snap_pos)
	var hit := test_move(snap_transform, momentum, _collision, EPSILON)

	# If they can move without instantly hitting something, then snap them up
	return !hit or _collision.get_travel().length() > step_up_depth

func _get_snap_down(position:Vector3, dir:Vector3, dist:float) -> Vector3:
	var snap_transform:Transform3D = Transform3D(global_transform.basis, position)
	var hit := test_move(snap_transform, dir * dist, _collision, EPSILON)
	if hit:
		return dir * _collision.get_travel()

	return Vector3.ZERO

func _check_perpendicular_bounce(hit:KinematicCollision3D, momentum:Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var from := hit.get_position() - up.normalized() * EPSILON + hit.get_normal() * EPSILON
	var to := from + momentum.normalized() * hit.get_remainder()
	var physics_raycast_query_params := PhysicsRayQueryParameters3D.create(from, to)
	var result:Dictionary = space_state.intersect_ray(physics_raycast_query_params)
	if result.is_empty():
		return false
	var hit_normal:Vector3 = result["normal"]
	return hit_normal.dot(up) <= EPSILON

func check_grounded():
	_ground_hit = test_move(global_transform, Vector3.DOWN * (grounded_dist + EPSILON), _collision, EPSILON, true)
	if _ground_hit:
		_ground_object = _collision.get_collider()
		_ground_dist = _collision.get_travel().length()
		_ground_angle = _collision.get_normal().angle_to(up)
		_ground_normal = _collision.get_normal()
		_ground_position = _collision.get_position()
	else:
		_ground_object = null
		_ground_dist = 0
		_ground_angle = 0
		_ground_normal = Vector3.ZERO
		_ground_position = Vector3.ZERO

func is_on_floor() -> bool:
	return _ground_hit and _ground_dist <= grounded_dist

func is_sliding() -> bool:
	return is_on_floor() and _ground_angle > deg_to_rad(max_walk_angle)

func move_and_slide(movement:Vector3, stop_slide_up_walls:bool=true, can_snap_up:bool=false) -> void:
	var bounce:int = 0;
	var remaining:Vector3 = movement;
	var start:Transform3D = global_transform
	var snapped_up:bool = false

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
		
		# Check for snapping up
		var perpendicular_bounce:bool = _check_perpendicular_bounce(_collision, remaining)
		var allow_snap:bool = can_snap_up and vertical_snap_up > 0
		var bottom:Vector3 = start.origin
		var within_snap_height:bool = (_collision.get_position() - bottom).dot(up) <= vertical_snap_up
		var within_snap_bounds:bool = perpendicular_bounce and allow_snap and within_snap_height
		print("snapping_up:", within_snap_bounds, " -- ", "perpendicular_bounce:", perpendicular_bounce, ", allow_snap:", allow_snap, ", within_snap_height:", within_snap_height)
		if within_snap_bounds and _can_snap_up(vertical_snap_up, remaining, start.origin):
			print("snapping_up:", vertical_snap_up)
			# move player up if they can snap up a step
			snapped_up = true
			var distance_move:float = min(remaining_dist, vertical_snap_up)
			start.origin += distance_move * up

			# Skip rest of boucne operation
			continue

		# Don't let player slide backwards (dot checks if facing same direction
		# than the player's initial movement).
		if remaining.dot(movement) < 0:
			# Cleanly stop movement to avoid backwards jitter
			break;

		# If the player is sliding up a wall, stop the player from sliding up or down walls
		if stop_slide_up_walls and normal.dot(up) <= 0:
			# Remove vertical component of remaining movement
			remaining = Plane(up).project(remaining)

		# Increment bounce count
		bounce += 1

	if snapped_up:
		start.origin += _get_snap_down(start.origin, -up, vertical_snap_up)

	global_position = start.origin

func get_angle_factor(angle_between:float) -> float:
	# Normalize angle between to be between 0 and 1
	var normalized_angle:float = clamp( \
		abs(angle_between - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)

	# Reduce the remaining movement by the remaining movement that ocurred
	return pow(0.1 + normalized_angle * 0.9, 2)
