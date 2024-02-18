#include "openkcc_body_3d.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void OpenKCCBody3D::move_and_slide(Vector3 movement) {
	Vector3 position = this->get_position();
	Ref<KinematicCollision3D> collision = this->move_and_collide(movement);
	if (collision.is_null())
	{
		this->set_position(position + movement);
	}
	else
	{
		this->set_position(position + collision->get_travel());
	}
}

bool OpenKCCBody3D::is_on_floor() {
	return true;
}

void OpenKCCBody3D::_bind_methods() {
	ClassDB::bind_method(D_METHOD("move_and_slide"), &OpenKCCBody3D::move_and_slide);
	ClassDB::bind_method(D_METHOD("is_on_floor"), &OpenKCCBody3D::is_on_floor);
}

OpenKCCBody3D::OpenKCCBody3D() : StaticBody3D() {
}

OpenKCCBody3D::~OpenKCCBody3D() {
	// Add your cleanup here.
}
