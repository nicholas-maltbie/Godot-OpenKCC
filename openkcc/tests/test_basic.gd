extends GutTest

const Player = preload("res://scripts/Player.gd")
var _sender = InputSender.new(Input)
var character:Player

func before_all():
	pass

func before_each():
	character = Player.new()
	var collision_body:CollisionShape3D = CollisionShape3D.new()
	var head:Node3D = Node3D.new()
	var camera:Camera3D = Camera3D.new()
	var capsule_shape:CapsuleShape3D = CapsuleShape3D.new()
	
	character.set_name("Character")
	collision_body.set_name("CollisionBody3D")
	head.set_name("Head")
	camera.set_name("Camera3d")
	
	collision_body.set_shape(capsule_shape)
	add_child(character)
	character.add_child(collision_body)
	character.add_child(head)
	head.add_child(camera)

func after_each():
	_sender.release_all()
	_sender.clear()

	character.free()

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func test_create_player():
	var start:Vector3 = character.global_position
	Input.action_press("Forward")
	simulate(character, 30, 1.0/30)
	var current:Vector3 = character.global_position
	var delta:Vector3 = current - start
	assert_between(delta.dot(Vector3.FORWARD), Player.SPEED - 1, Player.SPEED + 1)
