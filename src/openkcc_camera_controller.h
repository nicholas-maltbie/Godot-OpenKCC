#ifndef OPENKCC_CAMERA_CONTROLLER_H
#define OPENKCC_CAMERA_CONTROLLER_H

#include <godot_cpp/classes/node3d.hpp>

using namespace godot;

namespace openkcc {

/// @brief Camera controller for OpenKCC character.
/// @details Camera controller for OpenKCC character that can manage pitch, yaw, zoom, and vertical damping.
class OpenKCCCameraController : public Node3D {
	GDCLASS(OpenKCCCameraController, Node3D)

private:
	/// @brief Pitch of camera (in degrees).
	float pitch = 0;
	/// @brief Yaw of camera (in degrees).
	float yaw = 0;
	/// @brief Zoom of camera in game units.
	float zoom = 0;
	/// @brief Damping factor for managing camera vertical movement.
	/// A value of zero will disable damping.
	float damping_factor = 1;
	/// @brief Camera zoom bounded value.
	/// Will be set to current camera zoom value if nothing is hit.
	float bounded_zoom_distance = 1;

	/// @brief Current camera y position from damping.
	float camera_pos_y = 0;

	/// @brief Minimum camera zoom
	float min_zoom = DEFAULT_MIN_ZOOM;
	/// @brief Maximum camera zoom
	float max_zoom = DEFAULT_MAX_ZOOM;

	/// @brief Minimum pitch value (in degrees)
	float min_pitch = DEFAULT_MIN_PITCH;
	/// @brief Maximum pitch value (in degrees)
	float max_pitch = DEFAULT_MAX_PITCH;

	/// @brief Target position computed from config.
	Vector3 target_position;

protected:
	/// @brief Setup method bindings for node usage in gdscript
	static void _bind_methods();

public:
	/// @brief Constructs a new instance of OpenKCC Camera Controller
	OpenKCCCameraController();
	/// @brief Deconstructs OpenKCC Camera Controller
	~OpenKCCCameraController();

	/// @brief Compute active position and rotation.
	/// @param delta Delta time in seconds.
	void _process(double delta) override;

	/// @brief On ready and scene started.
	void _ready() override;

	/// @brief Get the target camera position.
	/// @return Camera position in world space.
	Vector3 get_target_position() const;

	/// @brief Get the target camera rotation.
	/// @return Camera rotation in world space.
	Vector3 get_target_rotation() const;

	/// @brief Get the bounded camera zoom if it hit an object.
	/// @return bounded camera zoom distance.
	float get_bounded_zoom_distance() const;

	/// @brief Sets pitch value, will be clamped between min_pitch and max_pitch.
	/// @param p_pitch Pitch value to set (in degrees).
	void set_pitch(const float p_pitch);

	/// @brief Sets the yaw value, will be bounded between 0 and 360 via modulo operator.
	/// @param p_yaw Yaw value to set (in degrees).
	void set_yaw(const float p_yaw);

	/// @brief Sets the zoom value, will be bounded between min_zoon and max_zoon.
	/// @param p_zoom Zoom distance to set (in units).
	void set_zoom(const float p_zoom);

	/// @brief Gets the current camera pitch.
	/// @return Camera pitch in degrees.
	float get_pitch() const;

	/// @brief Gets the current camera yaw.
	/// @return Camera yaw in degrees.
	float get_yaw() const;

	/// @brief Gets the current camera zoon.
	/// @return Zoom in units.
	float get_zoom() const;

	/// @brief Sets minimum pitch bound (in degrees).
	/// @param p_min_pitch Minimum pitch value (in degrees).
	void set_min_pitch(const float p_min_pitch);
	/// @brief Sets maximum pitch bound (in degrees).
	/// @param p_max_pitch Maximum pitch value (in degrees).
	void set_max_pitch(const float p_max_pitch);
	/// @brief Gets minimum pitch bound (in degrees).
	/// @return Maximum pitch value (in degrees).
	float get_min_pitch() const;
	/// @brief Gets maximum pitch bound (in degrees).
	/// @return Maximum pitch value (in degrees).
	float get_max_pitch() const;

	/// @brief Sets minimum zoom bound.
	/// @param p_min_zoom Minimum zoom bound.
	void set_min_zoom(const float p_min_zoom);
	/// @brief Sets maximum zoom bound.
	/// @param p_max_zoom Maximum zoom bound.
	void set_max_zoom(const float p_max_zoom);
	/// @brief Gets minimum zoom bound.
	/// @return Minimum zoom bound.
	float get_min_zoom() const;
	/// @brief Gets maximum zoom bound.
	/// @return Maximum zoom bound.
	float get_max_zoom() const;

	/// @brief Sets the damping factor for managing camera vertical movement.
	/// A value of zero will disable damping.
	/// @param p_damping_factor Damping factor value.
	void set_damping_factor(const float p_damping_factor);
	/// @brief Gets the damping factor for managing camera vertical movement.
	/// @return Current damping value.
	float get_damping_factor() const;

	/// @brief Maximum rotation value in degrees.
	static const float MAX_ROTATION_EULER;
	/// @brief Default minimum pitch value (in degrees).
	static const float DEFAULT_MIN_PITCH;
	/// @brief Default maximum pitch value (in degrees).
	static const float DEFAULT_MAX_PITCH;
	/// @brief Default minimum zoom value.
	static const float DEFAULT_MIN_ZOOM;
	/// @brief Default maximum zoom value.
	static const float DEFAULT_MAX_ZOOM;
};

} //namespace openkcc

#endif // OPENKCC_CAMERA_CONTROLLER_H