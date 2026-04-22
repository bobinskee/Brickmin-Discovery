extends BrickminState
class_name IdleState

var last_pos 
var adjust_speed: float = 10.0

func _update_min(brickmin: CharacterBody3D, delta: float, min_data: Dictionary):
	
	var rand = Vector3(randf_range(-360.0, 360.0), 0, randf_range(-360.0, 360.0))
	var distance: float = 0
	var repel_force = Vector3.ZERO
	var difference = Vector3.ZERO
	
	for current in (BrickminManager.total_min):
		if current == brickmin: continue
		
		difference = brickmin.global_position - current.global_position
		distance = brickmin.global_position.distance_to(current.global_position)
		
		if distance < 0.5:
			difference += rand
			repel_force += (difference.normalized()/distance) * adjust_speed
	
	for leader in (BrickminManager.leader_bodies):
		distance = brickmin.global_position.distance_to(leader.global_position + (Vector3.DOWN * 1.5))
		difference = brickmin.global_position - leader.global_position
		
		if distance < brickmin.space_leader:
			repel_force += (difference.normalized()/distance) * adjust_speed
	
	if not repel_force.is_finite():
		repel_force = Vector3(randf(), 0, randf()).normalized()
	
	var cur_move = brickmin.velocity.move_toward(repel_force, delta * brickmin.acceleration)
	
	if not brickmin.velocity.is_finite():
		brickmin.global_position = last_pos + Vector3(randf(), 0, randf()).normalized()
		brickmin.velocity = Vector3.ZERO
	
	brickmin.comb_force = cur_move
	
	var combined_norm = Vector3.ZERO
	
	if min_data["near_cliff"]:
		var new_norms = []
		
		for i in range(2):
			var cur_norm = min_data["normals"][i]
			
			if cur_norm != Vector3.ZERO and not cur_norm in new_norms:
				new_norms.append(cur_norm)
				combined_norm += cur_norm
		
		if cur_move and combined_norm:
			combined_norm = combined_norm.normalized()
			
			if combined_norm.dot(cur_move) > 0:
				cur_move = cur_move.slide(combined_norm)
	
	brickmin.reaction_time = randf_range(1, 1.3)
	
	var y_velocity = brickmin.velocity.y
	
	if brickmin.velocity.is_finite():
		
		brickmin.velocity = cur_move
		brickmin.velocity.y = y_velocity - (delta * General.gravity)
		
		brickmin.move_and_slide()
