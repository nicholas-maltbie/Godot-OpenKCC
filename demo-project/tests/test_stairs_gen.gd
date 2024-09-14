extends GutTest

const Stairs = preload("res://scripts/stairs.gd")

var _stairs:Stairs

func before_all():
	pass

func before_each():
	_stairs = Stairs.new()
	add_child_autofree(_stairs)

func after_each():
	pass

func after_all():
	pass

func test_stairs_one_step():
	_stairs.num_step = 1
	_stairs.step_height = 0.1
	_stairs.step_depth = 0.35
	_stairs.step_width = 1

	var mesh = _stairs.mesh
	var faces = mesh.get_faces()

	# one square for front (2 tri), top (2 tri), two for sides (4 tri), one
	# for back (2 tri) should have a total of 10 triangles. 10 tri = 30 vertices
	assert_eq(faces.size(), 30)
