extends GutTest

const Player = preload("res://scripts/Player.gd")
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

	_character.add_child(collision_body)
	_character.add_child(head)
	head.add_child(camera)
	add_child(_character)
	
	_ground = StaticBody3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	var box_shape:BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(10, 1, 10)
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(0, -0.5, 0)
	_ground.set_name("Ground")
	collision_shape.set_name("CollisionShape")

	add_child(_ground)
	_ground.add_child(collision_shape)

func after_each():
	_sender.release_all()
	_sender.clear()
	_character.free()
	_ground.free()

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var move_params = [
	[["Forward"], Vector3.FORWARD],
	[["Back"], Vector3.BACK],
	[["Left"], Vector3.LEFT],
	[["Right"], Vector3.RIGHT],
	[["Forward", "Left"], Vector3.FORWARD + Vector3.LEFT],
	[["Forward", "Right"], Vector3.FORWARD + Vector3.RIGHT],
	[["Back", "Left"], Vector3.BACK + Vector3.LEFT],
	[["Back", "Right"], Vector3.BACK + Vector3.RIGHT]]

func test_player_move(params=use_parameters(move_params)):
	var start:Vector3 = _character.global_position
	var dirs = params[0]
	var expected = params[1]
	for dir in dirs:
		Input.action_press(dir)
	simulate(_character, 30, 1.0/30)
	for dir in dirs:
		Input.action_release(dir)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(expected.normalized()), Player.SPEED, 0.1)

func test_player_idle():
	var start:Vector3 = _character.global_position
	simulate(_character, 30, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.length(), 0.0, 0.001)

func test_player_fall():
	_character.global_position = Vector3.UP * 11
	var start:Vector3 = _character.global_position
	simulate(_character, 120, 1.0/30)
	var current:Vector3 = _character.global_position
	var delta:Vector3 = current - start
	assert_almost_eq(delta.dot(Vector3.DOWN), 10.0, 0.1)
