@tool
class_name Stairs
extends Node3D

## Number of steps to include
@export_range(0, 20, 1, "or_greater") var num_step:int = 10:
	get:
		return num_step
	set(value):
		if value <= 0:
			return
		var previous = num_step
		num_step = value
		_build_on_set(previous, num_step)

## Height of each step
@export var step_height:float = 0.2:
	get:
		return step_height
	set(value):
		var previous = step_height
		step_height = value
		_build_on_set(previous, step_height)

## Depth of each step
@export var step_depth:float = 0.35:
	get:
		return step_depth
	set(value):
		var previous = step_depth
		step_depth = value
		_build_on_set(previous, step_depth)

## Width of each step
@export var step_width:float = 1:
	get:
		return step_width
	set(value):
		var previous = step_width
		step_width = value
		_build_on_set(previous, step_width)

## Include sides for each step
@export var include_side_faces:bool = true:
	get:
		return include_side_faces
	set(value):
		var previous = include_side_faces
		include_side_faces = value
		_build_on_set(previous, include_side_faces)

## Include square for back of staircase
@export var include_back_face:bool = true:
	get:
		return include_back_face
	set(value):
		var previous = include_back_face
		include_back_face = value
		_build_on_set(previous, include_back_face)

## Include bottom face for staircase
@export var include_bottom_face:bool = false:
	get:
		return include_bottom_face
	set(value):
		var previous = include_bottom_face
		include_bottom_face = value
		_build_on_set(previous, include_bottom_face)

## Should the mesh be saved to the scene. Enabling this option saves the mesh
## data to the .tscn file. This will speed up loading times and allow for
## the mesh to be loaded instantly with the scene and not need to be
## re-generated every time this object is created. However, this mesh data
## can be qutie large and make the scene file much larger than expected.
##
## Enabled by default to allow for fast loading
@export var save_mesh:bool = true:
	get:
		return save_mesh
	set(value):
		var previous = save_mesh
		save_mesh = value
		_build_on_set(previous, value)

## Texture for stairs
@export var texture:Texture2D:
	get:
		return texture
	set(value):
		var previous = texture
		texture = value
		_build_on_set(previous, value)

## Debug value to control whether the mesh is updated
## time a value is set.
var _update_on_set=true

