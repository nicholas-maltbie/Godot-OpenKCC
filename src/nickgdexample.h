#ifndef NICKGDEXAMPLE_H
#define NICKGDEXAMPLE_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class NickGDExample : public Sprite2D {
	GDCLASS(NickGDExample, Sprite2D)

private:
	double time_passed;

protected:
	static void _bind_methods();

public:
	NickGDExample();
	~NickGDExample();

	void _process(double delta) override;
};

} //namespace godot

#endif