class_name Databody

#region Body & Kinematics
var transform_l: Transform3D = Transform3D()
var transform_g: Transform3D = Transform3D()

var velocity: Vector3 = Vector3.ZERO

var body_RID: RID
var shape_RID: RID

const col_layer = 3
const col_mask = 1 

var mesh_num: int

#endregion
