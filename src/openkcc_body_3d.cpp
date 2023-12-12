#include "openkcc_body_3d.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

bool OpenKCCBody3D::move_and_slide() {
	return false;
}

void OpenKCCBody3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("move_and_slide"), &OpenKCCBody3D::move_and_slide);
}

OpenKCCBody3D::OpenKCCBody3D() : PhysicsBody3D() {
}

OpenKCCBody3D::~OpenKCCBody3D() {
	// Add your cleanup here.
}
