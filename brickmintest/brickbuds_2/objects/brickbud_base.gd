extends Databody
class_name Brickbud

var a = 5

#region General

var name: String = ""
var bud_id: int = 0

var active: int = 1

#endregion

#region Type & State

var bud_type: General_Bud.types_list = General_Bud.types_list.BASE

var bud_state: Utils_Bud.state = Utils_Bud.state.IDLE

#endregion

#region Group Management

var leader_ID: int = -1

#endregion

func remove_self() -> void:
	
	if body_RID.is_valid():
		PhysicsServer3D.free_rid(body_RID)
	
	if shape_RID.is_valid():
		PhysicsServer3D.free_rid(shape_RID)
