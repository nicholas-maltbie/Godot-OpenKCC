class_name OpenKCCBody3D extends RigidBody3D
## Implementation of the OpenKCC that uses the
## the [RigidBody3D] to directly
## interact with the physics world.

## Default grounded height for the character.
const DEFAULT_GROUNDED_HEIGHT = 0.1
## Default max walking angle in degrees.
const DEFAULT_MAX_WALK_ANGLE = 60
## Maximum number of bounces when player computes sliding.
const MAX_BOUNCES:int = 5
## Buffer for shoving angle when normalizing bounce in radians.
const BUFFER_SHOVE_RADIANS:float = PI
## Maximum shove angle when normalizing bounce in radians.
const MAX_SHOVE_RADIANS:float = PI/2

## Small value for buffer values.
const EPSILON:float = 0.001

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

## Margin of distance for player to maintain between objects.
## Will attempt to be at minimum this distance from any other objects during movement.
@export var margin:float = 0.04
#endregion

## Direction of up for the character
var up:Vector3 = Vector3.UP

#region Grounded state
## Did the player hit the ground within [member OpenKCCBody3D.grounded_dist] distance.
var _ground_hit:bool = false
## What object did the player hit on the ground (if any).
var _ground_object:Object = null
## Distance player is from the ground.
var _ground_dist:float = 0
## Angle player is making between ground normal and vertical.
var _ground_angle:float = 0
## Ground normal vector from collision.
var _ground_normal:Vector3 = Vector3.ZERO
## Position in which player collider hit the ground.
var _ground_position:Vector3 = Vector3.ZERO
#endregion

## Internal variable for computing collisions
var _collision:KinematicCollision3D = KinematicCollision3D.new();

## Check if a player's final position after snapping up would be valid.
## Returns true if valid, false if the player hits an object or the step is too narrow.
## See [member OpenKCCBody3D.step_up_depth] for step depth requirements.
##
## [br] [param distance_to_snap] - How far should the player be snapped up.
## [br] [param momentum] - Remaining momentum of player after snapping up.
## [br] [param position] - position of player before snapping up.
func _can_snap_up(distance_to_snap:float, momentum:Vector3, position:Vector3) -> bool:
	## If the character were to snap up and move forward, would they hit something?
	var snap_pos:Vector3 = position + distance_to_snap * up;
	var snap_transform:Transform3D = Transform3D(global_transform.basis, snap_pos)
	var hit := test_move(snap_transform, momentum, _collision, margin)

	# If they can move without instantly hitting something, then snap them up
	return !hit or _collision.get_travel().length() > step_up_depth

## Get the distance a place is from the ground and returns the movement
## in order to place the player on the ground.
##
## [br] [param position] - Position to start player from.
## [br] [param dir] - Direction to snap the player.
## [br] [param dist] - Maximum distance to check for snapping.
func _get_snap_down(position:Vector3, dir:Vector3, dist:float) -> Vector3:
	var snap_transform:Transform3D = Transform3D(global_transform.basis, position)
	var hit := test_move(snap_transform, dir * dist, _collision, EPSILON, true)

	# Move player to snapped down
	if hit:
		return _collision.get_travel().limit_length(max(0, _collision.get_travel().length() - margin))

	return Vector3.ZERO

## Check if a bounce is perpendicular by computing a raycast from slightly behind
## the [param hit] in the direction of [param momentum]. Will return true if the
## bounce is mostly perpendicular, aka, hit a vertical surface, false otherwise.
## This is used to check if the player is able to snap up a step.
##
## [br] [param hit] - Hit information from player collision.
## [br] [param momentum] = Player direction of movement.
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

## Check the current grounded state of the player, will update the grounded
## state variables based on the result of the check.
## Checks by invoking [method PhysicsBody3D.test_move] in the down
## direction for [member OpenKCCBody3D.grounded_dist]. If something is hit,
## the player's grounded state will be updated with the collision result.
func check_grounded():
	_ground_hit = test_move(global_transform, -up * (grounded_dist + EPSILON), _collision, EPSILON, true)
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

## Is the player currently on the floor.
## Grounded state is updated by [method OpenKCCBody3D.check_grounded]
## which is called after each [method OpenKCCBody3D.move_and_slide]
func is_on_floor() -> bool:
	return _ground_hit and _ground_dist <= grounded_dist

## Is the player sliding. Player will be considered sliding
## if the player is both [method OpenKCCBody3D.is_on_floor]
## and the [member OpenKCCBody3D._ground_angle] is greater than
## the [member OpenKCCBody3D.max_walk_angle].
func is_sliding() -> bool:
	return is_on_floor() and _ground_angle > deg_to_rad(max_walk_angle)

## Snap the player to the ground, will check if the player is within
## [member OpenKCCBody3D.vertical_snap_up] from the floor.
## If so, the player will snap up to the position.
func snap_to_ground() -> void:
	global_transform.origin += _get_snap_down(global_transform.origin, -up, vertical_snap_up)

