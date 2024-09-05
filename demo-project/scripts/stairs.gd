@tool
class_name Stairs
extends Node3D

## Number of steps to include
@export_range(0, 20, 1, "or_greater") var num_step:int = 10:
	get:
		return num_step
	set(value):
		if value > 0 and value != num_step:
			num_step = value
			_build_mesh()

## height of each step
@export var step_height:float = 0.2:
	get:
		return step_height
	set(value):
		if value != step_height:
			step_height = value
			_build_mesh()

## depth of each step
@export var step_depth:float = 0.35:
	get:
		return step_depth
	set(value):
		if value != step_depth:
			step_depth = value
			_build_mesh()

## depth of each step
@export var step_width:float = 1:
	get:
		return step_width
	set(value):
		if value != step_width:
			step_width = value
			_build_mesh()

## Object for the stairs as a child to this
@export var _stairs_obj:Node3D

func _enter_tree() -> void:
	if _stairs_obj.get_parent() != self:
		_stairs_obj = find_child("StairsBody")
	_build_mesh_if_none_exists()

func _add_square(vertices:PackedVector3Array, v1:Vector3, v2:Vector3, v3:Vector3, v4:Vector3) -> void:
	vertices.push_back(v1)
	vertices.push_back(v2)
	vertices.push_back(v3)

	vertices.push_back(v3)
	vertices.push_back(v4)
	vertices.push_back(v1)

func _build_mesh_if_none_exists() -> void:
	if _stairs_obj == null:
		_build_mesh()

func _build_mesh() -> void:
	if !is_node_ready():
		return
	
	if _stairs_obj != null:
		_stairs_obj.free()
	
	var vertices = PackedVector3Array()
	var mat = StandardMaterial3D.new()
	var color = Color(0.6, 0.6, 0.6)
	mat.albedo_color = color
	
	for step in num_step:
		# Build each step as two sets of squares
		# one on the front, one on the back
		var left:float = 0
		var right:float = step_width
		var top:float = (step + 1) * step_height
		var bottom:float = step * step_height
		var front:float = step * step_depth
		var back:float = (step + 1) * step_depth

		var front_bottom_line := Line3D.new(Vector3(left, bottom, front), Vector3(right, bottom, front))
		var front_top_line := Line3D.new(Vector3(left, top, front), Vector3(right, top, front))
		var back_top_line := Line3D.new(Vector3(left, top, back), Vector3(right, top, back))
		var base_back_line := Line3D.new(Vector3(left, 0, back), Vector3(right, 0, back))
		var base_front_line := Line3D.new(Vector3(left, 0, front), Vector3(right, 0, front))
		
		# Add front face
		_add_square(vertices, front_bottom_line.v2, front_top_line.v2, front_top_line.v1, front_bottom_line.v1)
		
		# Add top face
		_add_square(vertices, front_top_line.v2, back_top_line.v2, back_top_line.v1, front_top_line.v1)

		# Add side faces
		_add_square(vertices, front_top_line.v1, back_top_line.v1, base_back_line.v1, base_front_line.v1)
		_add_square(vertices, base_front_line.v2, base_back_line.v2, back_top_line.v2, front_top_line.v2)
		
		# Add back face if last step
		if step == num_step - 1:
			_add_square(vertices, base_back_line.v1, back_top_line.v1, back_top_line.v2, base_back_line.v2)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	
	for v in vertices.size(): 
		st.add_vertex(vertices[v])

	# Add generated mesh to this object
	var mesh_instance = MeshInstance3D.new()
	st.generate_normals()
	mesh_instance.mesh = st.commit()

	var static_body = StaticBody3D.new()
	var collision_body = CollisionShape3D.new()
	var shape_3d = ConcavePolygonShape3D.new()
	shape_3d.set_faces(vertices)
	collision_body.shape = shape_3d

	add_child(static_body)
	static_body.add_child(collision_body)
	static_body.add_child(mesh_instance)

	if Engine.is_editor_hint():
		static_body.owner = get_tree().edited_scene_root
		collision_body.owner = get_tree().edited_scene_root
		mesh_instance.owner = get_tree().edited_scene_root

	var existing = find_child("StairsBody")
	if existing != null:
		existing.free()

	static_body.name = "StairsBody"
	_stairs_obj = static_body

class Line3D:
	var v1:Vector3
	var v2:Vector3

	func _init(v1:Vector3, v2:Vector3):
		self.v1 = v1
		self.v2 = v2
