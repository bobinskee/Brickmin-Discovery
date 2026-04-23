extends BrickminState
class_name AirborneState
 
#var idle_state = preload("res://brickbmin/brickbmin_states/idle_state.gd").new()

func _update(bmin: CharacterBody3D, delta: float, _bmin_data: Dictionary):
	##CONSOLIDATE THIS WITH GAPJUMP STATE
	
	if bmin.thrown:
		bmin.t += delta * 2
		
	elif bmin.gapjumped:
		bmin.t += delta * 1.3
	
	var cur_vel = General._bezcurve(bmin.t, bmin.start, bmin.mid, bmin.end) - bmin.global_position
	
	var last_pos = bmin.global_position
	
	if bmin.t > 0.9:
		if bmin.thrown:
			cur_vel -= (bmin.global_position - last_pos)/delta
	
		elif bmin.gapjumped:
			cur_vel -= (bmin.global_position - last_pos)/delta
	
	if bmin.velocity.is_finite():
		
		if bmin.move_and_collide(cur_vel):
			
			if bmin.thrown:
				bmin.state = "idle"
			
			elif bmin.gapjumped:
				bmin.state = "follow"
			
			bmin.thrown = false
			bmin.gapjumped = false
	
	elif not bmin.velocity.is_finite():
		print("ruh roh")
		bmin.global_position = bmin.last_pos
		bmin.state = "idle"
