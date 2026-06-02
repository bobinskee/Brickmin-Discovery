extends RefCounted
class_name Utils_Bud



static var idle_state: BudState = preload("res://brickbuds/bud_states/idle_state.gd").new()
static var follow_state: BudState = preload("res://brickbuds/bud_states/follow_state.gd").new()
static var airborne_state: BudState = preload("res://brickbuds/bud_states/airborne_state.gd").new()
#static var follow_v2: BudnState = preload("res://brickbuds/bud_states/followstate_v2.gd").new() 

static var model: RID

static var spatial_grid: Dictionary = {}
const grid_size: float = 1

static var mm: MultiMesh = MultiMesh.new()

##Return a normalized vector pointing away from any too-close neighbors.
static func setup_spatial_grid(all_buds: Array) -> void:
	
	spatial_grid.clear()
	
	for bud in all_buds:
	
		var grid_pos = Vector2i(bud.global_position.x / grid_size, bud.global_position.z / grid_size)
		
		if not spatial_grid.has(grid_pos):
			spatial_grid[grid_pos] = []
		
		spatial_grid[grid_pos].append(bud)

static func get_repel_vector(bud: CharacterBody3D, check_cap: int) -> Vector3:
	
	var repel_vector = Vector3.ZERO
	
	var bud_pos = Vector2i(floori(bud.global_position.x / grid_size), floori(bud.global_position.z / grid_size))
	
	var checked_buds: int = 0
	
	for x in range(3):
		for z in range(3):
			var curr_pos = bud_pos + Vector2i(x - 1, z - 1)
			
			if spatial_grid.has(curr_pos):
				for other in spatial_grid[curr_pos]:
					if other == bud:
						continue
					
					if checked_buds >= check_cap:
						break
					
					var difference = bud.global_position - other.global_position
					
					if difference.length_squared() < 0.0001:
						repel_vector += Vector3(randf() - 0.5, 0, randf() - 0.5)
						checked_buds += 1
					
					elif difference.length_squared() < pow(grid_size, 2):
						repel_vector += difference.normalized()
						checked_buds += 1
		
		if checked_buds >= check_cap:
			break
	
	return repel_vector

static func cliff_slide(cur_move: Vector3, normals: Array) -> Vector3:
	
	var new_norms = []
	var combined_norm = Vector3.ZERO
	var new_vector = Vector3.ZERO
	
	for i in range(2):
		#var cur_norm = min_data["normals"][i]
		var cur_norm = normals[i]
		
		if cur_norm != Vector3.ZERO and not cur_norm in new_norms:
			new_norms.append(cur_norm)
			combined_norm += cur_norm
		
	if cur_move and combined_norm:
		combined_norm = combined_norm.normalized()
		
		if combined_norm.dot(cur_move) > 0:
			new_vector = cur_move.slide(combined_norm)
	
	return new_vector

#region : Type setting

static func _set_active_types(type_list: PackedInt32Array) -> void:
	
	for i in type_list:
		
		#Check if the current type being checked is considered active (greater than 0).
		if type_list[i - 1] > 0:
			
			var type_name = General_Bud.types_list.find_key(i - 1)
			
			if General_Bud.all_types.has(type_name):
				
				if General_Bud.all_types[type_name]["active"] != true:
					General_Bud.all_types[type_name]["active"] = true
					#print(type_name + " has been activated.")

static func _reset_active_types() -> void:
	
	for i in General_Bud.types_list.size():
		
		var type_name = General_Bud.types_list.find_key(i)
		
		if General_Bud.all_types[type_name]["active"] != false:
			General_Bud.all_types[type_name]["active"] = false
			#print(type_name + " has been reset.")

#endregion : Type setting

