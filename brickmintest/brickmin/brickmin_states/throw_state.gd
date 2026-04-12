extends BrickminState
class_name ThrowState
 
func _update_min(brickmin: CharacterBody3D, delta: float, _dict_individual: Dictionary, _dict_all: Dictionary):
	##CONSOLIDATE THIS WITH GAPJUMP STATE
	
	var last_pos = brickmin.global_position
	
	brickmin.t += delta * 2
	
	var cur_vel
	var next_pos = General._bezcurve(brickmin.t, brickmin.start, brickmin.mid, brickmin.end)
	cur_vel = next_pos - brickmin.global_position
	last_pos = brickmin.global_position
		
	if brickmin.t > 0.9:
		cur_vel -= (brickmin.global_position - last_pos)/delta
	
	if brickmin.velocity.is_finite():
		var collision = brickmin.move_and_collide(cur_vel)
		
		if collision:
			brickmin.velocity = Vector3.ZERO
			brickmin.state = load("res://brickmin/brickmin_states/idle_state.tres")
	
	elif not brickmin.velocity.is_finite():
		print("ruh roh")
		brickmin.global_position = last_pos
		brickmin.state = load("res://brickmin/brickmin_states/idle_state.tres")
