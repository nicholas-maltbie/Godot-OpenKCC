extends GutTest

const Player = preload("res://scripts/character.gd")

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

var _sender
var _character:Player
var _ground:StaticBody3D

func before_all():
	pass

func before_each():
	_character = Player.new()
	var head:Node3D = Node3D.new()
	var camera:Camera3D = Camera3D.new()

	_character.set_name("Character")
	head.set_name("Head")
	camera.set_name("Camera3d")

	_character.add_child(head)
	head.add_child(camera)
	add_child_autofree(_character)
	_character.global_position = Vector3(0, 1, 0)

	_ground = TestUtils.add_wall(self, Vector3(100, 1, 100), Vector3(0, -0.501, 0), Vector3.ZERO, Vector3.ZERO, "Ground")
	_sender = InputSender.new(_character)

func after_each():
	_sender.release_all()
	_sender.clear()

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Test player movement based on input direction key presses
## and the resulting change in character position.
func test_player_move(params=use_parameters(move_params)):
	var start:Vector3 = _character.global_position
	for dir in params.input_array:
		_sender.action_down(dir)
	simulate(_character, 30, 1.0/30)
	for dir in params.input_array:
		_sender.action_up(dir)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(params.movement_dir.normalized()), _character.move_speed, 0.1)

## Test that the player is able to jump when the "Jump" action
## is pressed and they are standing on some solid surface.
## Verify that when the player jumps their vertical velocity is set to
## the jump velocity of the player.
func test_player_jump():
	assert_almost_eq(_character.world_velocity.length(), 0.0, 0.01)
	_sender.action_down("Jump")
	simulate(_character, 1, 1)
	assert_almost_eq(_character.world_velocity.dot(Vector3.UP), _character.jump_velocity, 0.01)
	_sender.action_up("Jump")

## Test player fall by moving them up into the air and assert that
## they fall down at least 10 units within 2 seconds and stop when they hit the ground.
func test_player_fall():
	_character.global_position = Vector3.UP * 10
	var start:Vector3 = _character.global_position
	simulate(_character, 120, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.DOWN), 9.0, 0.1)

## Put the player on a sliding surface
## Assert that they can only jump once even if they
## are back on the ground
func test_player_jump_once():
	# have player stand on flat surface
	await TestUtils.wait_until_async(self, _character.is_on_floor, _character)
	assert_true(_character._can_jump)

	# Make surface player is standing on slanted ground and they are sliding down
	_ground.global_rotation_degrees = Vector3(0, 0, 65)
	_ground.global_position = Vector3(0, -1.6, 0)

	# Wait until player is back on floor and sliding
	await TestUtils.wait_until_async(self, _character.is_sliding, _character, 10, 0.1)

	# Once player is sliding, have them attempt a jump
	assert_true(_character._can_jump)
	assert_false(_character.moving_up())

	# After sending jump input, player should be moving up
	_sender.action_down("Jump").wait_frames(1)
	await _sender.idle
	await TestUtils.wait_until_async(self, _character.moving_up, _character)

	# Player should no longer be able to jump when they are in the air
	assert_false(_character._can_jump)
	_sender.action_up("Jump")

	# Wait until they are on the ground again, they should still no longer be able to jump
	await TestUtils.wait_until_async(self, _character.is_on_floor, _character, 10, 0.1)
	assert_false(_character._can_jump)
