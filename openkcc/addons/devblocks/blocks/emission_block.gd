@tool
extends ColoredBlock
class_name EmissionBlock


@export_range(0.0, 4.0) var emission_energy : float = 1.0 :
	set(value):
		emission_energy = value
		_update_mesh()

func _ready() -> void:
	super._ready()
	$Mesh.get_surface_override_material(0).set("emission_enabled", true)
	

func _update_mesh() -> void:
	super._update_mesh()
	$Mesh.get_surface_override_material(0).set("emission", block_color)
	$Mesh.get_surface_override_material(0).set("emission_energy", emission_energy)