func force_update_mesh() -> void:
	# Setup arrays for vertices nad UF
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()

	# Setup material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	mat.albedo_texture = texture
	mat.vertex_color_use_as_albedo = true

	# Build mesh step by step
	var uv_offset = Vector2(step_width, 1)
	var left:float = 0
	var right:float = step_width
	for step in num_step:
		# Build each step as two sets of squares
		# one on the front, one on the back
		var bottom:float = step * step_height
		var top:float = (step + 1) * step_height
		var front:float = step * step_depth
		var back:float = (step + 1) * step_depth

		# Add front face
		_add_square(vertices, Vector3(right, bottom, front), Vector3(right, top, front), \
			Vector3(left, top, front), Vector3(left, bottom, front))
		_add_square_uv(uvs, Vector2(right, bottom), Vector2(right, top), \
			Vector2(left, top), Vector2(left, bottom), uv_offset)

		# Add top face
		_add_square(vertices, Vector3(right, top, front), Vector3(right, top, back), \
			Vector3(left, top, back), Vector3(left, top, front))
		_add_square_uv(uvs, Vector2(right, front), Vector2(right, back), \
			Vector2(left, back), Vector2(left, front), uv_offset)

		# Add side faces
		if include_side_faces:
			# Left side
			_add_square(vertices, Vector3(left, top, front), Vector3(left, top, back), \
				Vector3(left, 0, back), Vector3(left, 0, front))
			_add_square_uv(uvs, Vector2(front, top), Vector2(back, top), \
				Vector2(back, 0), Vector2(front, 0), uv_offset)

			# Right side
			_add_square(vertices, Vector3(right, 0, front), Vector3(right, 0, back), \
				Vector3(right, top, back), Vector3(right, top, front))
			_add_square_uv(uvs, Vector2(front, 0), Vector2(back, 0), \
				Vector2(back, top), Vector2(front, top), uv_offset)

		# If on the last step
		if step == num_step - 1:
			# Add back face if last step
			if include_back_face:
				_add_square(vertices, Vector3(left, 0, back), Vector3(left, top, back), \
					Vector3(right, top, back), Vector3(right, 0, back))
				_add_square_uv(uvs, Vector2(right, 0), Vector2(right, top), \
					Vector2(left, top), Vector2(left, 0), uv_offset)

			# Add bottom face if needed
			if include_bottom_face:
				_add_square(vertices, Vector3(left, 0, 0), Vector3(left, 0, back), \
					Vector3(right, 0, back), Vector3(right, 0, 0))
				_add_square_uv(uvs, Vector2(right, 0), Vector2(right, back), \
					Vector2(left, back), Vector2(left, 0), uv_offset)

	# Build mesh from vertices and UV values
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(mat)
	for idx in vertices.size():
		st.set_color(mat.albedo_color)
		st.set_uv(uvs[idx])
		st.add_vertex(vertices[idx])

	# Add generated mesh to this object
	st.generate_normals()
	st.generate_tangents()
	var static_body:StaticBody3D = null
	var collision_body:CollisionShape3D = null
	var mesh_instance:MeshInstance3D = null

	for child in get_children():
		if child is MeshInstance3D:
			mesh_instance = child
			break

	# Setup mesh instance 3d child
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)

	mesh_instance.mesh = st.commit()

	for child in get_children():
		if child is StaticBody3D:
			static_body = child
			break

	if static_body == null:
		static_body = StaticBody3D.new()
		add_child(static_body)

	for child in static_body.get_children():
		if child is CollisionShape3D:
			collision_body = child
			break

	if collision_body == null:
		collision_body = CollisionShape3D.new()
		static_body.add_child(collision_body)

	var shape_3d = ConcavePolygonShape3D.new()
	shape_3d.set_faces(vertices)
	collision_body.shape = shape_3d

	if Engine.is_editor_hint():
		if save_mesh and is_inside_tree():
			var root = get_tree().edited_scene_root
			mesh_instance.owner = root
			static_body.owner = root
			collision_body.owner = root
		elif not save_mesh:
			mesh_instance.owner = null
			static_body.owner = null
			collision_body.owner = null

## Upon object entering the scene, build the mesh.
func _ready() -> void:
	var stairs:MeshInstance3D = null
	for child in get_children():
		if child is MeshInstance3D:
			stairs = child
			break

	if stairs == null:
		_build_mesh()

## Check if property has changed and update if configured.
func _build_on_set(previous, new) -> void:
	if is_node_ready() and previous != new and _update_on_set:
		_build_mesh()

## Helper method to add a square to a set of PackedVector3Array as two triangles.
func _add_square(vertices:PackedVector3Array, v1:Vector3, v2:Vector3, v3:Vector3, v4:Vector3) -> void:
	vertices.push_back(v1)
	vertices.push_back(v2)
	vertices.push_back(v3)

	vertices.push_back(v3)
	vertices.push_back(v4)
	vertices.push_back(v1)

## Helper method to add a square to a UV map as two triangles.
func _add_square_uv(uvs:PackedVector2Array, v1:Vector2, v2:Vector2, v3:Vector2, v4:Vector2, uv_offset:Vector2) -> void:
	uvs.push_back(uv_offset - v1)
	uvs.push_back(uv_offset - v2)
	uvs.push_back(uv_offset - v3)

	uvs.push_back(uv_offset - v3)
	uvs.push_back(uv_offset - v4)
	uvs.push_back(uv_offset - v1)

## Create mesh if node is ready, cancel otherwise.
func _build_mesh() -> void:
	force_update_mesh()
