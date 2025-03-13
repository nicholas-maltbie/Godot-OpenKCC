extends GutTest

var _character:OpenKCCRigidBody3D
var _ground:StaticBody3D

func before_all():
	pass

func before_each():
	_character = OpenKCCRigidBody3D.new()
	var collision_body:CollisionShape3D = CollisionShape3D.new()
	var capsule_shape:CapsuleShape3D = CapsuleShape3D.new()
	collision_body.set_shape(capsule_shape)
	collision_body.position = Vector3(0, 1, 0)
	_character.add_child(collision_body)
	add_child_autofree(_character)

	_ground = TestUtils.add_wall(self, Vector3(10, 1, 10), Vector3(0, -0.501, 0), Vector3.ZERO, Vector3.ZERO, "Ground")

func after_each():
	pass

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Test player standing idle and that they do not move (assuming they are standing
## on a floor).
func test_player_idle():
	var start:Vector3 = _character.global_position
	simulate(_character, 30, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.length(), 0.0, 0.001)

## Test player slide accross a wall when running into it.
## Rotate the wall to various rotatinos and have the player
## walk into the wall and assert how far the player will
## bounce based on their rotation.
func test_player_slide(params=use_parameters(TestMoveParams.slide_params_rigidbody)):
	TestUtils.add_wall(self, Vector3(10, 10, 1), Vector3(0, 0, 0), Vector3(0, 0, -5), Vector3(0, params.wall_rotation, 0))
	var start:Vector3 = _character.global_position
	_character.move_and_slide(Vector3.FORWARD * 5)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.FORWARD), params.forward_bounds[0], params.forward_bounds[1])
	assert_almost_eq(delta.dot(params.expected_slide_dir), params.slide_bounds[0], params.slide_bounds[1])

## Test the player's move and slide function for movement in a 3D space
## in various basic directions.
func test_player_move_and_slide(params=use_parameters(TestMoveParams.MOVE_VECTOR_TESTS)):
	# Move the floor to allow for up or down movement
	_ground.free()
	var start:Vector3 = _character.global_position
	_character.move_and_slide(params[0])
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq((params[0] - delta).length(), 0.0, 0.01)

## Test the various player grounded states based on the player height from
## the ground, if there is an object below them, and the angle between
## the player and the ground.
func test_player_grounded(params=use_parameters(TestMoveParams.ground_params)):
	# Player should be grounded on the floor
	_character.check_grounded()
	assert_true(_character.is_on_floor())

	# Manually modify value for grounded dist for grounded to set as not on floor
	if params.invalid_ground_hit:
		_character._ground_hit = false
	if params.invalid_ground_angle:
		_character._ground_angle = _character.DEFAULT_MAX_WALK_ANGLE + 10
	if params.invalid_ground_dist:
		_character._ground_dist = _character.DEFAULT_GROUNDED_HEIGHT + 10
	assert_eq(_character.is_on_floor(), params.expected_is_on_floor)
	assert_eq(_character.is_sliding(), params.expected_is_sliding)

## Test if the player moves up a slanted surface towards a wall, that
## they will stop before sliding up the wall.
func test_player_no_slide_up_walls(params=use_parameters(TestMoveParams.wall_slide_params_rigidbody)):
	# Add a vertical wall in front of the player
	TestUtils.add_wall(self, Vector3(10, 10, 1), Vector3(0, 0, 0), Vector3(0, 0, -5), Vector3(0, 0, 0))

	# Move the player up vertically towards the wall
	_character.check_grounded()
	_character.move_and_slide(params.movement)

	# Assert that the character bounces as expected
	assert_almost_eq(_character.global_position.x, params.expected.x, params.error.x)
	assert_almost_eq(_character.global_position.y, params.expected.y, params.error.y)
	assert_almost_eq(_character.global_position.z, params.expected.z, params.error.z)

## Validate player won't bounce backwards when they hit a wall
## and could slide backwards in the original direction they were moving
func test_player_no_jitter_backwards(params=use_parameters(TestMoveParams.jitter_parms)):
	# Add walls for the player to slide off of
	TestUtils.add_wall(self, Vector3(100, 10, 1), Vector3(-1, 0, 0), Vector3(0, 0, -3), Vector3(0, 30, 0), "wall_1")
	TestUtils.add_wall(self, Vector3(100, 10, 1), Vector3(-1, 0, 0), Vector3(0, 0, -3), Vector3(0, -30, 0), "wall_2")

	# Assert that when the player moves forward they don't slide backwards
	_character.move_and_slide(params.movement)
	var expected := Vector3(0.2, 0.0, 2.2)
	assert_almost_eq(_character.global_position.x, expected.x, 0.1)
	assert_almost_eq(_character.global_position.y, expected.y, 0.1)
	assert_almost_eq(_character.global_position.z, expected.z, 0.1)
