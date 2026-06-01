class_name MeshLoader

enum type { BUD, ENEMY }

var loader_type: type
var name: StringName = ""

var multimesh_RID: RID
var instance_RID: RID 

var mesh_reference: RID

var transform_list: PackedFloat32Array

var setup_complete: bool = false

func _initialize_self(world: RID, instances: int, mesh_to_use: Mesh) -> void:
	
	if setup_complete:
		push_warning("This meshloader has already been set up.")
		return
	
	if not mesh_to_use:
		push_error("Can't find the mesh that's supposed to be used!")
		return
	
	if not world or not world.is_valid():
		push_error("Something's wrong with the world space!")
		return
	
	mesh_reference = RenderingServer.mesh_create()
	
	for k in mesh_to_use.get_surface_count():
		var surfaces: Array = mesh_to_use.surface_get_arrays(k)
		var mesh_type: RenderingServer.PrimitiveType
		
		if mesh_to_use.has_method("surface_get_primitive_type"):
			mesh_type = mesh_to_use.surface_get_primitive_type(k)
			#print("The mesh is not a primitive.")
		
		elif mesh_to_use is PrimitiveMesh:
			mesh_type = RenderingServer.PRIMITIVE_TRIANGLES
			#print("The mesh is a primitive.")
		
		else:
			mesh_type = RenderingServer.PRIMITIVE_TRIANGLES
			#print("Defaulting the primitve type to PRIMITIVE_TRIANGLES.")
		
		RenderingServer.mesh_add_surface_from_arrays(mesh_reference, mesh_type, surfaces)
	
	multimesh_RID = RenderingServer.multimesh_create()
	instance_RID = RenderingServer.instance_create()
	
	RenderingServer.instance_set_base(instance_RID, multimesh_RID)
	RenderingServer.instance_set_scenario(instance_RID, world)
	RenderingServer.multimesh_allocate_data(multimesh_RID, instances, RenderingServer.MULTIMESH_TRANSFORM_3D)
	RenderingServer.multimesh_set_mesh(multimesh_RID, mesh_reference)
	
	setup_complete = true

#func _sync_meshes()
#	if General_Bud.

func _remove_self() -> void:
	
	if multimesh_RID.is_valid():
		RenderingServer.free_rid(multimesh_RID)
	
	if instance_RID.is_valid():
		RenderingServer.free_rid(instance_RID)
		
	if mesh_reference.is_valid():
		RenderingServer.free_rid(mesh_reference)
