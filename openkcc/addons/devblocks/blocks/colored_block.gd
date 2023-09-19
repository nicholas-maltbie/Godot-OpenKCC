@tool
extends BasicBlock
class_name ColoredBlock


@export var block_color : Color = Color.WHITE :
	set(value):
		block_color = value
		_update_mesh()


func _update_mesh() -> void:
	super._update_mesh()
	if $Mesh.get_surface_override_material(0):
		$Mesh.get_surface_override_material(0).set("albedo_color", block_color)
