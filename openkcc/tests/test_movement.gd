extends GutTest

const Player = preload("res://scripts/Player.gd")

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
		[ 30, Vector3.LEFT,  [4.65, 0.1], [0.95, 0.1]],
		[-30, Vector3.RIGHT, [4.65, 0.1], [0.95, 0.1]],
		[ 15, Vector3.LEFT,  [4.25, 0.1], [0.67, 0.1]],
		[-15, Vector3.RIGHT, [4.25, 0.1], [0.67, 0.1]],
		[  0, Vector3.RIGHT, [4.00, 0.1], [0.00, 0.1]],
	])

var move_params = ParameterFactory.named_parameters(
	['input_array', 'movement_dir'],
	[
		[["Forward"], Vector3.FORWARD],
		[["Back"], Vector3.BACK],
		[["Left"], Vector3.LEFT],
		[["Right"], Vector3.RIGHT],
		[["Forward", "Left"], Vector3.FORWARD + Vector3.LEFT],
		[["Forward", "Right"], Vector3.FORWARD + Vector3.RIGHT],
		[["Back", "Left"], Vector3.BACK + Vector3.LEFT],
		[["Back", "Right"], Vector3.BACK + Vector3.RIGHT],
	])

var wall_slide_params = ParameterFactory.named_parameters(
	["movement", "expected", "error"],
	[
		[Vector3.FORWARD * 10 + Vector3.UP *  5, Vector3(0, 2, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10, Vector3(0, 2, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 30 + Vector3.UP * 15, Vector3(0, 2, -4), Vector3(0.0, 0.1, 0.1)],
		[Vector3.FORWARD * 35 + Vector3.UP * 20, Vector3(0, 2, -4), Vector3(0.0, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 3, Vector3(3.2, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.RIGHT * 5, Vector3(5.2, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT * 3, Vector3(-3.2, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 10 + Vector3.UP *  5 + Vector3.LEFT * 5, Vector3(-5.2, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 3, Vector3(3.5, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.RIGHT * 5, Vector3(5.7, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT * 3, Vector3(-3.5, 2, -4), Vector3(0.1, 0.2, 0.2)],
		[Vector3.FORWARD * 20 + Vector3.UP * 10 + Vector3.LEFT * 5, Vector3(-5.7, 2, -4), Vector3(0.1, 0.2, 0.2)],
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

var _sender = InputSender.new(Input)
var _character:Player
var _ground:StaticBody3D

func before_all():
	pass

func before_each():
	_character = Player.new()
	var collision_body:CollisionShape3D = CollisionShape3D.new()
	var head:Node3D = Node3D.new()
	var camera:Camera3D = Camera3D.new()
	var capsule_shape:CapsuleShape3D = CapsuleShape3D.new()

	_character.set_name("Character")
	collision_body.set_name("CollisionBody3D")
	head.set_name("Head")
	camera.set_name("Camera3d")

	collision_body.set_shape(capsule_shape)
	collision_body.position = Vector3(0, 1, 0)

	_character.add_child(collision_body)
	_character.add_child(head)
	head.add_child(camera)
	add_child(_character)

	_ground = StaticBody3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	var box_shape:BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(10, 1, 10)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, -0.501, 0)
	_ground.set_name("Ground")
	collision_shape.set_name("CollisionShape")

	add_child(_ground)
	_ground.add_child(collision_shape)

func after_each():
	_sender.release_all()
	_sender.clear()
	if is_instance_valid(_character):
		_character.free()
	if is_instance_valid(_ground):
		_ground.free()

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_wall(size:Vector3, offset:Vector3, position:Vector3, rotation:Vector3):
	var wall = StaticBody3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	var box_shape:BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	collision_shape.position = offset
	wall.set_name("Wall")
	collision_shape.set_name("CollisionShape3D")

	wall.position = position
	wall.rotation = rotation
	wall.add_child(collision_shape)
	add_child_autofree(wall)
	return wall

## Test player movement based on input direction key presses
## and the resulting change in character position.
func test_player_move(params=use_parameters(move_params)):
	var start:Vector3 = _character.global_position
	for dir in params.input_array:
		Input.action_press(dir)
	simulate(_character, 30, 1.0/30)
	for dir in params.input_array:
		Input.action_release(dir)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(params.movement_dir.normalized()), Player.SPEED, 0.1)

## Test player standing idle and that they do not move (assuming they are standing
## on a floor).
func test_player_idle():
	var start:Vector3 = _character.global_position
	simulate(_character, 30, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.length(), 0.0, 0.001)

## Test player fall by moving them up into the air and assert that
## they fall down at least 10 units within 2 seconds and stop when they hit the ground.
func test_player_fall():
	_character.global_position = Vector3.UP * 10
	var start:Vector3 = _character.global_position
	simulate(_character, 120, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.DOWN), 10.0, 0.1)

## Test player slide accross a wall when running into it.
## Rotate the wall to various rotatinos and have the player
## walk into the wall and assert how far the player will
## bounce based on their rotation.
func test_player_slide(params=use_parameters(slide_params)):
	add_wall(Vector3(10, 3, 1), Vector3(0, 1.5, 0), Vector3(0, 0, -5), Vector3(0, params.wall_rotation, 0))
	var start:Vector3 = _character.global_position
	_character.move_and_slide(Vector3.FORWARD * 5)
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

## Test that the player is able to jump when the "Jump" action
## is pressed and they are standing on some solid surface.
## Verify that when the player jumps their vertical velocity is set to
## the jump velocity of the player.
func test_player_jump():
	simulate(_character, 1, 1.0/30.0)
	assert_almost_eq(_character.world_velocity.length(), 0.0, 0.01)
	Input.action_press("Jump")
	simulate(_character, 1, 1.0/30.0)
	assert_almost_eq(_character.world_velocity.dot(Vector3.UP), Player.JUMP_VELOCITY, 0.01)
	Input.action_release("Jump")

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
	add_wall(Vector3(10, 3, 1), Vector3(0, 1.5, 0), Vector3(0, 0, -5), Vector3(0, 0, 0))

	# Move the player up vertically towards the wall
	_character.check_grounded()
	_character.move_and_slide(params.movement)

	# Assert that the character bounces as expected
	assert_almost_eq(_character.global_position.x, params.expected.x, params.error.x)
	assert_almost_eq(_character.global_position.y, params.expected.y, params.error.y)
	assert_almost_eq(_character.global_position.z, params.expected.z, params.error.z)
