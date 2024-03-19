class_name TestUtils

static func add_wall(gut_test:GutTest, size:Vector3, offset:Vector3, position:Vector3,
		rotation:Vector3, wall_name:String="Wall"):
	var wall = StaticBody3D.new()
	var collision_shape:CollisionShape3D = CollisionShape3D.new()
	var box_shape:BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	collision_shape.position = offset
	wall.set_name(wall_name)
	collision_shape.set_name("CollisionShape3D")

	wall.position = position
	wall.rotation = rotation
	wall.add_child(collision_shape)
	gut_test.add_child_autofree(wall)
	return wall
