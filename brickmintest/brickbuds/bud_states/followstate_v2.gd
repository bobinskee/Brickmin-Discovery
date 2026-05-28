extends BrickminState

func update(bmin: CharacterBody3D, delta: float, _min_data: Dictionary) -> void:
	
	if bmin.leader != null:
		bmin.target = bmin.leader.body.global_position
		
		var cur_move = bmin.velocity.move_toward(bmin.target, delta * 50)
		bmin.velocity = cur_move
		
	bmin.move_and_slide()
