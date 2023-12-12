#ifndef OPENKCCBODY3D_H
#define OPENKCCBODY3D_H

#include <godot_cpp/classes/physics_body3D.hpp>

namespace godot {

class OpenKCCBody3D : public PhysicsBody3D {
	GDCLASS(OpenKCCBody3D, PhysicsBody3D)

protected:
	static void _bind_methods();

public:
	bool move_and_slide();

	OpenKCCBody3D();
	~OpenKCCBody3D();
};

} //namespace godot

#endif // OPENKCCBODY3D_H