static func _new_bud(index: int, world_space: RID, spawn_pos: Vector3 = Vector3.ZERO) -> Brickbud:
	
	var new_bud = Brickbud.new()
	
	if new_bud:
		
		new_bud.body_RID = PhysicsServer3D.body_create()
		new_bud.shape_RID = PhysicsServer3D.capsule_shape_create()
		
		new_bud.bud_id = index
		new_bud.transform_g.origin = spawn_pos
		new_bud.behavior = BehaviorLoader.IDLE
		
		PhysicsServer3D.shape_set_data(new_bud.shape_RID, BudStats.stats[new_bud.type]["shape_scale"])
		
		PhysicsServer3D.body_set_space(new_bud.body_RID, world_space)
		
		PhysicsServer3D.body_set_mode(new_bud.body_RID, PhysicsServer3D.BODY_MODE_KINEMATIC)
		
		PhysicsServer3D.body_set_state(new_bud.body_RID, PhysicsServer3D.BODY_STATE_TRANSFORM, new_bud.transform_g)
		
		PhysicsServer3D.body_add_shape(new_bud.body_RID, new_bud.shape_RID) #Index of 0
		
		PhysicsServer3D.body_set_collision_mask(new_bud.body_RID, Utils_Math._bitshift_left(1))
		PhysicsServer3D.body_set_collision_layer(new_bud.body_RID, Utils_Math._bitshift_left(3))
		#PhysicsServer3D.body_set_shape_disabled(new_bud.body_RID, 0, true)
	
	return new_bud

static func _setup_budmeshes(save_list: Array[MeshLoader], world: RID) -> void:
	
	for i in General_Bud.types_list.size():
		
		var current_type = General_Bud.types_list.find_key(i)
		
		if not BudStats.stats.has(General_Bud.types_list[current_type]):
			push_warning("There's no mesh in the dictionary corresponding to the type of: " + current_type + ".")
			continue
		
		var new_mesh = MeshLoader.new()
		new_mesh.name = current_type
		new_mesh.loader_type = MeshLoader.type.BUD
		
		var mesh_in_dict = BudStats.stats[General_Bud.types_list[current_type]]["mesh"]
		
		var mesh_to_use = Utils_Models._get_mesh(load(mesh_in_dict))
		
		if mesh_to_use:
			new_mesh._initialize_self(world, General_Bud.limit, mesh_to_use)
		
		save_list[i] = new_mesh

static func _setup_bud_data(all_buds: Array, world_space: RID, spawn_pos: Vector3 = Vector3.ZERO) -> void:
	
	if not General_Bud.bud_data_loaded:
		
		#print("Bud data not yet loaded. Setting them up!")
		
		if all_buds.size() > 0:
			all_buds.fill(null)
			
			for k in range(General_Bud.limit):
				
				spawn_pos = Vector3(k * -2, 10, 0)
				
				var bud: Brickbud = Utils_Bud._new_bud(k, world_space, spawn_pos)
				all_buds[k] = bud
			
			#print("All buds loaded.")
			General_Bud.bud_data_loaded = true

static func _sync_budmeshes(mesh_list: Array[MeshLoader], buffer: PackedFloat32Array, start_pos: int) -> void:
	
	for meshloader in mesh_list:
			
		#This is pretty much guranteed to happen since the mesh list has been resized, so it
		#checks for as certain number of entries based on how big the General_Bud.types_list
		#is. If there's at least one type not present on the field, this will error, so we
		#just gotta make it continue on.
		if meshloader == null:
			continue
		
		if not General_Bud.all_types.has(meshloader.name):
			push_warning("This type doesn't have a corresponding dictionary.")
			continue
		
		if meshloader.loader_type == MeshLoader.type.BUD:
			if General_Bud.all_types[meshloader.name]["active"] == true:
				
				for bud in General_Bud.all_buds:
					
					if bud.active:
						var bud_type = General_Bud.types_list.keys()[bud.type]
						
						if General_Bud.all_types[bud_type] == General_Bud.all_types[meshloader.name]:
							
							for g in range(12):
								buffer[(start_pos * 12) + g] = Utils_Math._Transform3D_to_PackedFloat32(bud.transform_g)[g]
							
							start_pos += 1
				
				RenderingServer.multimesh_set_buffer(meshloader.multimesh_RID, buffer)
