extends BudState
"""
#var idle_state = preload("res://brickbud/brickbud_states/idle_state.gd").new()

func update(bud: CharacterBody3D, delta: float, _bud_data: Dictionary)  -> void:
	##CONSOLIDATE THIS WITH GAPJUMP STATE
	
	if bud.thrown:
		bud.t += delta * 2
		
	elif bud.gapjumped:
		bud.t += delta * 1.3
	
	var cur_vel = Utils_Math.bezier_curve(bud.t, bud.start, bud.mid, bud.end) - bud.global_position
	
	var last_pos = bud.global_position
	
	if bud.t > 0.9:
		if bud.thrown:
			cur_vel -= (bud.global_position - last_pos)/delta
	
		elif bud.gapjumped:
			cur_vel -= (bud.global_position - last_pos)/delta
	
	if bud.velocity.is_finite():
		
		if bud.move_and_collide(cur_vel):
			
			if bud.thrown:
				bud.state = Utils_Bud.state.IDLE
			
			elif bud.gapjumped:
				bud.state = Utils_Bud.state.FOLLOW
			
			bud.thrown = false
			bud.gapjumped = false
	
	elif not bud.velocity.is_finite():
		print("ruh roh")
		bud.global_position = bud.last_pos
		bud.state = Utils_Bud.state.IDLE"""
