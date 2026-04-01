extends BrickminState
class_name IdleState

var random_dir
var last_pos 

func _update_min(brickmin: CharacterBody3D, delta: float, dict_individual: Dictionary, _dict_all: Dictionary):
	
	var repel_force = Vector3.ZERO
	var adjust_speed: float = 10.0
	var combined_norm = Vector3.ZERO
	var rand = Vector3(randf_range(-360.0, 360.0), 0, randf_range(-360.0, 360.0))
	
	for current in (BrickminManager.total_min):
		if current == brickmin: continue
		
		var difference = brickmin.global_position - current.global_position
		var distance = brickmin.global_position.distance_to(current.global_position)
		
		if distance < 0.5:
			difference += rand
			repel_force += (difference.normalized()/distance) * adjust_speed
	
	for leader in (BrickminManager.leader_bodies):
		var distance = brickmin.global_position.distance_to(leader.global_position + (Vector3.DOWN * 1.5))
		var difference = brickmin.global_position - leader.global_position
		
		if distance < brickmin.space_leader:
			repel_force += (difference.normalized()/distance) * adjust_speed
	
	if not repel_force.is_finite():
		repel_force = Vector3(randf(), 0, randf()).normalized()
	
	var y_velocity = brickmin.velocity.y
	var cur_move = brickmin.velocity.move_toward(repel_force, delta * brickmin.acceleration)
	
	if not brickmin.velocity.is_finite():
		random_dir = Vector3(randf(), 0, randf()).normalized()
		brickmin.global_position = last_pos + random_dir
		brickmin.velocity = Vector3.ZERO
	
	brickmin.comb_force = cur_move
	
	if dict_individual["near_cliff"]:
		
		var new_norms = []
		
		for i in range(2):
			var cur_norm = dict_individual["normals"][i]
			
			if cur_norm != Vector3.ZERO and not cur_norm in new_norms:
				new_norms.append(cur_norm)
				combined_norm += cur_norm
				
			if new_norms.size() == 1:
				combined_norm = combined_norm.normalized()
				cur_move = cur_move.slide(combined_norm)
				
			elif new_norms.size() > 1:
				cur_move = Vector3.ZERO
	
	if brickmin.velocity.is_finite():
		
		brickmin.velocity = cur_move
		brickmin.velocity.y = y_velocity - (delta * General.gravity)
		
		
		brickmin.move_and_slide()
