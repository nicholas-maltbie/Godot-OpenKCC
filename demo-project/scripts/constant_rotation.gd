extends PhysicsBody3D

@export var rotation_rate:Vector3 = Vector3(0, 30, 0)

func _process(delta):
	global_rotation_degrees += delta * rotation_rate
