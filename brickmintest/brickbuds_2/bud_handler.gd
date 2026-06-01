extends Node3D

var active_buds: Array = []
var active_type_list: PackedInt32Array = []
var mesh_list: Array[MeshLoader] = []
var current_type_buds: PackedFloat32Array = PackedFloat32Array()

var bud_data_loaded: bool = false

var pool_position: Vector3 = Vector3.ZERO

const transform3Dfloats = 12

var Csharp_script = load("res://utilities/cs/csharp_test.cs").new()

func _ready() -> void:
	
	General_Bud.all_buds.resize(General_Bud.limit)
	active_buds.resize(General_Bud.limit)
	current_type_buds.resize(General_Bud.limit * 12)
	
	active_type_list.resize(General_Bud.types_list.size())
	mesh_list.resize(General_Bud.types_list.size())
	
	Utils_Bud._setup_bud_data(General_Bud.all_buds, get_world_3d().space, Vector3(0, 20, 0))
	Utils_Bud._setup_budmeshes(mesh_list, get_world_3d().scenario)
	
	#Csharp_script._RunTest()

func _physics_process(delta: float) -> void:
	
	active_type_list.fill(0)
	current_type_buds.fill(0)
	
	Utils_Bud._reset_active_types()
	
	if General_Bud.all_buds.size() > 0:
		
		for bud in General_Bud.all_buds:
			
			if not bud.active:
				continue
			
			var y_vel = bud.velocity.y
			bud.velocity.y = Utils_Math._apply_gravity(delta, y_vel)
			
			Utils_Math._update_position(bud, delta)
			
			if active_type_list[bud.bud_type] != 1:
				active_type_list[bud.bud_type] = 1
		
		Utils_Bud._set_active_types(active_type_list)
	
	if mesh_list.size() > 0 and active_buds.size() > 0:
		
		var k: int = 0
		
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
							var bud_type = General_Bud.types_list.keys()[bud.bud_type]
							
							if General_Bud.all_types[bud_type] == General_Bud.all_types[meshloader.name]:
								
								for g in range(transform3Dfloats):
									current_type_buds[(k * transform3Dfloats) + g] = Utils_Math._Transform3D_to_PackedFloat32(bud.transform_g)[g]
								
								k += 1
								
					RenderingServer.multimesh_set_buffer(meshloader.multimesh_RID, current_type_buds)
					
					#print("yes")
		
		#Utils_Models._data_mesh_sync(all_buds, Utils_Bud.mm, false)

func _notification(what: int) -> void:
	
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
	
		#print("Clean up initiated.")
		
		if  General_Bud.all_buds:
			for bud in  General_Bud.all_buds:
				if bud is Brickbud and bud != null and bud.has_method("_remove_self"):
					bud.remove_self()
		
		if mesh_list:
			for mesh in mesh_list:
				if mesh is MeshLoader and mesh != null and mesh.has_method("_remove_self"):
					mesh._remove_self()
		
		General_Bud.all_buds.clear()
		active_type_list.clear()
		mesh_list.clear()
		
		#print("Clean up complete!")
