extends BudState

var last_pos 
var adjust_speed: float = 2

func update(bud: CharacterBody3D, delta: float, min_data: Dictionary) -> void:
	
	var repel_force = BudUtils.get_repel_vector(bud, 10) * 5
	
	var cur_move = bud.velocity.move_toward(repel_force, delta * bud.acceleration)
	
	bud.comb_force = cur_move
	
	if min_data["near_cliff"]:
		
		cur_move = BudUtils.cliff_slide(cur_move, min_data["normals"])
	
	if bud.velocity.is_finite():
		
		var vert_move = bud.velocity.y - (delta * General.gravity)
		bud.velocity = Vector3(cur_move.x, vert_move, cur_move.z)
		
		bud.move_and_slide()
