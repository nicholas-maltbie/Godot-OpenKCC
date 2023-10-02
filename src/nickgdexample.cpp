#include "nickgdexample.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void NickGDExample::_bind_methods() {
}

NickGDExample::NickGDExample() {
	// Initialize any variables here.
	time_passed = 0.0;
}

NickGDExample::~NickGDExample() {
	// Add your cleanup here.
}

void NickGDExample::_process(double delta) {
	time_passed += delta;

	float posx = 10.0 + (10.0 * sin(time_passed * 2.0));
	float posy = 10.0 + (10.0 * cos(time_passed * 1.5));
	Vector2 new_position = Vector2(posx, posy);

	set_position(new_position);
}