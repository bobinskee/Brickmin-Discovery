extends Node3D

var active_buds: Array = []
var active_type_list: PackedInt32Array = []
var mesh_list: Array[MeshLoader] = []
var buds_buffer: PackedFloat32Array = PackedFloat32Array()

var bud_data_loaded: bool = false

var pool_position: Vector3 = Vector3.ZERO

const transform3Dfloats = 12

var Csharp_script = load("res://utilities/cs/csharp_test.cs").new()

func _ready() -> void:
	
	General_Bud.all_buds.resize(General_Bud.limit)
	active_buds.resize(General_Bud.limit)
	buds_buffer.resize(General_Bud.limit * 12)
	
	active_type_list.resize(General_Bud.types_list.size())
	mesh_list.resize(General_Bud.types_list.size())
	
	Utils_Bud._setup_bud_data(General_Bud.all_buds, get_world_3d().space, Vector3(0, 20, 0))
	Utils_Bud._setup_budmeshes(mesh_list, get_world_3d().scenario)
	
	#Csharp_script._RunTest()

func _physics_process(delta: float) -> void:
	
	active_type_list.fill(0)
	buds_buffer.fill(0)
	Utils_Bud._reset_active_types()
	
	if General_Bud.all_buds.size() > 0:
		
		for bud in General_Bud.all_buds:
			
			if not bud.active:
				continue
			
			if not bud.behavior:
				bud.behavior = BehaviorLoader.IDLE
				push_warning("This Bud doesn't have a behavior, so it's being defaulted to IDLE.")
			
			bud.behavior.update(bud, delta)
			
			Utils_Math._update_position(bud, delta)
			
			if active_type_list[bud.type] != 1:
				active_type_list[bud.type] = 1
		
		Utils_Bud._set_active_types(active_type_list)
	
	if mesh_list.size() > 0 and active_buds.size() > 0:
		
		var start_pos: int = 0
		
		Utils_Bud._sync_budmeshes(mesh_list, buds_buffer, start_pos)

func _notification(what: int) -> void:
	
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
	
		#print("Clean up initiated.")
		
		if  General_Bud.all_buds:
			for bud in  General_Bud.all_buds:
				if bud is Brickbud and bud != null:
					bud.remove_self()
				else:
					push_error("Something's wrong with deleting the buds!")
		
		if mesh_list:
			for mesh in mesh_list:
				
				if mesh is MeshLoader and mesh.has_method("_remove_self"):
					mesh._remove_self()
				
				elif mesh == null:
					continue
				
				else:
					push_error("Something's wrong with deleting the meshes!")
		
		General_Bud.all_buds.clear()
		active_type_list.clear()
		mesh_list.clear()
		buds_buffer.clear()
		
		#print("Clean up complete!")
