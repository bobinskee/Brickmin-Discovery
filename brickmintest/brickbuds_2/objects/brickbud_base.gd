class_name Brickbud

#region General

var name: String = ""
var bud_id: int = 0

var active: bool = false

#endregion

#region Body & Kinematics

var transform: Transform3D = Transform3D()
var velocity: Vector3 = Vector3.ZERO

var body_RID: RID
var shape_RID: RID

const col_layer = 3
const col_mask = 1 

var mesh_num: int

#endregion

#region Type & State

var bud_type: BudStats.type = BudStats.type.BASE

var bud_state: BudUtils.state = BudUtils.state.IDLE

#endregion

#region Group Management

var leader_ID: int = -1

#endregion

func remove_self() -> void:
	
	if body_RID.is_valid():
		PhysicsServer3D.free_rid(body_RID)
	
	if shape_RID.is_valid():
		PhysicsServer3D.free_rid(shape_RID)
	
	
