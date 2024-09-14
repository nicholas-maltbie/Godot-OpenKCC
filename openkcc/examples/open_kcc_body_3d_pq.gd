class_name OpenKCCBody3DPQ extends Node3D
## Implementation of the OpenKCC that uses the
## the [PhysicsShapeQueryParameters3D] to directly
## interact with the physics world.

#region Constants

## Default grounded height value for player.
const DEFAULT_GROUNDED_HEIGHT:float = 0.15

## Default maximum walk angle in degrees.
const DEFAULT_MAX_WALK_ANGLE:float = 60

## Max bounces when computing player movement.
const MAX_BOUNCES:int = 5

## Buffer value when computing angle falloff (90 degrees)
const BUFFER_SHOVE_RADIANS:float = PI

## Max angle taht a player can reflect off of (180 degrees)
const MAX_SHOVE_RADIANS:float = PI/2

## Small epsilon value for handling error ranges.
const EPSILON:float = 0.001

#endregion

#region Export Parameters

## Height of player's capsule collider.
@export var height:float = 2

## Radius of player's capsule collider.
@export var radius:float = 0.5

## Skin width of player's collision shape.
## Player is allowed to overlap with other objects by this amount, good to
## keep this a small, non-zero value to allow for some overlap with surronding objects.
@export var skin_width:float = 0.01

## Distance at which player is considered on the ground and no longer falling, defaults to
## [constant DEFAULT_GROUNDED_HEIGHT].
@export var grounded_dist:float = DEFAULT_GROUNDED_HEIGHT

## Maximum angle at which the player can walk up slopes in degrees, defaults to
## [constant DEFAULT_MAX_WALK_ANGLE].
@export var max_walk_angle:float = DEFAULT_MAX_WALK_ANGLE

## Vertical snap up distance the player can snap up.
@export var vertical_snap_up:float = 0.3

## Minimum depth required for a stair when moving onto a step.
@export var step_up_depth:float = 0.3

## Vertical snap down distance the player snap down while walking.
@export var vertical_snap_down:float = 0.35
#endregion

## Direction of up vector for player movement.
var up:Vector3 = Vector3.UP

#region Grounded State
## A value indicating whether the ground hit check hit an object within the grounded dist.
var _ground_hit:bool = false

## Distance player is standing off the ground.
var _ground_dist:float = 0

## Angle between the surface normal of the player and the up vector.
var _ground_angle:float = 0

## Normal vector of the player's standing.
var _ground_normal:Vector3 = Vector3.ZERO

## Position in which player's collider is hitting the ground.
var _ground_position:Vector3 = Vector3.ZERO

#endregion

#region Collision Parameters

## Collision placeholder for player movement to avoid dynamic memory allocation.
var _collision:OpenKCCCollision = OpenKCCCollision.new()

## Physics query for player movement to avoid dynamic memory allocation.
var _physics_query_params:PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()

## Physics query for raycast to avoid dynamic memory allocation.
var _phsyics_raycast_query_params:PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()

## Capsule shape of the player with the skin width removed.
var _capsule:Shape3D

## Capsule shape of the player including the overlap.
var _overlap_capsule:Shape3D

#endregion

func _can_snap_up(distance_to_snap:float, momentum:Vector3, position:Vector3) -> bool:
	# If the character were to snap up and move forward, would they hit something?
	var snap_pos:Vector3 = position + distance_to_snap * up;
	var snap_transform:Transform3D = Transform3D(global_transform.basis, snap_pos)
	var hit := _get_collision(snap_transform, momentum.normalized(), step_up_depth, _collision)
	
	# If they can move without instantly hitting something, then snap them up
	return !hit or _collision.dist_traveled > step_up_depth

