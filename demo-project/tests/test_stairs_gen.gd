extends GutTest

var step_height_values = [0.1, 0.2, 0.3]
var step_depth_values = [0.25, 0.35, 0.45]
var step_width_values = [1, 1.5, 2.0]
var num_step_values = [2, 5, 10]

var stairs_param = ParameterFactory.named_parameters(
	['step_height', 'step_depth', 'step_width', 'include_back', 'include_sides', 'include_bottom'],
	get_step_params())

var staircase_param = ParameterFactory.named_parameters(
	['num_step', 'step_height', 'step_depth', 'step_width'],
	get_staircase_params())

var _stairs:Stairs

func get_step_params():
	var step_param_values = []
	for step_height_val in step_height_values:
		for step_depth_val in step_depth_values:
			for step_width_val in step_width_values:
				for include_back in [true, false]:
					for include_side in [true, false]:
						for include_bottom in [true, false]:
							step_param_values.append(\
		[step_height_val, step_depth_val, step_width_val, include_back, include_side, include_bottom])
	return step_param_values

func get_staircase_params():
	var staircase_params_values = []
	for step_param in get_step_params().slice(0, 5):
		for num_step_val in num_step_values:
			staircase_params_values.append([num_step_val] + step_param)
	return staircase_params_values

func before_each():
	_stairs = Stairs.new()
	_stairs.save_mesh = false
	add_child_autofree(_stairs)

## Test generating a single step will result in the expected shape
## A box with a front, sides, and top of the expected size.
func test_stairs_one_step(params=use_parameters(stairs_param)):
	_stairs._update_on_set = false
	_stairs.num_step = 1
	_stairs.step_height = params.step_height
	_stairs.step_depth = params.step_depth
	_stairs.step_width = params.step_width
	_stairs.include_back_face = params.include_back
	_stairs.include_side_faces = params.include_sides
	_stairs.include_bottom_face = params.include_bottom
	_stairs.force_update_mesh()

	var mesh = _stairs.get_child(0).mesh
	var faces = mesh.get_faces()

	var top_faces = 2
	var front_faces = 2
	var back_faces = 2 if params.include_back else 0
	var bottom_faces = 2 if params.include_bottom else 0
	var side_faces = 4 if params.include_sides else 0
	var total_faces = top_faces + front_faces + back_faces + bottom_faces + side_faces
	assert_eq(faces.size(), total_faces * 3)

	_verify_single_step(_stairs, 0)

## Test generating a staircase of size n works as expected
func test_staircase_gen(params=use_parameters(staircase_param)):
	_stairs._update_on_set = false
	_stairs.num_step = params.num_step
	_stairs.step_height = params.step_height
	_stairs.step_depth = params.step_depth
	_stairs.step_width = params.step_width
	_stairs.include_back_face = true
	_stairs.include_side_faces = true
	_stairs.include_bottom_face = false
	_stairs.force_update_mesh()

	# each step has one square for front (2 tri), top (2 tri), and two for sides (4 tri)
	# Plus one for back (2 tri)
	var expected_face_count = (2 + 2 + 4) * params.num_step + 2
	var faces = _stairs.get_child(0).mesh.get_faces()
	assert_eq(faces.size() / 3, expected_face_count)

	for step_idx in params.num_step:
		_verify_single_step(_stairs, step_idx)

func _verify_single_step(stairs:Stairs, step_idx:int):
	var back_plane = (step_idx + 1) * stairs.step_depth
	var front_plane = (step_idx) * stairs.step_depth
	var front_plane_previous = (step_idx - 1) * stairs.step_depth
	var back_plane_next = (step_idx + 2) * stairs.step_depth
	var left_plane = stairs.step_width
	var right_plane = 0
	var top_plane = (step_idx + 1) * stairs.step_height
	var top_next_step = (step_idx + 2) * stairs.step_height

	var face_count := {"front": 0, "back":0, "left": 0, "right":0, "top": 0, "bottom": 0}
	var faces = _stairs.get_child(0).mesh.get_faces()

	# find the triangles for each face
	var valid_faces := true
	for face_idx in faces.size() / 3:
		var v1 = faces[face_idx * 3]
		var v2 = faces[face_idx * 3 + 1]
		var v3 = faces[face_idx * 3 + 2]

		# vertices should either be along front plane, side plane, or back plane
		# Front/back plane, at same depth along z axis
		# Side plane, at same depth along x axis
		# Top plane, at the same height
		var front = _is_almost_eq(v1.z, v2.z, 0.001) and _is_almost_eq(v2.z, v3.z, 0.001)
		var side = _is_almost_eq(v1.x, v2.x, 0.001) and _is_almost_eq(v2.x, v3.x, 0.001)
		var top = _is_almost_eq(v1.y, v2.y, 0.001) and _is_almost_eq(v2.y, v3.y, 0.001)

		if front:
			valid_faces = valid_faces and not (side or top)
			if _is_almost_eq(v1.z, front_plane, 0.001):
				face_count["front"] += 1
			elif _is_almost_eq(v1.z, back_plane, 0.001):
				# Ignore back face of subsequent steps
				if _is_almost_eq(v1.y, top_next_step, 0.001) or \
					_is_almost_eq(v2.y, top_next_step, 0.001) or \
					_is_almost_eq(v3.y, top_next_step, 0.001):
					continue
				face_count["back"] += 1

		if side:
			valid_faces = valid_faces and not(front or top)
			# only include sides that share an edge with this step.
			if not (_is_almost_eq(v1.z, front_plane, 0.001) or \
				_is_almost_eq(v2.z, front_plane, 0.001) or \
				_is_almost_eq(v3.z, front_plane, 0.001)):
				continue
			# Ignore side faces of subsequent or previous steps
			if _is_almost_eq(v1.z, front_plane_previous, 0.001) or \
				_is_almost_eq(v2.z, front_plane_previous, 0.001) or \
				_is_almost_eq(v3.z, front_plane_previous, 0.001) or \
				_is_almost_eq(v1.z, back_plane_next, 0.001) or \
				_is_almost_eq(v2.z, back_plane_next, 0.001) or \
				_is_almost_eq(v3.z, back_plane_next, 0.001):
				continue
			if _is_almost_eq(v1.x, left_plane, 0.001):
				face_count["left"] += 1
			elif _is_almost_eq(v1.x, right_plane, 0.001):
				face_count["right"] += 1

		if top:
			valid_faces = valid_faces and not(front or side)
			# Top face
			if _is_almost_eq(v1.y, top_plane, 0.001):
				face_count["top"] += 1
			# Bottom face
			if _is_almost_eq(v1.y, 0, 0.001):
				face_count["bottom"] += 1

	# Assert face counts
	var valid_step := true
	valid_step = valid_step and face_count["front"] == 2
	valid_step = valid_step and face_count["top"] == 2

	var expected_sides:int = 2 if stairs.include_side_faces else 0;
	valid_step = valid_step and face_count["left"] == expected_sides
	valid_step = valid_step and face_count["right"] == expected_sides

	if step_idx == stairs.num_step - 1:
		var expected_bottom:int = 2 if stairs.include_bottom_face else 0;
		var expected_back:int = 2 if stairs.include_back_face else 0;
		valid_step = valid_step and face_count["back"] == expected_back
		valid_step = valid_step and face_count["bottom"] == expected_bottom
	else:
		valid_step = valid_step and face_count["back"] == 0
		valid_step = valid_step and face_count["bottom"] == 0

	assert_true(valid_faces and valid_step)
