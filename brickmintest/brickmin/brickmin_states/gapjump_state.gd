extends BrickminState
class_name GapJumpState 

func _update_min(brickmin: CharacterBody3D, delta: float, _dict_individual: Dictionary, _dict_all: Dictionary):
	
	var last_pos = brickmin.global_position
	
	brickmin.t += delta * 1.3
	
	var cur_vel
	var next_pos = General._bezcurve(brickmin.t, brickmin.start, brickmin.mid, brickmin.end)
	cur_vel = next_pos - brickmin.global_position
	last_pos = brickmin.global_position
	
	if brickmin.t > 1.0:
		cur_vel -= (brickmin.global_position - last_pos)/delta
	
	if brickmin.velocity.is_finite():
		var collision = brickmin.move_and_collide(cur_vel)
		
		if collision:
			brickmin.state = load("res://brickmin/brickmin_states/follow_state.tres")