func _check_perpendicular_bounce(hit:OpenKCCCollision, momentum:Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	_phsyics_raycast_query_params.from = hit.point - up.normalized() * EPSILON + hit.normal * EPSILON
	_phsyics_raycast_query_params.to = _phsyics_raycast_query_params.from + momentum.normalized() * hit.dist_remaining
	var result:Dictionary = space_state.intersect_ray(_phsyics_raycast_query_params)
	if result.is_empty():
		return false
	var hit_normal:Vector3 = result["normal"]
	return hit_normal.dot(up) <= EPSILON

func _get_collision(start:Transform3D, dir:Vector3, dist:float, collision:OpenKCCCollision) -> bool:
	var space_state = get_world_3d().direct_space_state
	_physics_query_params.transform = start
	_physics_query_params.margin = skin_width
	_physics_query_params.shape = _capsule
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

func _get_snap_down(position:Vector3, dir:Vector3, dist:float) -> Vector3:
	var snap_transform:Transform3D = Transform3D(global_transform.basis, position)
	var hit := _get_collision(snap_transform, dir, dist, _collision)
	if hit and _collision.dist_traveled > skin_width:
		return dir * _collision.dist_traveled

	return Vector3.ZERO

## Push the character out of overlapping objects
func push_out_overlapping() -> void: 
	var space_state = get_world_3d().direct_space_state
	_physics_query_params.transform = global_transform
	_physics_query_params.shape = _overlap_capsule
	_physics_query_params.margin = EPSILON
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
		var push = result[idx_2] - result[idx_1]
		if push.length() > EPSILON:
			delta += push.normalized() * (push.length() - EPSILON)

	global_position += delta

func snap_down(dir:Vector3, max_move:float) -> bool:
	var snap_down:Vector3 = _get_snap_down(global_position, dir, vertical_snap_down)
	if snap_down.length() > max_move:
		snap_down = snap_down.normalized() * max_move
	
	if snap_down.length() > EPSILON:
		global_position += snap_down
		return true
	else:
		return false

func setup_shape():
	_capsule = CapsuleShape3D.new()
	_overlap_capsule = CapsuleShape3D.new()
	_capsule.height = height - skin_width * 2
	_capsule.radius = radius - skin_width
	_overlap_capsule.height = height
	_overlap_capsule.radius = radius

func move_and_slide(movement:Vector3, stop_slide_up_walls:bool=true, can_snap_up:bool=true) -> void:
	var bounce:int = 0
	var remaining:Vector3 = movement
	var start := global_transform
	var snapped_up:bool = false

	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Increment bounce count
		bounce += 1

		# Helper value
		var move_dir:Vector3 = remaining.normalized()
		var move_dist:float = remaining.length()

		# Check if player collides with anything due to bounce
		var hit := _get_collision(start, move_dir, move_dist, _collision)

		# If we don't collide with anything, proceed forward
		if not hit:
			start.origin += remaining
			break

		var normal:Vector3 = _collision.normal
		var dist_remaining:float = _collision.dist_remaining
		remaining = remaining.normalized() * dist_remaining

		# Otherwise this collided with something
		# Move the object to the collision position
		start.origin += move_dir * _collision.dist_traveled

		# Get angle between surface normal and remaining movement
		var angle_between:float = normal.angle_to(move_dir)

		# Check if the player is running into a perpendicular surface
		var perpendicular_bounce:bool = _check_perpendicular_bounce(_collision, remaining)
		var allow_snap:bool = can_snap_up and vertical_snap_up > 0
		var bottom:Vector3 = start.origin - height /  2 * up
		var within_snap_height:bool = (_collision.point - bottom).dot(up) <= vertical_snap_up
		if perpendicular_bounce and allow_snap and within_snap_height and \
			_can_snap_up(vertical_snap_up, remaining, start.origin):
			snapped_up = true
			
			# move player up if they can snap up a step
			var distance_move:float = min(dist_remaining, vertical_snap_up)
			start.origin += distance_move * up

			# Skip rest of boucne operation
			continue

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(normal).project(remaining).normalized() * \
			dist_remaining * get_angle_factor(angle_between)

		# Don't let player slide backwards (dot checks if facing same direction
		# than the player's initial movement).
		if remaining.dot(movement) < 0:
			# Cleanly stop movement to avoid backwards jitter
			break

		# If the player is sliding up a wall, stop the player from sliding up or down walls
		if stop_slide_up_walls and normal.dot(up) <= EPSILON:
			# Remove vertical component of remaining movement
			remaining = Plane(up).project(remaining)

	if snapped_up:
		start.origin += _get_snap_down(start.origin, -up, vertical_snap_up)

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
	return pow(0.1 + 0.9 * normalized_angle, 2)

class OpenKCCCollision:
	var dist_traveled:float
	var dist_remaining:float
	var normal:Vector3
	var point:Vector3
