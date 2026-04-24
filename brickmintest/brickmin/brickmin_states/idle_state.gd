extends BrickminState
class_name IdleState

var last_pos 
var adjust_speed: float = 2

func _update(bmin: CharacterBody3D, delta: float, min_data: Dictionary):
	
	#var rand = Vector3(randf_range(-45.0, 45.0), 0, randf_range(-45.0, 45.0))
	#var distance: float = 0
	var repel_force = Vector3.ZERO
	#var difference = Vector3.ZERO
	
	var any_overlapping = bmin.get_node("RepelBubble").get_overlapping_bodies()
	
	#var dir = Vector3.ZERO
	
	for i in any_overlapping:
		if i == bmin:
			continue
		
		var repel_distance = bmin.global_position.distance_to(i.global_position)
		
		repel_force = ((bmin.global_position - i.global_position).normalized()/repel_distance * adjust_speed) 
		
	if any_overlapping.size() <= 1:
		#print("yes")
		repel_force = Vector3.ZERO
			
	if not repel_force.is_finite():
		repel_force = Vector3(randf(), 0, randf()).normalized() * 3
	
	var cur_move = bmin.velocity.move_toward(repel_force, delta * bmin.acceleration)
	
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
		
	else:
		
		bmin.global_position += Vector3(randf_range(-360, 360), 0, randf_range(-360, 360))
		bmin.velocity = Vector3(randf(), 0, randf()).normalized()
