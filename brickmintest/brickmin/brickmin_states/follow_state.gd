extends BrickminState
class_name FollowState

var start_distance: float = 10
var stop_distance: float = 5
var random_dir

func _update_min(brickmin: CharacterBody3D, delta: float, dict_individual: Dictionary, _dict_all: Dictionary):
	var y_velocity = brickmin.velocity.y 
	var target_position
	var cur_speed = brickmin.speed
	var repel_force = Vector3.ZERO
	var adjust_speed: float = 5.0
	
	if brickmin.leader:
	
		var player_cursor = brickmin.leader.get_node(^"Cursor").get_node(^"Pointer")
		var swarming = brickmin.leader.get_node(^"InputHandler").player_swarming
		var leader_body = brickmin.leader.get_node(^"Body").get_node(^"CharacterBody3D")
		
		if brickmin.velocity.is_finite():
			
			brickmin.pathing = false
			
			var repel_weight: float = 1.0
			"""
			if dict_individual["follow_path"]:
				brickmin.pathing = true
				repel_weight = 0.01
				
				var dist_to_next = 0.6
				
				if brickmin.global_position.distance_to(dict_individual["follow_path"][brickmin.follow_index]) <= dist_to_next:
					brickmin.follow_index += 1
				
				target_position = dict_individual["follow_path"][brickmin.follow_index]
				start_distance = 0
				stop_distance = 0
				
				brickmin.next_pos = target_position
				
				brickmin.get_child(3).global_position = target_position"""
			
			if swarming:
				target_position = player_cursor.global_position
				start_distance = 10
				stop_distance = 0
			
			else:
				target_position = leader_body.global_position
				start_distance = 8
				stop_distance = 8
			
			var xz_brickmin = Vector2(brickmin.global_position.x, brickmin.global_position.z)
			var xz_target = Vector2(target_position.x, target_position.z)
			var xz_direction = xz_brickmin.direction_to(xz_target)
			var direction = Vector3(xz_direction.x, 0.0, xz_direction.y)
			var target_velocity = direction * cur_speed
			var xz_dist = xz_brickmin.distance_to(xz_target) 
			
			if not brickmin.is_on_floor():
				
				if brickmin.velocity.y > 0:
					repel_weight = 0.25
			
			else:
				if abs(brickmin.velocity.x) > 0 or abs(brickmin.velocity.z) > 0:
					repel_weight = 4.0
			
			if not brickmin.made_it:
				
				if not swarming:
					
					if leader_body.velocity.length() > 0.0:
						start_distance = 8
						stop_distance = 6
					
					if abs(brickmin.global_position.distance_to(target_position)) >= (stop_distance) or abs(leader_body.velocity.length()) > 0.0:
						brickmin.following = true 
						
					else:
						brickmin.following = false
						brickmin.made_it = true
						brickmin.xz_rand = (randf_range(0, 5))
					
				else:
					if xz_dist >= (stop_distance) or abs(leader_body.velocity.length()) > 0.0:
						brickmin.following = true 
						
					else:
						brickmin.following = false
						brickmin.made_it = true
			
			if brickmin.made_it and not brickmin.following:
				
				if abs(brickmin.global_position.distance_to(target_position)) >= (start_distance):
					brickmin.following = true
					brickmin.made_it = false
			
			var cur_accel: float = brickmin.acceleration
			
			if brickmin.following:
				
				if not swarming:
					
					var slide_it: bool = false
					
					if (abs(xz_dist - brickmin.xz_rand) <= brickmin.fallback) and abs(leader_body.velocity.length()) > 0.0:
						cur_speed = move_toward(cur_speed, 1.0, delta * (brickmin.acceleration * 3))
						slide_it = true
					
					else:
						cur_speed = move_toward(cur_speed, brickmin.speed, delta * (brickmin.acceleration * 3))
					
					if slide_it and direction:
						repel_force.slide(direction)
			
			elif not brickmin.following:
				target_velocity = Vector3.ZERO
			
			for current in (BrickminManager.total_min):
				if current == brickmin: continue
				
				var distance = brickmin.global_position.distance_to(current.global_position)
				
				if distance < brickmin.space_min:
					#If the distance between the current thing being checked and the Brickmin is less...
					#than the space distance...
					
					repel_force += ((brickmin.global_position - current.global_position).normalized()/distance) * adjust_speed
					#Add to the repel force.
			
			for leader in (BrickminManager.leader_bodies):
				var distance = brickmin.global_position.distance_to(leader_body.global_position + (Vector3.ZERO * 1.5))
				
				if distance < brickmin.space_leader:
					repel_force += ((brickmin.global_position - leader_body.global_position).normalized()/distance) * (adjust_speed * 2)
			
			var final_force = ((repel_force * repel_weight) + target_velocity)
			
			var cur_move = brickmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
			var combined_norm = Vector3.ZERO
			
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
				
				if leader_body.is_on_floor():
					brickmin.wanna_jump = true
					
					if dict_individual["jump_to"]: 
						if (dict_individual["jump_to"] - brickmin.global_position).dot(leader_body.global_position - brickmin.global_position) > 0.5:
							
							var offset_amt = 1.5
							
							if not dict_individual["walk_off"]:
								
								var rand_offset = Vector3(randf_range(-offset_amt, offset_amt), 0.0, randf_range(-offset_amt, offset_amt))
								var base_jump_height = 10
								
								brickmin.t = 0.0
								brickmin.start = brickmin.global_position
								brickmin.end = dict_individual["jump_to"] + rand_offset
								brickmin.mid = ((dict_individual["jump_to"] + rand_offset) + brickmin.global_position)/2
								brickmin.mid.y = base_jump_height + (0.5 * (brickmin.global_position.y + dict_individual["jump_to"].y + (abs(dict_individual["jump_to"].y - brickmin.global_position.y))))
								
								brickmin.jump_timer -= 0.05
								
								if brickmin.jump_timer <= 0.0 or abs(brickmin.leader.global_position - brickmin.global_position).length() > 1:
									brickmin.state = load("res://brickmin/brickmin_states/gapjump_state.tres")
							
							elif dict_individual["walk_off"]:
								cur_move = brickmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
				else:
					if abs(brickmin.global_position.distance_to(leader_body.global_position)) < 5:
						cur_move = Vector3.ZERO
				
			else:
				brickmin.wanna_jump = false
			
			brickmin.velocity = cur_move
			brickmin.velocity.y = y_velocity - (delta * General.gravity)
			
			if brickmin.is_on_floor():
				
				if dict_individual["hop_to"] and not dict_individual["near_cliff"]:
					brickmin.velocity.y += brickmin.jump_power * General.jump_power_mult
			
			brickmin.last_pos = brickmin.global_position
			
			brickmin.move_and_slide()
	
	else:
		brickmin.state = load("res://brickmin/brickmin_states/idle_state.tres")
