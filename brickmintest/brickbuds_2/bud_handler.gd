extends Node3D

var all_buds: Array = []

var bud_data_loaded: bool = false

var pool_position: Vector3 = Vector3.ZERO

var mm = MultiMesh.new()

func _ready() -> void:
	
	all_buds.resize(BudUtils.bud_limit)
	
	for node in get_tree().get_nodes_in_group("levels"):
		setup_buds(node)

func setup_buds(node: Node3D) -> void:
	
	if node.is_in_group("levels"):
		
		if not bud_data_loaded:
			
			print("Bud data not yet loaded. Setting them up!")
			
			if all_buds.size() > 0:
				all_buds.fill(null)
				
				for k in range(BudUtils.bud_limit):
					
					var bud: Brickbud = new_bud_data(k)
					all_buds[k] = bud
				
				print("All buds loaded.")
				bud_data_loaded = true
		
		if bud_data_loaded:
			
			print("Bud data has been loaded! Running mesh setup.")
			
			for i in range(BudStats.type.size()):
				
				var bud_type: String = BudStats.type.keys()[i]
				
				
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.instance_count = BudUtils.bud_limit
				
				var mesh_to_load = load(BudStats.stats[i]["mesh"])
				
				if mesh_to_load:
					mm.mesh = mesh_to_load
				else:
					print("No mesh found!")
				
				var mm_node = MultiMeshInstance3D.new()
				mm_node.name = bud_type + "_typeloader"
				mm_node.multimesh = mm
				
				for k in range(mm.instance_count):
					sync_bud_data_mesh(all_buds[k])
				
				self.add_child(mm_node)

func new_bud_data(index: int) -> Brickbud:
	
	var new_bud = Brickbud.new()
	
	if new_bud:
		
		new_bud.body_RID = PhysicsServer3D.body_create()
		new_bud.shape_RID = PhysicsServer3D.capsule_shape_create()
		
		new_bud.bud_id = index
		new_bud.transform.origin = (Vector3(-100, 10, 0)) + ((Vector3.RIGHT * index) * 1)
		
		PhysicsServer3D.shape_set_data(new_bud.shape_RID, BudStats.stats[new_bud.bud_type]["shape_scale"])
		
		PhysicsServer3D.body_set_space(new_bud.body_RID, self.get_world_3d().space)
		
		PhysicsServer3D.body_set_mode(new_bud.body_RID, PhysicsServer3D.BODY_MODE_KINEMATIC)
		
		PhysicsServer3D.body_set_state(new_bud.body_RID, PhysicsServer3D.BODY_STATE_TRANSFORM, new_bud.transform)
		
		PhysicsServer3D.body_add_shape(new_bud.body_RID, new_bud.shape_RID) #Index of 0
		PhysicsServer3D.body_set_shape_disabled(new_bud.body_RID, 0, true)
	
	return new_bud

func _notification(what: int) -> void:
	
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
	
		print("Clean up initiated.")
		
		if all_buds:
			for bud in all_buds:
				if bud is Brickbud and bud != null:
					bud.remove_self()
		
		all_buds.clear()
		
		print("Clean up complete!")

func sync_bud_data_mesh(bud: Brickbud) -> void:
	if not bud is Brickbud:
		print("Pass a Brickbud!")
	
	else:
		mm.set_instance_transform(bud.bud_id, bud.transform)
