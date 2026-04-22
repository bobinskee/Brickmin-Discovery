extends BrickminState
class_name AirborneState
 
#var idle_state = preload("res://brickmin/brickmin_states/idle_state.gd").new()

func _update_min(brickmin: CharacterBody3D, delta: float, _min_data: Dictionary):
	##CONSOLIDATE THIS WITH GAPJUMP STATE
	
	if brickmin.thrown:
		brickmin.t += delta * 2
		
	elif brickmin.gapjumped:
		brickmin.t += delta * 1.3
	
	var cur_vel = General._bezcurve(brickmin.t, brickmin.start, brickmin.mid, brickmin.end) - brickmin.global_position
	
	var last_pos = brickmin.global_position
	
	if brickmin.t > 0.9:
		if brickmin.thrown:
			cur_vel -= (brickmin.global_position - last_pos)/delta
	
		elif brickmin.gapjumped:
			cur_vel -= (brickmin.global_position - last_pos)/delta
	
	if brickmin.velocity.is_finite():
		
		if brickmin.move_and_collide(cur_vel):
			
			if brickmin.thrown:
				brickmin.state = General.idle_state
			
			elif brickmin.gapjumped:
				brickmin.state = General.follow_state
			
			brickmin.thrown = false
			brickmin.gapjumped = false
	
	elif not brickmin.velocity.is_finite():
		print("ruh roh")
		brickmin.global_position = brickmin.last_pos
		brickmin.state = General.idle_state