## Move and slide the player by some movement vector.
## Will start off by checking if the player is overlapping with any objects
## and push out before attempting any movement.
##
## Then, the movement will be computed, the player will bounce off of any surfaces and slide along the plane.
## This movement is limited to a maximum of [constant MAX_BOUNCES] bounces at most.
## Remaining momentum will be decreased after each bounce depending on how sharp
## the bounce was. For example, walking directly into a wall will result in no
## sliding. While glancing off a surface at a 30 degree angle will result in
## retaining most of the momentum.
##
## Once the player has finished movement, the grounded state will be updated
## by invoking [method OpenKCCBody3D.check_grounded]
##
## [i]This is expected to be called within a physics update, otherwise the behavior
## may not behave as expected.[/i]
##
## [br] [param movement] - Player movement in world space.
## [br] [param stop_slide_up_walls] - Should sliding up vertical surfaces be prevented.
## [br] [param can_snap_up] - If vertical snapping is enabled, should the player be able to snap up
##   as part of this movement command.
func move_and_slide(movement:Vector3, stop_slide_up_walls:bool=true, can_snap_up:bool=false) -> void:
	# Check to push out of overlapping objects
	var overlap = test_move(global_transform, up * EPSILON, _collision, margin / 2, true)
	if overlap:
		# Remove original "up" movement from collision check
		global_position += _collision.get_travel() - up * EPSILON

	# Setup some variables
	var bounce:int = 0;
	var remaining:Vector3 = movement;
	var start:Transform3D = global_transform
	var snapped_up:bool = false

	# Compute movement due to each bounce
	while remaining.length() > EPSILON and bounce < MAX_BOUNCES:
		# Increment bounce count
		bounce += 1

		# Helper value
		var move_dir:Vector3 = remaining.normalized()
		var move_dist:float = remaining.length()

		# Check if player collides with anything due to bounce
		var hit := test_move(start, remaining, _collision, margin, true)
		if not hit:
			start.origin += remaining
			break

		var normal:Vector3 = _collision.get_normal()
		var dist_remaining:float = _collision.get_remainder().length()
		remaining = _collision.get_remainder()

		# Otherwise this collided with something
		# Move the object to the collision position
		start.origin += _collision.get_travel()

		# Push character back by depth on normal
		start.origin += _collision.get_normal() * _collision.get_depth()

		# Get angle between surface normal and remaining movement
		var angle_between:float = normal.angle_to(move_dir)
		dist_remaining *= get_angle_factor(angle_between)

		# Check if the player is running into a perpendicular surface
		var perpendicular_bounce:bool = _check_perpendicular_bounce(_collision, remaining)
		var allow_snap:bool = can_snap_up and vertical_snap_up > 0
		var bottom:Vector3 = start.origin
		var within_snap_height:bool = (_collision.get_position() - _ground_position).dot(up) <= vertical_snap_up
		var within_snap_bounds:bool = perpendicular_bounce and allow_snap and within_snap_height
		if within_snap_bounds and _can_snap_up(vertical_snap_up, remaining, start.origin):
			# move player up if they can snap up a step
			snapped_up = true
			var distance_move:float = min(dist_remaining, vertical_snap_up)
			start.origin += distance_move * up

			# Skip rest of bounce operation
			continue

		# Rotate the remaining movement to be projected along the plane
		# of the surface hit (emulate 'sliding' against the object)
		remaining = Plane(normal).project(remaining).normalized() * dist_remaining

		# Don't let player slide backwards (dot checks if facing same direction
		# than the player's initial movement).
		if remaining.dot(movement) < 0:
			# Cleanly stop movement to avoid backwards jitter
			break

		# If the player is sliding up a wall, stop the player from sliding up or down walls
		if stop_slide_up_walls and normal.dot(up) <= EPSILON:
			# Remove vertical component of remaining movement
			remaining = Plane(up).project(remaining).normalized() * dist_remaining

	if snapped_up:
		start.origin += _get_snap_down(start.origin, -up, vertical_snap_up)

	global_position = start.origin
	check_grounded()

## Get the angle factor, how much momentum should be kept after
## a bounce at a given angle. Will return a value between 0 and 1
## with 1 representing keeping all the momentum, and zero means
## the player should stop.
##
## [br] [param angle_between] - Angle between player and collision surface.
func get_angle_factor(angle_between:float) -> float:
	# Normalize angle between to be between 0 and 1
	var normalized_angle:float = clamp( \
		abs(angle_between - BUFFER_SHOVE_RADIANS) / MAX_SHOVE_RADIANS, 0, 1)

	# Reduce the remaining movement by the remaining movement that occurred
	return pow(0.1 + normalized_angle * 0.9, 2)
