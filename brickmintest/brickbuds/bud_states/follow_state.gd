extends BudState

## For when Brickmin are following player
## Moving, separation, and jumping

#region Variables

var random_dir
var adjust_speed: float = 2

#endregion

func update(bud: CharacterBody3D, delta: float, bud_data: Dictionary) -> void:
	
	var start_distance: float = 10
	var stop_distance: float = 5
	var y_velocity = bud.velocity.y 
	var cur_speed = bud.speed
	var repel_force = Vector3.ZERO
	var keep_slide: bool = true
	var repel_amt: float = 10
	
	#So long as the current Brickmin has a leader...
	if bud.leader:
		
		#if bud.desired_offset == Vector3.ZERO:
		#	bud.desired_offset = generateOffset(50, 7)
		
		#var target_position = bud.desired_offset + Vector3(bud.leader.body.global_position.x, 0, bud.leader.body.global_position.z)
		#bud.get_child(2).global_position = target_position
		
		#Default the target position to the leader.
		#if bud.repel_bubble.get_child(0).scale.x != bud.personal_space:
		#	bud.repel_bubble.get_child(0).scale = Vector3.ONE * bud.personal_space
		
		var target_position = bud.leader.body.global_position
		
		#Make sure the velocity is valid.
		if bud.velocity.is_finite():
			
			bud.pathing = false
			
			"""
			if dict_individual["follow_path"]:
				brickbud.pathing = true
				repel_weight = 0.01
				
				var dist_to_next = 0.6
				
				if brickbud.global_position.distance_to(dict_individual["follow_path"][brickbud.follow_index]) <= dist_to_next:
					brickbud.follow_index += 1
				
				target_position = dict_individual["follow_path"][brickbud.follow_index]
				start_distance = 0
				stop_distance = 0
				
				brickbud.next_pos = target_position
				
				brickbud.get_child(3).global_position = target_position"""
			
			var cur_accel: float = bud.acceleration
			
			#If the leader is swarming...
			if bud.leader.input.player_swarming:
				#Set the target position to the leader's cursor.
				
				if not bud.resetted:
					bud.spin_time += randi_range(0, 359)
					bud.resetted = true
				
				if bud.spin_time >= 359:
					bud.spin_time = 0
				else:
					bud.spin_time += 1
				
				var offset = Vector3(cos(deg_to_rad(bud.spin_time)), 0, sin(deg_to_rad(bud.spin_time)))
				target_position = bud.leader.cursor.global_position + (offset * (randf_range(0, 3) * 2))
				
				#bud.get_node(^"RepelBubble").get_child(0).scale = Vector3.ONE * 1
				#target_position = bud.leader.cursor.global_position
				start_distance = 0.5
				stop_distance = 0.5
				
				var dist = bud.global_position - target_position
				dist.y = 0
				
				if dist.length_squared() < pow(6, 2):
					keep_slide = false
					#expansion = 500
			
			else:
				if bud.resetted:
					bud.resetted = false
			#brickbud.get_child(2).global_position = target_position
			
			var xz_bud = Vector2(bud.global_position.x, bud.global_position.z)
			var xz_target = Vector2(target_position.x, target_position.z)
			var xz_direction = xz_bud.direction_to(xz_target)
			#var xz_dist = xz_bud.distance_to(xz_target) 
			
			if not bud.made_it:
				#if not bud.leader.input.player_swarming:
					
				if (abs(bud.global_position.x - target_position.x) <= stop_distance and abs(bud.global_position.z - target_position.z) <= stop_distance):# or abs(bud.leader.body.velocity.length()) > 0: 
					bud.following = false 
					bud.made_it = true
					bud.time = 0
					
					#if bud.leader.input.player_swarming:
					#	cur_speed = 0
					
					#if bud.cur_dist == 0:
					
						#print(bud.cur_dist)
					
				else:
					bud.following = true
					bud.made_it = false
					bud.cur_dist = 0
					#bud.xz_rand = (randf_range(0, 5))
					
				#else:
				#	bud.following = true
				
			else:
				if not abs(bud.leader.body.velocity.length()) > 0:
					bud.cur_dist = bud.global_position.distance_to(bud.leader.body.global_position)
			
			if bud.made_it and not bud.following:
				#expansion = 10
				
				if abs(bud.leader.body.velocity.length()) > 0:
					if bud.cur_dist != 0:
						if bud.time < bud.cur_dist:
							bud.time += 0.5
				
				#if bud.leader.body.move_time < 1:
					#if bud.global_position.distance_squared_to(target_position) <= pow(start_distance * bud.leader.body.move_time, 2):
					#	bud.following = true
					#	bud.made_it = false
				
				#elif bud.leader.body.move_time >= 1:
				if abs(bud.global_position - target_position).length_squared() >= pow(start_distance, 2) and bud.time >= bud.cur_dist or (bud.leader.input.player_swarming):
					bud.following = true
					bud.made_it = false
			
			#region Speed controls
			
			if bud.following:
				#If the player is just not swarming...
				if not bud.leader.input.player_swarming:
					
					#If the current Brickmin is too close to the player...
					if (abs(Vector3(bud.global_position.x - target_position.x, 0, bud.global_position.z - target_position.z)).length_squared() <= pow(bud.fallback, 2)):
						cur_speed = move_toward(cur_speed, 1.0, delta * (bud.acceleration * 5))
						#slide_it = true
					
					#elif (abs(Vector3(bud.global_position.x - target_position.x, 0, bud.global_position.z - target_position.z)).length_squared() >= pow(bud.fallback * 2, 2)):
						#cur_speed = move_toward(cur_speed, bud.speed * 2, delta * (bud.acceleration * 5))
					#	cur_speed = bud.speed * 1.25
						#repel_weight = 0.75
						#bud.get_node(^"RepelBubble").get_child(0).scale = Vector3.ONE * 0.8
						
						
					else:
						#cur_speed = move_toward(cur_speed, bud.speed, delta * (bud.acceleration * 5))
						cur_speed = bud.speed
			
			#endregion
			
			var target_velocity = Vector3(xz_direction.x, 0.0, xz_direction.y).normalized() * cur_speed
			
			#region Separation forces.
			"""
			if abs(bud.leader.body.velocity.length_squared()) > 0 and not bud.leader.input.player_swarming:
				if abs(bud.global_position.distance_squared_to(target_position)) >= pow(5, 2):
					repel_amt = 30"""
			
			#if abs(bud.global_position.x - bud.leader.body.global_position.x) <= 5 and abs(bud.global_position.z - bud.leader.body.global_position.z) <= 5: 
			#	repel_amt = 20
			
			#if (Engine.get_physics_frames() % 5) == (bud.id % 5):
			repel_force = Utils_Bud.get_repel_vector(bud, 10) * 5
			
			if not bud.is_on_floor():
				if bud.velocity.y > 0:
					repel_force = repel_force * 0.5
			
			else:
				
				bud.jump_timer -= 0.075
			
			#endregion
			
			#region repel controls
			
			if bud.following:
				#repel_weight = 0.5
				if abs(cur_speed) > 0:
					repel_force += repel_force.slide(target_velocity.normalized()).normalized() * repel_force.length()
				"""
				if (abs(bud.leader.body.velocity.x) > bud.leader.body.speed - 1 or abs(bud.leader.body.velocity.z) > bud.leader.body.speed - 1 and not bud.leader.input.player_swarming) or keep_slide:
					if bud.velocity.dot(target_velocity) > 0.5:
						if abs(bud.global_position.distance_squared_to(target_position)) > pow(bud.fallback, 2):
							repel_force = repel_force.slide(target_velocity.normalized())
			
			elif not bud.following:
				target_velocity = Vector3.ZERO"""
			
			#endregion
			
			#slide_repel = slide_repel.move_toward(repel_force, delta * 100)
			
			var final_force = repel_force + target_velocity
			final_force.y = 0
			
			#bud.get_child(2).global_position = bud.global_position + (final_force.normalized() * 3)
			
			var cur_move = bud.velocity.move_toward(final_force, delta * cur_accel)
			
			bud.comb_force = cur_move
			
			#region Stop Brickbud from walking off of ledges.
			
			if bud_data["near_cliff"]:
				
				cur_move = Utils_Bud.cliff_slide(cur_move, bud_data["normals"])
				
				if bud.leader.body.jump_to:
					bud.wanna_jump = true
					
					if bud_data["jump_to"]: 
						if (bud_data["jump_to"].direction_to(bud.global_position)).dot(bud.leader.body.global_position.direction_to(bud.global_position)) > 0.5:
							
							if not bud_data["walk_off"]:
								
								if bud.jump_timer <= 0 and abs(bud.leader.body.global_position.distance_to(bud.global_position)) > 1:
									
									#var rand_offset = randf_range(0, offset_amt)
									var rand_offset = randf_range(2, 2.5)
									
									bud.t = 0.0
									bud.start = bud.global_position
									bud.end = bud.global_position + (bud.global_position.direction_to(bud_data["jump_to"]) * (bud.global_position.distance_to(bud_data["jump_to"]) + rand_offset))
									bud.mid = ((bud_data["jump_to"]) + bud.global_position)/2
									bud.mid.y = bud.jump_height + max(bud.global_position.y, bud_data["jump_to"].y)
									bud.state = Utils_Bud.state.AIRBORNE
									bud.gapjumped = true
									bud.jump_timer = randf_range(0, 0.2)
						
						elif bud_data["walk_off"]:
							cur_move = bud.velocity.move_toward(final_force.limit_length(cur_speed), delta * cur_accel)
				else:
					if abs(bud.global_position.distance_to(bud.leader.body.global_position)) < 1:
						cur_move = Vector3.ZERO
				
			else:
				bud.wanna_jump = false
			
			#endregion
			
			bud.velocity = cur_move
			
			bud.velocity.y = y_velocity - (delta * Constants.gravity)
			
			if bud.is_on_floor():
				
				if bud_data["hop_up"] and not bud_data["near_cliff"]:
					bud.velocity.y += bud.jump_power * Constants.jump_power_mult
				
			bud.last_pos = bud.global_position
			
			bud.move_and_slide()
	
	else:
		bud.state = Utils_Bud.state.IDLE

func generateOffset(divisions: int, max_dist: float) -> Vector3:
	var circle = TAU / divisions
	var rand = (randi() % divisions) * circle
	
	var newpos = Vector3.ZERO
	
	var dist = round(randf_range(2, max_dist))
	
	newpos.x = cos(rand) * dist
	newpos.z = sin(rand) * dist
	#var rand_z = randi() & divisions
	#var new_pos = ( Vector3(randi(-360, 360), 0, randf_range(-360, 360)).normalized() * randf_range(2, 5) )
	newpos.y = 0
	return newpos

"""
##Return a normalized vector pointing away from any too-close neighbors.
func get_repel_vector(bud: CharacterBody3D, check_cap: float) -> Vector3:
	
	var neighbors_checked: int = 0
	var repel_force: Vector3 = Vector3.ZERO
	
	for i in bud.repel_bubble.neighbors:
		
		var difference = bud.global_position - i.global_position
		
		if difference.length_squared() < 0.0001:
			repel_force += Vector3(randf() - 0.5, 0, randf() - 0.5)
		
		else:
			repel_force += difference.normalized()
		
		neighbors_checked += 1
		
		if neighbors_checked >= check_cap:
			break
		
	return repel_force.normalized()"""
