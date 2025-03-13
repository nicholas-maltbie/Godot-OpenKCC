class_name TestMoveParams

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

static var slide_params_physics_query = GutUtils.ParameterFactory.named_parameters(
	['wall_rotation', 'expected_slide_dir', 'forward_bounds', 'slide_bounds'],
	[
		[ 30, Vector3.LEFT,  [5.28, 0.1], [0.95, 0.1]],
		[-30, Vector3.RIGHT, [5.28, 0.1], [0.95, 0.1]],
		[ 15, Vector3.LEFT,  [8.88, 0.1], [0.25, 0.1]],
		[-15, Vector3.RIGHT, [8.88, 0.1], [0.25, 0.1]],
		[  0, Vector3.RIGHT, [9.00, 0.1], [0.00, 0.1]],
	])

static var slide_params_rigidbody = GutUtils.ParameterFactory.named_parameters(
	['wall_rotation', 'expected_slide_dir', 'forward_bounds', 'slide_bounds'],
	[
		[ 30, Vector3.LEFT,  [4.05, 0.1], [0.95, 0.1]],
		[-30, Vector3.RIGHT, [4.05, 0.1], [0.95, 0.1]],
		[ 15, Vector3.LEFT,  [3.90, 0.1], [0.25, 0.1]],
		[-15, Vector3.RIGHT, [3.90, 0.1], [0.25, 0.1]],
		[  0, Vector3.RIGHT, [4.00, 0.1], [0.00, 0.1]],
	])

static var wall_slide_params_physics_query = GutUtils.ParameterFactory.named_parameters(
	["movement", "expected", "error"],
	[
		[Vector3.FORWARD * 10 + Vector3.UP *  5, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 30 + Vector3.UP * 15, Vector3(0, 3, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 35 + Vector3.UP * 20, Vector3(0, 3, -4), Vector3(0.0, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 3, Vector3(1.7, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 5, Vector3(3.0, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT  * 3, Vector3(-1.7, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT  * 5, Vector3(-3.0, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 3, Vector3(1.3, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 5, Vector3(2.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT  * 3, Vector3(-1.3, 3, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT  * 5, Vector3(-2.2, 3, -4), Vector3(0.1, 0.2, 0.2)],
	])

static var wall_slide_params_rigidbody = GutUtils.ParameterFactory.named_parameters(
	["movement", "expected", "error"],
	[
		[Vector3.FORWARD * 10 + Vector3.UP *  5, Vector3(0, 2.0, -4.0), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 20 + Vector3.UP * 10, Vector3(0, 2.0, -3.9), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 30 + Vector3.UP * 15, Vector3(0, 2.0, -3.9), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 35 + Vector3.UP * 20, Vector3(0, 2.2, -3.8), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 3, Vector3( 2.3, 2.0, -4.0), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 5, Vector3( 3.5, 2.0, -4.0), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT  * 3, Vector3(-2.3, 2.0, -4.0), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT  * 5, Vector3(-3.5, 2.0, -4.0), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 3, Vector3( 3.1, 2.0, -3.9), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 5, Vector3( 3.8, 2.0, -3.9), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT  * 3, Vector3(-3.1, 2.0, -3.9), Vector3.ONE * 0.1],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT  * 5, Vector3(-3.8, 2.0, -3.9), Vector3.ONE * 0.1],
	])

static var jitter_parms = GutUtils.ParameterFactory.named_parameters(
	["movement"],
	[
		[Vector3.FORWARD *  10],
		[Vector3.FORWARD *  20],
		[Vector3.FORWARD *  40],
		[Vector3.FORWARD *  50],
		[Vector3.FORWARD * 100],
	])

static var ground_params = GutUtils.ParameterFactory.named_parameters(
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

static var overlap_params = GutUtils.ParameterFactory.named_parameters(
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
