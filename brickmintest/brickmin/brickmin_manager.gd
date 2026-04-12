extends Node3D

@onready var map_RID = get_world_3d().get_navigation_map()
@onready var leaders = get_tree().get_nodes_in_group("leaders")

var count: int = 0
var total_min = []
var leader_bodies = []

signal total_min_update

func _spawn_min(_player, spawn_pos: Vector3, scene: Node):
	
	total_min_update.emit()
	
	count += 1
	
	if leaders and not leader_bodies:
		for i in leaders:
			#var player_body = (i.get_child(0).get_child(0))
			var player_body = i.get_node(^"Body").get_node(^"CharacterBody3D")
			leader_bodies.append(player_body)
	
	if count <= 100:
		
		var min_ref = preload("res://brickmin/base_brickmin.tscn")
		
		if min_ref:
			var new_min = min_ref.instantiate()
			
			scene.add_child(new_min)
			total_min.append(new_min)
			new_min.global_position = spawn_pos
			new_min.name = ("min " + str(count))
			new_min.id = total_min.size()
			new_min.state = load("res://brickmin/brickmin_states/idle_state.tres")
		
		

func _physics_process(delta: float) -> void:
	var all_min = get_tree().get_nodes_in_group("brickmin")
	var dict_all = {}
	
	#if leader_bodies:
		#leaders[0].get_child(3).global_position = leader_bodies[0].global_position + (Vector3.DOWN * 1.5)
	
	for i in all_min:
		
		if not i.state:
			i.state = load("res://brickmin/brickmin_states/idle_state.tres")
		
		var hop_to_position: Vector3 = Vector3.ZERO
		var near_cliff: bool = false
		var ledge_norms = [
			Vector3.ZERO, #center-left
			Vector3.ZERO, #center-right
		]
		var path: PackedVector3Array
		var path_index = 0
		var walk_off: bool = false
		
		var targ_velo = Vector3.ZERO
		var jump_to = Vector3.ZERO
		
		if i.state is FollowState:
			
			var space_state = get_viewport().find_world_3d().direct_space_state
			var cur_velo_length = clamp(i.velocity.length(), 0, i.speed)
			
			if i.leader:
				
				var player_obj = i.leader
				var cursor = player_obj.get_node(^"Cursor")
				var swarming = player_obj.get_node(^"InputHandler").player_swarming
				var leader_body = player_obj.get_node(^"Body").get_node(^"CharacterBody3D")
				
				if abs(leader_body.velocity.length()) > 0 or i.being_called:
					cur_velo_length = clamp(i.velocity.length(), 1, i.speed)
					i.being_called = false
					
				var target = leader_body.global_position
				
				if swarming:
					if cursor.get_node(^"Pointer"):
						target = cursor.get_node(^"Pointer").global_position
					
					else:
						target = cursor.global_position
				
				if abs(leader_body.global_position.y - target.y) < 1.1 and not swarming:
					
					var dir_to_targ = (target - i.global_position)
					dir_to_targ.y = 0.0
					dir_to_targ = dir_to_targ.normalized()
					
					var wallcheckpf1 = PhysicsRayQueryParameters3D.create(i.global_position, i.global_position + (dir_to_targ * 2), 1)
					wallcheckpf1.exclude = [i.get_rid()]
					var wallcheckpf1_result = space_state.intersect_ray(wallcheckpf1)
					
					var wallcheckpf2 = PhysicsRayQueryParameters3D.create(i.global_position, i.global_position + (dir_to_targ * 20), 1)
					wallcheckpf2.exclude = [i.get_rid()]
					var wallcheckpf2_result = space_state.intersect_ray(wallcheckpf2)
					
					i.cur_pos = i.global_position
					
					i.get_child(3).global_position = i.global_position + (dir_to_targ * 2)
					
					if wallcheckpf1_result:
						i.time_before_pathfind -= 0.5
						
					elif not wallcheckpf1_result and not wallcheckpf2_result:
						i.time_before_pathfind = 3
					
					if i.time_before_pathfind <= 0 and wallcheckpf2_result:
						#print("yes")
						i.follow_index = 0
						var map: RID = get_world_3d().get_navigation_map()
						var pf_params = NavigationPathQueryParameters3D.new()
						var pf_result = NavigationPathQueryResult3D.new()
						
						if NavigationServer3D.map_get_iteration_id(map) > 0:
							pf_params.map = map
							pf_params.start_position = i.cur_pos
							pf_params.target_position = target
							
							pf_params.navigation_layers = 1
							
							NavigationServer3D.query_path(pf_params, pf_result)
							
							path = pf_result.get_path()
				
				targ_velo = i.global_position.direction_to(target)
				targ_velo.y = 0.0
				
				var wallcheck = PhysicsRayQueryParameters3D.create(i.global_position, i.global_position + targ_velo * cur_velo_length, 1)
				wallcheck.exclude = [i.get_rid()]
				var wallcheck_result = space_state.intersect_ray(wallcheck)
				
				if wallcheck_result:
					
					var above_pos = Vector3(0.0, 3.0, 0.0) + (Vector3(targ_velo.x, 0.0, targ_velo.z) * 10)
					
					var ledgecheck = PhysicsRayQueryParameters3D.create(i.global_position + above_pos, i.global_position + targ_velo, 1)
					ledgecheck.exclude = [i.get_rid()]
					var ledgecheck_result = space_state.intersect_ray(ledgecheck)
					
					if ledgecheck_result:
						if ledgecheck_result["normal"].y != 0:
							hop_to_position = ledgecheck_result["position"]
				
				var cur_vel = i.comb_force
				cur_vel.y = 0.0
				
				var xz_cur_vel = Vector3(cur_vel.x, 0.0, cur_vel.z)
				xz_cur_vel = xz_cur_vel
				
				var right_vel = xz_cur_vel.cross(Vector3.UP)
				right_vel = Vector3(right_vel.x, 0.0, right_vel.z)
				
				var length: float = 2
				
				var offsets = [
					(xz_cur_vel.normalized() * length) - (right_vel.normalized() * length/2), #center-left
					(xz_cur_vel.normalized() * length) + (right_vel.normalized() * length/2), #center-right
				]
				
				var bottom = Vector3(0.0, -i.get_child(1).mesh.height/2 - 0.1, 0.0)
				var end_pos = i.global_position + bottom
				
				var high = Vector3(0.0, 5.0, 0.0)
				
				if i.is_on_floor():
					
					var in_front = i.global_position
					var start_pos = i.global_position
					
					for k in range(offsets.size()):
						
						var cur_offset = offsets[k]
						in_front = i.global_position + cur_offset
						start_pos = i.global_position + bottom + cur_offset
						
						var groundcheck = PhysicsRayQueryParameters3D.create(in_front + (Vector3.UP * 1), in_front + (Vector3.DOWN * 5), 1)
						groundcheck.exclude = [i.get_rid()]
						var groundcheck_result = space_state.intersect_ray(groundcheck)
						
						var normalray = PhysicsRayQueryParameters3D.create(start_pos, end_pos, 1)
						normalray.exclude = [i.get_rid()]
						var normalray_result = space_state.intersect_ray(normalray)
						
						if not groundcheck_result:
							near_cliff = true
							
							if normalray_result:
								match int(k):
									0: 
										ledge_norms[k] = normalray_result["normal"]
									1: 
										ledge_norms[k] = normalray_result["normal"]
				
				if i.wanna_jump:# and i.leader and leader_body.jump_to:
					
					var jump_dist = (leader_body.jump_to - i.global_position)
					var max_jump = 15
					
					jump_dist.y = 0.0
					
					if abs(jump_dist.length()) >= max_jump:
						jump_dist = jump_dist.limit_length(max_jump)
					
					var start = i.global_position + (jump_dist) + high
					var end = i.global_position + (jump_dist)
					end.y = leader_body.jump_to.y - 5
					
					var jumpray = PhysicsRayQueryParameters3D.create(start, end, 1)
					jumpray.exclude = [i.get_rid()]
					var jumpray_result = space_state.intersect_ray(jumpray)
					
					var length2 = length
					
					if i.velocity == Vector3.ZERO:
						length2 = 10
					
					var to_player = i.global_position.direction_to(leader_body.global_position) * (length2 + 0.5)
					var high2 = Vector3(to_player.x, 0.0, to_player.z)
					var low2 = Vector3(to_player.x, -i.get_child(1).mesh.height/2 - 0.1, to_player.z)
					
					var groundcheck2 = PhysicsRayQueryParameters3D.create(i.global_position + high2, i.global_position + low2, 1)
					groundcheck2.exclude = [i.get_rid()]
					var groundcheck_result2 = space_state.intersect_ray(groundcheck2)
					
					if not groundcheck_result2 and jumpray_result:
						jump_to = jumpray_result["position"]
						#i.get_child(3).global_position = jumpray_result["position"]
					
					if jump_to.y:
						if jump_to.y > leader_body.global_position.y:
							walk_off = true
		
		var dict_individual = {
			"hop_to": hop_to_position,
			"near_cliff": near_cliff,
			"normals": ledge_norms,
			"jump_to": jump_to,
			"walk_off": walk_off,
			"follow_path": path,
			"path_index": path_index,
		}
			
		if i.state:
			i.state._update_min(i, delta, dict_individual, dict_all)
