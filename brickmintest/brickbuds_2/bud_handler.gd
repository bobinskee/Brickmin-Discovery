extends Node3D

var all_buds: Array = []

var bud_data_loaded: bool = false

var pool_position: Vector3 = Vector3.ZERO

#var mm_node: MultiMeshInstance3D = MultiMeshInstance3D.new()
#var mm: MultiMesh = MultiMesh.new()

func _ready() -> void:
	
	all_buds.resize(Utils_Bud.bud_limit)
	
	Utils_Bud._setup_buds(bud_data_loaded, all_buds, get_world_3d().space, get_tree().current_scene, Vector3(0, 20, 0))

func _physics_process(delta: float) -> void:
	
	for bud in all_buds:
		
		var y_vel = bud.velocity.y
		bud.velocity.y = Utils_Math._apply_gravity(delta, y_vel)
		
		Utils_Math._update_position(bud, delta)
	
	Utils_Models._data_mesh_sync(all_buds, Utils_Bud.mm, false)

func _notification(what: int) -> void:
	
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
	
		print("Clean up initiated.")
		
		if all_buds:
			for bud in all_buds:
				if bud is Brickbud and bud != null:
					bud.remove_self()
		
		all_buds.clear()
		
		print("Clean up complete!")
