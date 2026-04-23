extends BrickminState
class_name IdleState

var last_pos 
var adjust_speed: float = 10.0

func _update(bmin: CharacterBody3D, delta: float, min_data: Dictionary):
	
	var rand = Vector3(randf_range(-45.0, 45.0), 0, randf_range(-45.0, 45.0))
	#var distance: float = 0
	var repel_force = Vector3.ZERO
	#var difference = Vector3.ZERO
	"""
	for current in (BrickminManager.total_min):
		if current == bmin: continue
		
		difference = bmin.global_position - current.global_position
		distance = bmin.global_position.distance_to(current.global_position)
		
		if distance < 0.5:
			difference += rand
			repel_force += (difference.normalized()/distance) * adjust_speed
	
	for leader in (BrickminManager.leader_bodies):
		distance = bmin.global_position.distance_to(leader.global_position + (Vector3.DOWN * 1.5))
		difference = bmin.global_position - leader.global_position
		
		if distance < bmin.space_leader:
			repel_force += (difference.normalized()/distance) * adjust_speed"""
	
	var any_overlapping = bmin.get_node("RepelBubble").get_overlapping_bodies()
		
	if any_overlapping:
		for i in any_overlapping:
			if i == bmin:
				continue
			
			var repel_distance = bmin.global_position.distance_to(i["position"])
			
			if repel_distance < bmin.space_min:
				#If the distance between the current thing being checked and the Brickbmin is less...
				#than the space distance...
				repel_force += ((bmin.global_position - i["position"]).normalized() + rand/repel_distance).limit_length(7)
		
	if not repel_force.is_finite():
		repel_force = Vector3(randf(), 0, randf()).normalized()
	
	var cur_move = bmin.velocity.move_toward(repel_force, delta * bmin.acceleration)
	
	if not bmin.velocity.is_finite():
		bmin.global_position = last_pos + Vector3(randf(), 0, randf()).normalized()
		bmin.velocity = Vector3.ZERO
	
	bmin.comb_force = cur_move
	
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
	
	bmin.reaction_time = randf_range(1, 1.3)
	
	var y_velocity = bmin.velocity.y
	
	if bmin.velocity.is_finite():
		
		bmin.velocity = cur_move
		bmin.velocity.y = y_velocity - (delta * General.gravity)
		
		bmin.move_and_slide()
