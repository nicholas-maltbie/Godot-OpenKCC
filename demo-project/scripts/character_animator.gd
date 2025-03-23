class_name CharacterAnimator

const IDLE = "Idle"
const WALKING = "Walking"
const JUMPING = "Jumping"
const FALLING = "Falling"

## Animation tree with various states
var _animation_tree:AnimationTree

## Current player animation state
var _anim_state:String = IDLE

## Character body rotation speed
var _rotation_speed:float

## time spent falling
var _falling_time:float

## Threshold time before starting falling animation
var _falling_threshold_time:float = 0.1

var _body:Node3D
var _anim_state_machine:AnimationNodeStateMachinePlayback

static func create(\
	animation_tree:AnimationTree, \
	body:Node3D, \
	rotation_speed:float, \
	desired_attitude:Quaternion) -> CharacterAnimator:
	var instance = CharacterAnimator.new()

	# Setup animation state machine
	instance._animation_tree = animation_tree
	instance._anim_state_machine = animation_tree["parameters/playback"]
	instance._body = body
	instance._rotation_speed = rotation_speed

	# rotate player body in direction of camera
	instance._body.basis = desired_attitude
	return instance

func process(_input_dir:Vector2, _desired_attitude:Quaternion, _jumping:bool, _on_floor:bool, _delta:float) -> void:
	# rotate player towards direction of movement (this is just visual, so complete
	# update with each frame instead of physics update).
	var target_anim_state:String = IDLE
	var blend_position:Vector2 = _animation_tree.get("parameters/Walking/blend_position")
	if _input_dir.length() >= 0.001:
		# rotate player to face in direction of camera.
		blend_position = blend_position.move_toward(Vector2(_input_dir.x, -_input_dir.y), _delta * _rotation_speed / 360)
		var body_rotation:Quaternion = Quaternion(_body.basis)
		var delta_to_target:float = body_rotation.angle_to(_desired_attitude)
		var weight:float = min(1.0, deg_to_rad(_delta * _rotation_speed) / delta_to_target)
		_body.basis = Basis(body_rotation.slerp(_desired_attitude, weight))
		target_anim_state = WALKING
	else:
		blend_position = blend_position.move_toward(Vector2.ZERO, _delta)

	_animation_tree.set("parameters/Walking/blend_position", blend_position)

	# If player is not on ground, set target state to falling
	if _jumping:
		target_anim_state = JUMPING
		_falling_time = _falling_threshold_time
	elif _on_floor == false:
		_falling_time += _delta
		if _falling_time > _falling_threshold_time:
			target_anim_state = FALLING
	else:
		_falling_time = 0

	# Update anim state if needed
	if _anim_state != target_anim_state:
		_anim_state = target_anim_state
		_anim_state_machine.travel(_anim_state)

## Update animation for jumping action
func jump() -> void:
	_anim_state = JUMPING
	_anim_state_machine.travel(_anim_state)
