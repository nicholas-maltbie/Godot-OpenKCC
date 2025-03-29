extends GutTest

var camera_raycast_params = ParameterFactory.named_parameters(
	['max_zoom', 'wall_dist'],
	[
		[10,  5],
		[10,  8],
		[10, 20],
		[10,  0],
		[ 5,  3],
		[ 5,  8],
		[ 5,  0],
	])

var _camera_controller:OpenKCCCameraController

func before_each():
	_camera_controller = OpenKCCCameraController.new()
	add_child_autofree(_camera_controller)

func test_camera_properties():
	_camera_controller.pitch = 0
	_camera_controller.yaw = 0
	_camera_controller.zoom = _camera_controller.min_zoom

	assert_eq(_camera_controller.pitch, 0)
	assert_eq(_camera_controller.yaw, 0)
	assert_eq(_camera_controller.zoom, _camera_controller.min_zoom)

	# Try setting values to something out of bounds
	_camera_controller.pitch = 120
	assert_eq(_camera_controller.pitch, _camera_controller.max_pitch)
	_camera_controller.pitch = -120
	assert_eq(_camera_controller.pitch, _camera_controller.min_pitch)

	_camera_controller.yaw = 360
	assert_eq(_camera_controller.yaw, 0)
	_camera_controller.yaw = 450
	assert_eq(_camera_controller.yaw, 90)

	_camera_controller.zoom = _camera_controller.min_zoom - 1
	assert_eq(_camera_controller.zoom, _camera_controller.min_zoom)
	_camera_controller.zoom = _camera_controller.max_zoom + 1
	assert_eq(_camera_controller.zoom, _camera_controller.max_zoom)

func test_camera_damp_y():
	_camera_controller.damping_factor = 8
	assert_eq(_camera_controller.get_target_position(), _camera_controller.global_position)

	# Upon moving the camera up, target position should lag behind
	_camera_controller.global_position += Vector3.UP * 0.5
	assert_ne(_camera_controller.get_target_position(), _camera_controller.global_position)

	# Allow a process, delta should shrink
	var delta:float = (_camera_controller.get_target_position() - _camera_controller.global_position).length()
	var smaller_delta:Callable = func():
		return (_camera_controller.get_target_position() - _camera_controller.global_position).length() < delta
	await wait_until(smaller_delta, 10)

	# After enough updates, delta should shrink to zero
	var update:int = 0
	while delta > 0 and update < 3:
		await wait_seconds(0.1)
		var delta_after_update := (_camera_controller.get_target_position() - _camera_controller.global_position).length()
		assert_lt(delta_after_update, delta)
		delta = delta_after_update
		update += 1

	# Assert that delta reached zero
	var zero_delta:Callable = func(): return _is_almost_eq(delta, 0, 0.001)
	await wait_until(zero_delta, 1)

	_camera_controller.global_position += Vector3.UP * 10
	await wait_frames(10)
	assert_ne(_camera_controller.get_target_position(), _camera_controller.global_position)

	# When damping factor is zero, there should be no delay
	_camera_controller.damping_factor = 0
	await wait_frames(10)
	assert_eq(_camera_controller.global_position, _camera_controller.get_target_position())

func test_camera_raycast(params=use_parameters(camera_raycast_params)):
	# Set camera zoom to 10 units
	_camera_controller.max_zoom = params.max_zoom
	_camera_controller.zoom = params.max_zoom
	_camera_controller.global_position = Vector3.ZERO

	# Check distance
	await wait_frames(10)
	var dist:float = (_camera_controller.get_target_position() - _camera_controller.global_position).length()
	assert_almost_eq(dist, params.max_zoom, 0.001)

	# Add a box between the camera and target position for raycast to hit
	var box = TestUtils.add_wall(
		self, Vector3(1, 1, 1), Vector3(0, 0, params.wall_dist), Vector3.ZERO, Vector3.ZERO, "Box")

	# Assert that the camera is now stopped by the box
	await wait_frames(2)
	dist = (_camera_controller.get_target_position() - _camera_controller.global_position).length()

	if params.wall_dist <= 0.5:
		assert_almost_eq(dist, params.max_zoom, 0.001)
	elif params.wall_dist <= params.max_zoom:
		assert_almost_eq(dist, params.wall_dist - 0.5, 0.001)
	elif params.wall_dist >= params.max_zoom:
		assert_almost_eq(dist, params.max_zoom, 0.001)
