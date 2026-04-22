extends BrickminState
class_name FollowState

var start_distance: float = 10
var stop_distance: float = 5
var random_dir
var adjust_speed: float = 5.0

func _update_min(brickmin: CharacterBody3D, delta: float, min_data: Dictionary):
	
	var y_velocity = brickmin.velocity.y 
	var cur_speed = brickmin.speed
	var repel_force = Vector3.ZERO
	var repel_weight: float = 1.0
	
	if brickmin.leader:
		
		var target_position = brickmin.leader.body.global_position
		
		if brickmin.velocity.is_finite():
			
			brickmin.pathing = false
			
			target_position = brickmin.leader.body.global_position 
			
			
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
			
			if brickmin.leader.input.player_swarming:
				target_position = brickmin.leader.cursor.global_position
				start_distance = 10
				stop_distance = 0
			
			#elif abs(brickmin.leader.body.velocity.x) > 0 or abs(brickmin.leader.body.velocity.z) > 0:
			#	target_position = brickmin.global_position + brickmin.leader.body.velocity.normalized()
			
			else:
				start_distance = 8
				stop_distance = 8
			
			#brickmin.get_child(2).global_position = target_position
			
			var xz_brickmin = Vector2(brickmin.global_position.x, brickmin.global_position.z)
			var xz_target = Vector2(target_position.x, target_position.z)
			var xz_direction = xz_brickmin.direction_to(xz_target)
			var xz_dist = xz_brickmin.distance_to(xz_target) 
			var direction = Vector3(xz_direction.x, 0.0, xz_direction.y)
			var target_velocity = direction * cur_speed
			
			if not brickmin.is_on_floor():
				
				if brickmin.velocity.y > 0:
					repel_weight = 0.25
			
			else:
				if abs(brickmin.velocity.x) > 0 or abs(brickmin.velocity.z) > 0:
					repel_weight = 10.0
				
				brickmin.jump_timer -= 0.075
			
			if not brickmin.made_it:
				
				if not brickmin.leader.input.player_swarming:
					
					if brickmin.leader.body.velocity.length() > 0.0:
						start_distance = 8
						stop_distance = 6
					
					if abs(brickmin.global_position.distance_to(target_position)) >= (stop_distance) or abs(brickmin.leader.body.velocity.length()) > 0.0:
						brickmin.following = true 
						
					else:
						brickmin.following = false
						brickmin.made_it = true
						brickmin.xz_rand = (randf_range(0, 5))
					
				else:
					
					#repel_weight = 3.0
					
					if xz_dist >= (stop_distance) or abs(brickmin.leader.body.velocity.length()) > 0.0:
						brickmin.following = true 
						
					else:
						brickmin.following = false
						brickmin.made_it = true
			
			if brickmin.made_it and not brickmin.following:
				
				if abs(brickmin.global_position.distance_to(target_position)) >= (start_distance):
					brickmin.following = true
					brickmin.made_it = false
			
			var cur_accel: float = brickmin.acceleration
			
			#region Separation forces.
			
			var repel_distance: float = 0.0
			
			for i in (BrickminManager.total_min):
				if i == brickmin: continue
				
				repel_distance = brickmin.global_position.distance_to(i.global_position)
				
				if repel_distance < brickmin.space_min:
					#If the distance between the current thing being checked and the Brickmin is less...
					#than the space distance...
					repel_force += ((brickmin.global_position - i.global_position).normalized()/repel_distance) * (adjust_speed * 1)
					#Add to the repel force.
			
			for i in (BrickminManager.leader_bodies):
				repel_distance = brickmin.global_position.distance_to(i.global_position + (Vector3.ZERO * 1.5))
				
				if repel_distance < brickmin.space_leader:
					repel_force += ((brickmin.global_position - i.global_position).normalized()/repel_distance) * (adjust_speed * 2)
			
			#endregion
			
			#brickmin.get_child(2).global_position = target_position
			
			#region Speed controls
			
			if brickmin.following:
				
				if not brickmin.leader.input.player_swarming:
					
					var slide_it: bool = false
					
					if (abs(xz_dist - brickmin.xz_rand) <= brickmin.fallback) and abs(brickmin.leader.body.velocity.length()) > 0.0:
						cur_speed = move_toward(cur_speed, 1.0, delta * (brickmin.acceleration * 3))
						slide_it = true
					
					else:
						cur_speed = move_toward(cur_speed, brickmin.speed, delta * (brickmin.acceleration * 3))
					
					if slide_it and direction:
						repel_force.slide(direction)
			
			elif not brickmin.following:
				target_velocity = Vector3.ZERO
			
			#endregion
			
			var final_force = ((repel_force * repel_weight) + target_velocity)
			
			var cur_move = brickmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
			
			brickmin.comb_force = cur_move
			
			#region Stop Brickmin from walking off of ledges.
			
			if min_data["near_cliff"]:
				
				var combined_norm = Vector3.ZERO
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
				
				if brickmin.leader.body.jump_to:
					brickmin.wanna_jump = true
					
					if min_data["jump_to"]: 
						
						if (min_data["jump_to"].direction_to(brickmin.global_position)).dot(brickmin.leader.body.global_position.direction_to(brickmin.global_position)) > 0.5:
							
							if not min_data["walk_off"]:
								
								if brickmin.jump_timer <= 0 and abs(brickmin.leader.body.global_position.distance_to(brickmin.global_position)) > 1:
									
									#var rand_offset = randf_range(0, offset_amt)
									var rand_offset = randf_range(2, 2.5)
									
									brickmin.t = 0.0
									brickmin.start = brickmin.global_position
									brickmin.end = brickmin.global_position + (brickmin.global_position.direction_to(min_data["jump_to"]) * (brickmin.global_position.distance_to(min_data["jump_to"]) + rand_offset))
									brickmin.mid = ((min_data["jump_to"]) + brickmin.global_position)/2
									brickmin.mid.y = brickmin.jump_height + General._get_highest(brickmin.global_position.y, min_data["jump_to"].y, false)
									brickmin.state = General.airborne_state
									brickmin.gapjumped = true
									
									brickmin.jump_timer = randf_range(0, 0.2)
						
						elif min_data["walk_off"]:
							cur_move = brickmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
				else:
					if abs(brickmin.global_position.distance_to(brickmin.leader.body.global_position)) < 1:
						cur_move = Vector3.ZERO
				
			else:
				brickmin.wanna_jump = false
			
			#endregion
			
			brickmin.velocity = cur_move
			
			brickmin.velocity.y = y_velocity - (delta * General.gravity)
			
			if brickmin.is_on_floor():
				
				if min_data["hop_up"] and not min_data["near_cliff"]:
					brickmin.velocity.y += brickmin.jump_power * General.jump_power_mult
				
			brickmin.last_pos = brickmin.global_position
			
			brickmin.move_and_slide()
	
	else:
		brickmin.state = General.idle_state
