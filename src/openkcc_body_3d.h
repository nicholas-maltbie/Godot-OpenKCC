#ifndef OPENKCCBODY3D_H
#define OPENKCCBODY3D_H

#include <godot_cpp/classes/static_body3d.hpp>

namespace godot {

class OpenKCCBody3D : public StaticBody3D {
	GDCLASS(OpenKCCBody3D, StaticBody3D)

protected:
	static void _bind_methods();

public:
	void move_and_slide(Vector3 movement);
	bool is_on_floor();

	OpenKCCBody3D();
	~OpenKCCBody3D();
};

} //namespace godot

#endif // OPENKCCBODY3D_H