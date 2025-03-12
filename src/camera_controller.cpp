#include "camera_controller.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/physics_direct_space_state3d.hpp>
#include <godot_cpp/classes/physics_ray_query_parameters3d.hpp>
#include <godot_cpp/classes/world3d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

using namespace godot;
using namespace openkcc;

const float CameraController::MAX_ROTATION_EULER = 360.0f;

const float CameraController::DEFAULT_MIN_PITCH = -90.0f;
const float CameraController::DEFAULT_MAX_PITCH = 90.0f;

const float CameraController::DEFAULT_MIN_ZOOM = 0.0f;
const float CameraController::DEFAULT_MAX_ZOOM = 5.0f;

void CameraController::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_target_position"), &CameraController::get_target_position);
	ClassDB::bind_method(D_METHOD("get_target_rotation"), &CameraController::get_target_rotation);

	ClassDB::bind_method(D_METHOD("get_pitch"), &CameraController::get_pitch);
	ClassDB::bind_method(D_METHOD("get_yaw"), &CameraController::get_yaw);
	ClassDB::bind_method(D_METHOD("get_zoom"), &CameraController::get_zoom);

	ClassDB::bind_method(D_METHOD("set_pitch", "p_pitch"), &CameraController::set_pitch);
	ClassDB::bind_method(D_METHOD("set_yaw", "p_yaw"), &CameraController::set_yaw);
	ClassDB::bind_method(D_METHOD("set_zoom", "p_zoom"), &CameraController::set_zoom);

	ClassDB::bind_method(D_METHOD("get_min_pitch"), &CameraController::get_min_pitch);
	ClassDB::bind_method(D_METHOD("get_max_pitch"), &CameraController::get_max_pitch);
	ClassDB::bind_method(D_METHOD("set_min_pitch", "p_min_pitch"), &CameraController::set_min_pitch);
	ClassDB::bind_method(D_METHOD("set_max_pitch", "p_max_pitch"), &CameraController::set_max_pitch);

	ClassDB::bind_method(D_METHOD("get_min_zoom"), &CameraController::get_min_zoom);
	ClassDB::bind_method(D_METHOD("get_max_zoom"), &CameraController::get_max_zoom);
	ClassDB::bind_method(D_METHOD("set_min_zoom", "p_min_zoom"), &CameraController::set_min_zoom);
	ClassDB::bind_method(D_METHOD("set_max_zoom", "p_max_zoom"), &CameraController::set_max_zoom);

	ClassDB::bind_method(D_METHOD("get_damping_factor"), &CameraController::get_damping_factor);
	ClassDB::bind_method(D_METHOD("set_damping_factor", "p_damping_factor"), &CameraController::set_damping_factor);

	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "pitch"), "set_pitch", "get_pitch");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "yaw"), "set_yaw", "get_yaw");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "zoom"), "set_zoom", "get_zoom");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_pitch"), "set_min_pitch", "get_min_pitch");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_pitch"), "set_max_pitch", "get_max_pitch");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_zoom"), "set_min_zoom", "get_min_zoom");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_zoom"), "set_max_zoom", "get_max_zoom");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "damping_factor"), "set_damping_factor", "get_damping_factor");
}

CameraController::CameraController() :
		Node3D() {
}

CameraController::~CameraController() {
}

void CameraController::_ready() {
	camera_pos_y = get_global_position().y;
}

void CameraController::_process(double delta) {
	Vector3 camera_source = get_global_position();
	if (damping_factor > 0) {
		// Use damping factor if configured.
		float current_value = camera_pos_y;
		float target_value = camera_source.y;
		float difference = target_value - current_value;
		current_value += difference * damping_factor * delta;
		camera_pos_y = CLAMP(current_value, MIN(camera_pos_y, target_value), MAX(camera_pos_y, target_value));
	} else {
		camera_pos_y = camera_source.y;
	}

	Quaternion dir = Quaternion(get_target_rotation());
	target_position = Vector3(camera_source.x, camera_pos_y, camera_source.z) + dir.xform(Vector3(0, 0, zoom));

	// Bound target position using raycast from camera source
	Ref<PhysicsRayQueryParameters3D> query = PhysicsRayQueryParameters3D::create(camera_source, target_position);
	Dictionary result = get_world_3d()->get_direct_space_state()->intersect_ray(query);
	if (!result.is_empty()) {
		target_position = result["position"];
	}
}

Vector3 CameraController::get_target_position() const {
	return target_position;
}

Vector3 CameraController::get_target_rotation() const {
	return Vector3(get_pitch(), get_yaw(), 0);
}

void CameraController::set_pitch(const float p_pitch) {
	pitch = CLAMP(p_pitch, min_pitch, max_pitch);
}

void CameraController::set_yaw(const float p_yaw) {
	yaw = fmod(p_yaw, MAX_ROTATION_EULER);
}

void CameraController::set_zoom(const float p_zoom) {
	zoom = CLAMP(p_zoom, min_zoom, max_zoom);
}

float CameraController::get_pitch() const {
	return pitch;
}

float CameraController::get_yaw() const {
	return yaw;
}

float CameraController::get_zoom() const {
	return zoom;
}

void CameraController::set_min_pitch(const float p_min_pitch) {
	min_pitch = p_min_pitch;
}

float CameraController::get_min_pitch() const {
	return min_pitch;
}

void CameraController::set_max_pitch(const float p_max_pitch) {
	max_pitch = p_max_pitch;
}

float CameraController::get_max_pitch() const {
	return max_pitch;
}

void CameraController::set_min_zoom(const float p_min_zoom) {
	min_zoom = p_min_zoom;
}

float CameraController::get_min_zoom() const {
	return min_zoom;
}

void CameraController::set_max_zoom(const float p_max_zoom) {
	max_zoom = p_max_zoom;
}

float CameraController::get_max_zoom() const {
	return max_zoom;
}

void CameraController::set_damping_factor(const float p_damping_factor) {
	damping_factor = p_damping_factor;
}

float CameraController::get_damping_factor() const {
	return damping_factor;
}
