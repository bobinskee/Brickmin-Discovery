class_name Utils_Models

static func _data_mesh_sync(object_list: Array, multimesh: MultiMesh, extra_data: bool = false) -> void:
	
	var list_size: int = object_list.size()
	
	if list_size == 0:
		print("No list found bruh.")
		return
	
	var transform3D_floats: int = 16 if extra_data else 12
	
	var transform_final: PackedFloat32Array = PackedFloat32Array()
	transform_final.resize(multimesh.instance_count * transform3D_floats)
	
	for i in range(list_size):
		
		var write_pos = i * transform3D_floats
		
		var object: Databody = object_list[i]
		var transform = object.transform_g
		
		for k in range(transform3D_floats):
			transform_final[write_pos + k] = Utils_Math._Transform3D_to_PackedFloat32(transform)[k]
		
	multimesh.set_buffer(transform_final)
	
"""
static func _make_meshloader(type: MeshLoader.type, instances: int, name: StringName, world_space: RID) -> MeshLoader:
	var new_mesh = MeshLoader.new()
	new_mesh.loader_type = type
	new_mesh.name = name
	
	return new_mesh
"""
static func _get_mesh(resource: Resource) -> Mesh:
	
	if not resource:
		return null
		
	if resource is Mesh:
		return resource.duplicate() 
	
	if resource is PackedScene:
		
		var new_mesh: Mesh = null
		var res_copy = resource.instantiate()
		
		if res_copy is MeshInstance3D:
			new_mesh = res_copy.mesh
			
		else:
			for i in res_copy.get_children():
				if i is MeshInstance3D:
					new_mesh = i.mesh
					break
		
		if new_mesh:
			new_mesh = new_mesh.duplicate()
		else:
			push_warning("No mesh instance 3D found within resource.")
	
		res_copy.queue_free()
		return new_mesh
	
	return null
