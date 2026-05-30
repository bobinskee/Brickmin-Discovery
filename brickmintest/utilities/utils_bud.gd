extends RefCounted
class_name Utils_Bud

#region Game variables
static var bud_limit = 10

#endregion

enum state {IDLE, FOLLOW, AIRBORNE}

const state_scripts: Dictionary = {
	state.IDLE: preload("res://brickbuds_2/states/state_idling.gd")
}

static var idle_state: BudState = preload("res://brickbuds/bud_states/idle_state.gd").new()
static var follow_state: BudState = preload("res://brickbuds/bud_states/follow_state.gd").new()
static var airborne_state: BudState = preload("res://brickbuds/bud_states/airborne_state.gd").new()
#static var follow_v2: BudnState = preload("res://brickbuds/bud_states/followstate_v2.gd").new() 

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

static func _new_bud(index: int, world_space: RID, spawn_pos: Vector3 = Vector3.ZERO) -> Brickbud:
	
	var new_bud = Brickbud.new()
	
	if new_bud:
		
		new_bud.body_RID = PhysicsServer3D.body_create()
		new_bud.shape_RID = PhysicsServer3D.capsule_shape_create()
		
		new_bud.bud_id = index
		new_bud.transform_g.origin = spawn_pos
		
		PhysicsServer3D.shape_set_data(new_bud.shape_RID, BudStats.stats[new_bud.bud_type]["shape_scale"])
		
		PhysicsServer3D.body_set_space(new_bud.body_RID, world_space)
		
		PhysicsServer3D.body_set_mode(new_bud.body_RID, PhysicsServer3D.BODY_MODE_KINEMATIC)
		
		PhysicsServer3D.body_set_state(new_bud.body_RID, PhysicsServer3D.BODY_STATE_TRANSFORM, new_bud.transform_g)
		
		PhysicsServer3D.body_add_shape(new_bud.body_RID, new_bud.shape_RID) #Index of 0
		
		PhysicsServer3D.body_set_collision_mask(new_bud.body_RID, Utils_Math._bitshift_left(1))
		PhysicsServer3D.body_set_collision_layer(new_bud.body_RID, Utils_Math._bitshift_left(3))
		#PhysicsServer3D.body_set_shape_disabled(new_bud.body_RID, 0, true)
	
	return new_bud

static func _setup_buds(bud_data_loaded: bool, all_buds: Array, world_space: RID, scene: Node, spawn_pos: Vector3 = Vector3.ZERO) -> void:
	
	if not bud_data_loaded:
		
		print("Bud data not yet loaded. Setting them up!")
		
		if all_buds.size() > 0:
			all_buds.fill(null)
			
			for k in range(Utils_Bud.bud_limit):
				
				spawn_pos = Vector3(k * -2, 10, 0)
				
				var bud: Brickbud = Utils_Bud._new_bud(k, world_space, spawn_pos)
				all_buds[k] = bud
			
			print("All buds loaded.")
			bud_data_loaded = true
	
	if bud_data_loaded:
		
		print("Bud data has been loaded! Running mesh setup.")
		
		var mm_node: MultiMeshInstance3D = MultiMeshInstance3D.new()
		
		
		for i in range(BudStats.type.size()):
			
			var bud_type: String = BudStats.type.keys()[i]
			
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.instance_count = Utils_Bud.bud_limit
			
			var mesh_to_load = load(BudStats.stats[i]["mesh"])
			
			if mesh_to_load:
				mm.mesh = mesh_to_load
			else:
				print("No mesh found!")
			
			mm_node.name = bud_type + "_typeloader"
			mm_node.multimesh = mm
			
			#for k in range(mm.instance_count):
			
			scene.add_child(mm_node)
		
		Utils_Models._data_mesh_sync(all_buds, mm, false)
