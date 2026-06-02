extends Databody
class_name Brickbud

#region General

var name: String = ""
var bud_id: int = 0

var active: int = 1

#endregion

#region Type & State

var type: General_Bud.types_list = General_Bud.types_list.BASE

var behavior: BudBehavior

#endregion

#region Group Management

var leader_ID: int = 0

#endregion

func remove_self() -> void:
	super.remove_self()
