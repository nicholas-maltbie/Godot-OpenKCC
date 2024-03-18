extends GutTest

const Player = preload("res://scripts/player.gd")

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
	add_child_autofree(_character)

	_ground = TestUtils.add_wall(self, Vector3(10, 1, 10), Vector3(0, -0.501, 0), Vector3.ZERO, Vector3.ZERO, "Ground")

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
		Input.action_press(dir)
	simulate(_character, 30, 1.0/30)
	for dir in params.input_array:
		Input.action_release(dir)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(params.movement_dir.normalized()), Player.SPEED, 0.1)

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

## Test player fall by moving them up into the air and assert that
## they fall down at least 10 units within 2 seconds and stop when they hit the ground.
func test_player_fall():
	_character.global_position = Vector3.UP * 11
	var start:Vector3 = _character.global_position
	simulate(_character, 120, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.DOWN), 10.0, 0.1)
