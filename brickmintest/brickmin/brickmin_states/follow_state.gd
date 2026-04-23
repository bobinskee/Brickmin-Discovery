extends BrickminState
class_name FollowState

var start_distance: float = 10
var stop_distance: float = 5
var random_dir
var adjust_speed: float = 5.0

func _update(bmin: CharacterBody3D, delta: float, bmin_data: Dictionary):
	
	var y_velocity = bmin.velocity.y 
	var cur_speed = bmin.speed
	var repel_force = Vector3.ZERO
	var repel_weight: float = 1.0
	
	if bmin.leader:
		
		var target_position = bmin.leader.body.global_position
		
		if bmin.velocity.is_finite():
			
			bmin.pathing = false
			
			target_position = bmin.leader.body.global_position 
			
			
			"""
			if dict_individual["follow_path"]:
				brickbmin.pathing = true
				repel_weight = 0.01
				
				var dist_to_next = 0.6
				
				if brickbmin.global_position.distance_to(dict_individual["follow_path"][brickbmin.follow_index]) <= dist_to_next:
					brickbmin.follow_index += 1
				
				target_position = dict_individual["follow_path"][brickbmin.follow_index]
				start_distance = 0
				stop_distance = 0
				
				brickbmin.next_pos = target_position
				
				brickbmin.get_child(3).global_position = target_position"""
			
			if bmin.leader.input.player_swarming:
				target_position = bmin.leader.cursor.global_position
				start_distance = 10
				stop_distance = 0
			
			#elif abs(brickbmin.leader.body.velocity.x) > 0 or abs(brickbmin.leader.body.velocity.z) > 0:
			#	target_position = brickbmin.global_position + brickbmin.leader.body.velocity.normalized()
			
			else:
				start_distance = 8
				stop_distance = 8
			
			#brickbmin.get_child(2).global_position = target_position
			
			var xz_bmin = Vector2(bmin.global_position.x, bmin.global_position.z)
			var xz_target = Vector2(target_position.x, target_position.z)
			var xz_direction = xz_bmin.direction_to(xz_target)
			var xz_dist = xz_bmin.distance_to(xz_target) 
			var direction = Vector3(xz_direction.x, 0.0, xz_direction.y)
			var target_velocity = direction * cur_speed
			
			if not bmin.is_on_floor():
				
				if bmin.velocity.y > 0:
					repel_weight = 0.25
			
			else:
				if abs(bmin.velocity.x) > 0 or abs(bmin.velocity.z) > 0:
					repel_weight = 10.0
				
				bmin.jump_timer -= 0.075
			
			if not bmin.made_it:
				
				if not bmin.leader.input.player_swarming:
					
					if bmin.leader.body.velocity.length() > 0.0:
						start_distance = 8
						stop_distance = 6
					
					if abs(bmin.global_position.distance_to(target_position)) >= (stop_distance) or abs(bmin.leader.body.velocity.length()) > 0.0:
						bmin.following = true 
						
					else:
						bmin.following = false
						bmin.made_it = true
						bmin.xz_rand = (randf_range(0, 5))
					
				else:
					
					#repel_weight = 3.0
					
					if xz_dist >= (stop_distance) or abs(bmin.leader.body.velocity.length()) > 0.0:
						bmin.following = true 
						
					else:
						bmin.following = false
						bmin.made_it = true
			
			if bmin.made_it and not bmin.following:
				
				if abs(bmin.global_position.distance_to(target_position)) >= (start_distance):
					bmin.following = true
					bmin.made_it = false
			
			var cur_accel: float = bmin.acceleration
			
			#region Separation forces.
			
			var repel_distance: float = 0.0
			"""
			for i in (BrickminManager.total_min):
				if i == bmin: continue
				
				repel_distance = bmin.global_position.distance_to(i.global_position)
				
				if repel_distance < bmin.space_min:
					#If the distance between the current thing being checked and the Brickbmin is less...
					#than the space distance...
					repel_force += ((bmin.global_position - i.global_position).normalized()/repel_distance) * (adjust_speed * 1)
					#Add to the repel force.
			
			for i in (BrickminManager.leader_bodies):
				repel_distance = bmin.global_position.distance_to(i.global_position + (Vector3.ZERO * 1.5))
				
				if repel_distance < bmin.space_leader:
					repel_force += ((bmin.global_position - i.global_position).normalized()/repel_distance) * (adjust_speed * 2)
			"""
			
			var any_overlapping = bmin.get_node("RepelBubble").get_overlapping_bodies()
			
			for i in any_overlapping:
				if i == bmin:
					continue
				
				repel_distance = bmin.global_position.distance_to(i["position"])
				
				if repel_distance < bmin.space_min:
					#If the distance between the current thing being checked and the Brickbmin is less...
					#than the space distance...
					repel_force += ((bmin.global_position - i["position"]).normalized()/repel_distance) * (adjust_speed * 1)
					#Add to the repel force.
			#endregion
			
			#brickbmin.get_child(2).global_position = target_position
			
			#region Speed controls
			
			if bmin.following:
				
				if not bmin.leader.input.player_swarming:
					
					var slide_it: bool = false
					
					if (abs(xz_dist - bmin.xz_rand) <= bmin.fallback) and abs(bmin.leader.body.velocity.length()) > 0.0:
						cur_speed = move_toward(cur_speed, 1.0, delta * (bmin.acceleration * 3))
						slide_it = true
					
					else:
						cur_speed = move_toward(cur_speed, bmin.speed, delta * (bmin.acceleration * 3))
					
					if slide_it and direction:
						repel_force.slide(direction)
			
			elif not bmin.following:
				target_velocity = Vector3.ZERO
			
			#endregion
			
			var final_force = ((repel_force * repel_weight) + target_velocity)
			
			var cur_move = bmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
			
			bmin.comb_force = cur_move
			
			#region Stop Brickbmin from walking off of ledges.
			
			if bmin_data["near_cliff"]:
				
				var combined_norm = Vector3.ZERO
				var new_norms = []
				
				for i in range(2):
					var cur_norm = bmin_data["normals"][i]
					
					if cur_norm != Vector3.ZERO and not cur_norm in new_norms:
						new_norms.append(cur_norm)
						combined_norm += cur_norm
				
				if cur_move and combined_norm:
					combined_norm = combined_norm.normalized()
					
					if combined_norm.dot(cur_move) > 0:
						cur_move = cur_move.slide(combined_norm)
				
				if bmin.leader.body.jump_to:
					bmin.wanna_jump = true
					
					if bmin_data["jump_to"]: 
						
						if (bmin_data["jump_to"].direction_to(bmin.global_position)).dot(bmin.leader.body.global_position.direction_to(bmin.global_position)) > 0.5:
							
							if not bmin_data["walk_off"]:
								
								if bmin.jump_timer <= 0 and abs(bmin.leader.body.global_position.distance_to(bmin.global_position)) > 1:
									
									#var rand_offset = randf_range(0, offset_amt)
									var rand_offset = randf_range(2, 2.5)
									
									bmin.t = 0.0
									bmin.start = bmin.global_position
									bmin.end = bmin.global_position + (bmin.global_position.direction_to(bmin_data["jump_to"]) * (bmin.global_position.distance_to(bmin_data["jump_to"]) + rand_offset))
									bmin.mid = ((bmin_data["jump_to"]) + bmin.global_position)/2
									bmin.mid.y = bmin.jump_height + General._get_highest(bmin.global_position.y, bmin_data["jump_to"].y, false)
									bmin.state = "airborne"
									bmin.gapjumped = true
									
									bmin.jump_timer = randf_range(0, 0.2)
						
						elif bmin_data["walk_off"]:
							cur_move = bmin.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
				else:
					if abs(bmin.global_position.distance_to(bmin.leader.body.global_position)) < 1:
						cur_move = Vector3.ZERO
				
			else:
				bmin.wanna_jump = false
			
			#endregion
			
			bmin.velocity = cur_move
			
			bmin.velocity.y = y_velocity - (delta * General.gravity)
			
			if bmin.is_on_floor():
				
				if bmin_data["hop_up"] and not bmin_data["near_cliff"]:
					bmin.velocity.y += bmin.jump_power * General.jump_power_mult
				
			bmin.last_pos = bmin.global_position
			
			bmin.move_and_slide()
	
	else:
		bmin.state = "idle"
