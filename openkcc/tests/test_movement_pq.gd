extends GutTest

const MOVE_VECTOR_TESTS = [ \
	[Vector3.FORWARD], \
	[Vector3.LEFT], \
	[Vector3.BACK], \
	[Vector3.RIGHT], \
	[Vector3.UP], \
	[Vector3.DOWN], \
	[Vector3.FORWARD + Vector3.LEFT], \
	[Vector3.FORWARD + Vector3.RIGHT], \
	[Vector3.BACK + Vector3.LEFT], \
	[Vector3.BACK + Vector3.RIGHT], \
]

var slide_params = ParameterFactory.named_parameters(
	['wall_rotation', 'expected_slide_dir', 'forward_bounds', 'slide_bounds'],
	[
		[ 30, Vector3.LEFT,  [6.65, 0.1], [2.75, 0.1]],
		[-30, Vector3.RIGHT, [6.65, 0.1], [2.75, 0.1]],
		[ 15, Vector3.LEFT,  [9.25, 0.1], [0.67, 0.1]],
		[-15, Vector3.RIGHT, [9.25, 0.1], [0.67, 0.1]],
		[  0, Vector3.RIGHT, [9.00, 0.1], [0.00, 0.1]],
	])

var wall_slide_params = ParameterFactory.named_parameters(
	["movement", "expected", "error"],
	[
		[Vector3.FORWARD * 10 + Vector3.UP *  5, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 30 + Vector3.UP * 15, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 35 + Vector3.UP * 20, Vector3(0, 3, -4), Vector3(0.0, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 3, Vector3(3.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 5, Vector3(5.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT * 3, Vector3(-3.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT * 5, Vector3(-5.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 3, Vector3(3.5, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 5, Vector3(5.7, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT * 3, Vector3(-3.5, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT * 5, Vector3(-5.7, 3, -4), Vector3(0.1, 0.2, 0.2)],
	])

var jitter_parms = ParameterFactory.named_parameters(
	["movement", "expected"],
	[
		[Vector3.FORWARD *  10, Vector3(0.0, 1.0, -3.6)],
		[Vector3.FORWARD *  20, Vector3(0.0, 1.0, -3.6)],
		[Vector3.FORWARD *  40, Vector3(0.0, 1.0, -3.6)],
		[Vector3.FORWARD *  50, Vector3(0.0, 1.0, -3.6)],
		[Vector3.FORWARD * 100, Vector3(0.0, 1.0, -3.6)],
	])

var ground_params = ParameterFactory.named_parameters(
	[
		"invalid_ground_hit",
		"invalid_ground_angle",
		"invalid_ground_dist",
		"expected_is_on_floor",
		"expected_is_sliding"
	],
	[
		[ true,  true,  true, false, false],
		[ true,  true, false, false, false],
		[ true, false,  true, false, false],
		[ true, false, false, false, false],
		[false,  true,  true, false, false],
		[false,  true, false,  true,  true],
		[false, false,  true, false, false],
		[false, false, false,  true, false]
	])

var overlap_params = ParameterFactory.named_parameters(
	[
		"box_position",
		"expected_position",
	],
	[
		[Vector3( 0.00, 1, -0.25), Vector3( 0.0, 1,  1.5)],
		[Vector3( 0.00, 1,  0.25), Vector3( 0.0, 1, -1.5)],
		[Vector3(-0.25, 1,  0.00), Vector3( 1.5, 1,  0.0)],
		[Vector3( 0.25, 1, -0.00), Vector3(-1.5, 1,  0.0)],
	])

var _character:OpenKCCBody3DPQ
var _ground:StaticBody3D

func before_each():
	_character = OpenKCCBody3DPQ.new()
	add_child_autofree(_character)
	_character.setup_shape()

	_character.height = 2
	_character.radius = 0.5
	_character.skin_width = 0.01

	_character.global_position = Vector3(0, 1, 0)
	_ground = TestUtils.add_wall(self, Vector3(10, 1, 10), Vector3(0, -0.501, 0), Vector3.ZERO, Vector3.ZERO, "Ground")

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
func test_player_slide(params=use_parameters(slide_params)):
	TestUtils.add_wall(self, Vector3(10, 10, 1), Vector3(0, 0, 0), Vector3(0, 0, -10), Vector3(0, params.wall_rotation, 0))
	var start:Vector3 = _character.global_position
	_character.move_and_slide(Vector3.FORWARD * 10)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.FORWARD), params.forward_bounds[0], params.forward_bounds[1])
	assert_almost_eq(delta.dot(params.expected_slide_dir), params.slide_bounds[0], params.slide_bounds[1])

## Test the player's move and slide function for movement in a 3D space
## in various basic directions.
func test_player_move_and_slide(params=use_parameters(MOVE_VECTOR_TESTS)):
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
func test_player_grounded(params=use_parameters(ground_params)):
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
func test_player_no_slide_up_walls(params=use_parameters(wall_slide_params)):
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
func test_player_no_jitter_backwards(params=use_parameters(jitter_parms)):
	# Add walls for the player to slide off of
	TestUtils.add_wall(self, Vector3(100, 10, 1), Vector3(-1, 0, 0), Vector3(0, 0, -10), Vector3(0, 30, 0), "wall_1")
	TestUtils.add_wall(self, Vector3(100, 10, 1), Vector3(-1, 0, 0), Vector3(0, 0, -10), Vector3(0, -30, 0), "wall_2")

	# Assert that when the player moves forward they don't slide backwards
	_character.move_and_slide(params.movement)
	assert_almost_eq(_character.global_position.x, params.expected.x, 0.1)
	assert_almost_eq(_character.global_position.y, params.expected.y, 0.1)
	assert_almost_eq(_character.global_position.z, params.expected.z, 0.1)

## Validate that the player will be able to use the push out overlapping
## to handle any situation where they are overlapping with an object.
func test_player_handle_overlap(params=use_parameters(overlap_params)):
	# Add a box that the player will overlap with
	TestUtils.add_wall(self, Vector3(1, 1, 1), Vector3(0, 0, 0), params.box_position, Vector3(0, 0, 0), "overlap_box")

	# Character should be pushed back to avoid the overlapping object
	_character.push_out_overlapping()

	# Specifically, the player should be pushed out according to expected offset
	assert_almost_eq(_character.global_position.x, params.expected_position.x, 0.1)
	assert_almost_eq(_character.global_position.y, params.expected_position.y, 0.1)
	assert_almost_eq(_character.global_position.z, params.expected_position.z, 0.1)
