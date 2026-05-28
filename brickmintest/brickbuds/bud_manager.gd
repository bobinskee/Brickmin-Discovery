extends Node3D

#region Variables

@onready var map_RID = get_world_3d().get_navigation_map()
@onready var leaders = get_tree().get_nodes_in_group("leaders")

@export var max_buds: float = 200
@export var update_per_frame: float = 200

#var idle_state = preload("res://brickmin/brickmin_states/idle_state.gd").new()
#var follow_state = preload("res://brickmin/brickmin_states/follow_state.gd").new()
#var airborne_state = preload("res://brickmin/brickmin_states/airborne_state.gd").new()

var total_buds = []
var leader_bodies = []

var spawn_count: int = 0

var check_length: float = 6
var hop_height: float = 3
var gap_jump_height: float = 5
var max_jump_dist:float = 15

var group_index: int = 0
var group_amt: int = 2

var ray = PhysicsRayQueryParameters3D.new()

var bud_ref = preload("res://brickbuds/base_brickbud.tscn")

var bud_idle = []
var bud_following = []

var update_index: int = 0

var prev_frame: int = -1

#endregion

func _ready() -> void:
	ray.collision_mask = 1

func _spawn_buds(spawn_pos: Vector3, scene: Node):
	## Spawn new (base) Brickbud.
	
	spawn_count += 1 #Increase the count.
	
	#Update the check for the amount of leaders.
	#If there are any leaders in the leader group...
	if leaders:
		
		#for each leader...
		for i in leaders:
			
			#if their body has not been logged in the leader_bodies
			#array...
			if not i.body in leader_bodies:
				
				#add their body to the array.
				leader_bodies.append(i.body)
	
	#If the count is less than or equal to 100...
	if spawn_count <= max_buds:
		
		#and the reference for the base Brickmin exists...
		if bud_ref:
			
			#create a new Brickmin.
			var new_bud = bud_ref.instantiate()
			
			scene.add_child(new_bud) #Add the new Brickmin to the scene,
			total_buds.append(new_bud) #and the total_min array.
			new_bud.global_position = spawn_pos #Set its spawn position.
			new_bud.name = ("bud " + str(spawn_count)) #Give it a name.
			new_bud.id = total_buds.size() #Give it a unique number ID.
			new_bud.state = BudUtils.state.IDLE
	
	#Make sure the count never exceeds 100.
	spawn_count = clamp(spawn_count, 0, max_buds)
	
	update_index = ceil(total_buds.size() / update_per_frame)

func _physics_process(delta: float) -> void:
	## Used to update all Brickmin in an efficient manner by iterating
	## through all the Brickmin present.
	
	#Need this for raycasts.
	var space_state = get_world_3d().direct_space_state
	
	#print(cur_frame)
	
	#Get all the Brickmin in the crrrent tree.
	#var all_buds = get_tree().get_nodes_in_group("brickbuds")
	
	if total_buds:
		
		if Engine.get_frames_drawn() != prev_frame:
			BudUtils.setup_spatial_grid(total_buds)
			prev_frame = Engine.get_frames_drawn()
		
		for bud in total_buds:
			
		#For each Brickmin...
			#If it doesn't have a state, set it to the idle state.
			#if not bud.state:
			#	bud.state = General.idle_state
			
			#region Variables
			
			var hop_up: bool = false #Should the Brickmin do a hop or not.
			var near_cliff: bool = false #If the Brickmin is near a cliff.
			
			#If the Brickmin should walk off a cliff.
			var walk_off: bool = false 
			
			#Ledge normal array. Used to log the angles of any nearby
			#ledges. Is used in the follow state to make Brickmin not
			#walk off legdes.
			var ledge_norms = [
				Vector3.ZERO, #center-left
				Vector3.ZERO, #center-right
			]
			
			var path: PackedVector3Array
			var path_index = 0
			
			var targ_dir = Vector3.ZERO #Target direction of the Brickmin.
			var jump_to = Vector3.ZERO #Where the Brickmin should gap-jump to.
			
			#endregion
			
			ray.exclude = [bud.get_rid()]
			
			#region Stuff for the Brickmin in follow state.
			
			if bud.state == BudUtils.state.IDLE or bud.state == BudUtils.state.FOLLOW:
				
				#Make sure the velocity length (speed) never exceeds the set Brickmin 
				#speed.
				var cur_velo_length = clamp(bud.velocity.length(), 0, bud.speed)
				
				#Make sure the Brickmin has a leader (extra safety check).
				if bud.leader:
					
					#If the leader is moving, or the Brickmin is being called...
					if abs(bud.leader.body.velocity.length()) > 0 or bud.being_called:
						
						#The velocity of the Brickmin needs to be moving, so its
						#length is clamped between 1 and the set Brickmin speed.
						cur_velo_length = clamp(bud.velocity.length(), 1, bud.speed)
						
						#Also set being_called to false.
						bud.being_called = false
					
					#Create a target variable, default it to the leader position.
					var target = bud.leader.body.global_position
					
					#If there is a cursor found and the leader is swarming...
					if bud.leader.cursor and bud.leader.input.player_swarming:
						
						#set the target to the cursor, instead.
						target = bud.leader.cursor.global_position
					
					#Make the Brickmin target velocity the direction to the current
					#target, and flatten the y-axis.
					targ_dir = bud.global_position.direction_to(target)
					targ_dir.y = 0.0
					
					"""
					if abs(leader_body.global_position.y - target.y) < 1.1 and not swarming:
						
						var dir_to_targ = (target - bud.global_position)
						dir_to_targ.y = 0.0
						dir_to_targ = dir_to_targ.normalized()
						
						var wallcheckpf1 = PhysicsRayQueryParameters3D.create(bud.global_position, bud.global_position + (dir_to_targ * 2), 1)
						wallcheckpf1.exclude = [bud.get_rid()]
						var wallcheckpf1_result = space_state.intersect_ray(wallcheckpf1)
						
						var wallcheckpf2 = PhysicsRayQueryParameters3D.create(bud.global_position, bud.global_position + (dir_to_targ * 20), 1)
						wallcheckpf2.exclude = [bud.get_rid()]
						var wallcheckpf2_result = space_state.intersect_ray(wallcheckpf2)
						
						bud.cur_pos = bud.global_position
						
						bud.get_child(3).global_position = bud.global_position + (dir_to_targ * 2)
						
						if wallcheckpf1_result:
							bud.time_before_pathfind -= 0.5
							
						elif not wallcheckpf1_result and not wallcheckpf2_result:
							bud.time_before_pathfind = 3
						
						if bud.time_before_pathfind <= 0 and wallcheckpf2_result:
							#print("yes")
							bud.follow_index = 0
							var map: RID = get_world_3d().get_navigation_map()
							var pf_params = NavigationPathQueryParameters3D.new()
							var pf_result = NavigationPathQueryResult3D.new()
							
							if NavigationServer3D.map_get_iteration_id(map) > 0:
								pf_params.map = map
								pf_params.start_position = bud.cur_pos
								pf_params.target_position = target
								
								pf_params.navigation_layers = 1
								
								NavigationServer3D.query_path(pf_params, pf_result)
								
								path = pf_result.get_path()
					"""
					#region Brickmin hopping.
					
					## This bit is what determines whether the Brickmin should hop up
					## a ledge or not.
					
					#Make the first raycast to check for if a wall is in front of the Brickmin.
					#It faces in the direction the Brickmin is moving (targ_velo), with the
					#vector scaling based on the current speed (cur_velo_length). 
					ray.from = bud.global_position
					ray.to = bud.global_position + (targ_dir * cur_velo_length)
					var wall_in_front = space_state.intersect_ray(ray)
					
					#If a wall was detected...
					if wall_in_front:
						
						#This is the start of the second raycast. It faces in the direction of the
						#target direction, and scales based on check_length. 
						var start = targ_dir * check_length
						
						#This is the actual height of the start of the second raycast, and dictates 
						#how high a ledge can be for a Brickmin to attempt to hop up.
						start.y = hop_height
						
						ray.from = bud.global_position + start
						
						#The end of the second raycast, which is just the same xz-position as the
						#start but remains at the Brickmin y-position.
						ray.to = bud.global_position + (targ_dir * check_length)
						
						#The second raycast, used for checking if there is a ledge that can be hopped up.
						#var ledgecheck = PhysicsRayQueryParameters3D.create(bud.global_position + start, bud.global_position + end, 1)
						var short_enough_ledge = space_state.intersect_ray(ray)
						
						#If there is a viable ledge that can be hopped up,
						if short_enough_ledge:
							
							#and the ledge is a vertical wall (soon this will take elements from
							#the floor normal),
							if abs(short_enough_ledge["normal"].y) == 1:
								
								#the Brickmin can hop up.
								hop_up = true
					
					#endregion
				
				#region Make Brickmin not walk off legdes (by default).
				## This just gets the normals of any nearby ledges and then
				## sends them to the Brickmin follow state to be used.
				
				#Get the current velocity of the Brickmin, and flatten the
				#y-axis.
				var cur_vel = bud.comb_force
				cur_vel.y = 0.0
				
				#Shift the cur_vel to the right using .cross with Vector3.UP.
				#Also flatten the y-axis. This is needed so the angles can be
				#checked to the left and right sides, not just forwards.
				var right_vel = cur_vel.cross(Vector3.UP)
				right_vel.y = 0
				
				#Length of the vectors to be used for ledge checking.
				var length: float = 2
				
				#Offsets that create vectors that point to the center-left and
				#center-right. Two are needed to detected whether or not the
				#Brickmin is at a corner, as just one vector is insufficient.
				var offsets = [
					(cur_vel.normalized() * length) - (right_vel.normalized() * length/2), #center-left
					(cur_vel.normalized() * length) + (right_vel.normalized() * length/2), #center-right
				]
				
				#Get the bottom of the Brickmin by getting the mesh height, halving it
				#(since the center is the origin), adding 0.1 to put it to where it can
				#detect the ground, and then only applying this to a y-axis by multiplying
				#by Vector3.UP.
				var bottom = Vector3.UP * -(bud.get_child(1).mesh.height/2 + 0.1)
				
				#If the Brickmin is on the floor...
				if bud.is_on_floor():
					
					#then for each (2) offsets in the array...
					for k in range(offsets.size()):
						
						#set our current offset,
						var cur_offset = offsets[k]
						
						#make a variable that just adds it to the Brickmin position.
						var in_front = bud.global_position + cur_offset
						
						#Check if there is ground in front of the Brickmin. Start the raycast
						#in front of the Brickmin, and end it at the same position but down
						#by how high the Brickmin is allowed to jump.
						ray.from = in_front
						ray.to = in_front + (Vector3.DOWN * gap_jump_height)
						var ground_in_front = space_state.intersect_ray(ray)
						
						#Check for the normal of any nearby ledges. It starts in front of the 
						#Brickmin, but aims just below it so it can hit the ledge of the
						#surface it is standing on. It ends directly under the Brickmin.
						ray.from = in_front + bottom
						#ray.to = ((bud.global_position.direction_to(in_front)) * 5)  + bottom
						ray.to = bud.global_position + bottom 
						var ledge_found = space_state.intersect_ray(ray)
						
						#If there is no ground in front of the Brickmin...
						if not ground_in_front:
							
							#they are indeed near a cliff.
							near_cliff = true
							
							#Furthermore, if we've found a ledge...
							if ledge_found:
								
								#For both offsets, add whatever was logged to the
								#ledge_norms array.
								match int(k):
									0: 
										ledge_norms[k] = Vector3.ZERO
										ledge_norms[k] = ledge_found["normal"]
									1: 
										ledge_norms[k] = Vector3.ZERO
										ledge_norms[k] = ledge_found["normal"]
				
				#endregion
					
					#region Brickmin gap-jumping. 
					
					#This is just another way of clarifying the Brickmin is
					#on the ground, but I didn't feel like having to make like
					#"start1", "end1", "start2", "end2', etc, for every time
					#I needed to have start and end variables for raycasts so
					#yeah this is staying separated by this.
					if bud.wanna_jump and bud.leader and abs(bud.velocity.length()) <= 1:
						
						#Get the distance between where the leader would like the
						#Brickmin to jump, and the position of the Brickmin.
						#Flatten the y again, as per usual.
						#var rand_offset = Vector3(randf_range(0, 1), 0, randf_range(0, 1))
						
						var jump_dist = Vector3(bud.leader.body.jump_to.x - bud.global_position.x, 0, bud.leader.body.jump_to.z - bud.global_position.z)
						
						#If the jump distance exceeds the maximum distance allowed
						#to be jumped, limit it to the max distance.
						if abs(jump_dist.length()) >= max_jump_dist:
							jump_dist = jump_dist.limit_length(max_jump_dist)
						
						#The start is at the Brickmin, with the jump distance as a 
						#vector but the y is flattened so we just add the gap jump
						#height to it. Now, the start is however many units higher
						#than the Brickmin, dictating how high of a gap-jump can be
						#performed.
						ray.from = bud.global_position + jump_dist + (Vector3.UP * gap_jump_height)
						
						#The end is basically a vector starting at the Brickmin
						#and going in the direction and length of the jump_dist.
						var end = bud.global_position + (jump_dist)
						
						#The y-position is the y-position of where to jump to but
						#down by the gap jump height again. This way, the start is 
						#above the end, pointing down towards it.
						end.y = General._get_highest((bud.leader.body.global_position.y - bud.leader.body.bottom), bud.leader.body.jump_to.y, true) - 2 
						ray.to = end
						
						#bud.get_child(2).global_position = end
						
						#This raycast checks if there's any ground at the determined
						#position for the Brickmin to jump to.
						var viable_jump_to = space_state.intersect_ray(ray)
						
						#We need to check in the direction of the Brickmin to see if there is
						#no ground in front. 5 seems like an apt distance to check.
						var check_length_ground = 5
						
						#Make a vector in the direction of player, scaled by the check length for
						#the ground.
						var to_player = bud.global_position.direction_to(bud.leader.body.global_position) * check_length_ground
						
						#Make a variable derived from to_player with flattened y.
						var high = to_player
						high.y = 0
						
						#Make a second variable derived from to_player that has the y set to the bottom
						#of the Brickmin.
						var low = to_player
						low.y = bottom.y
						
						#bud.get_child(3).global_position = bud.global_position + low
						
						#Used to check the ground right in front of the Brickmin, using the high and
						#low positions.
						ray.from = bud.global_position + high
						ray.to = bud.global_position + low
						var ground_is_infront = space_state.intersect_ray(ray)
						
						#If there is no ground right in front of the Brickmin, but there is somewhere
						#the Brickmin can jump to...
						if not ground_is_infront and viable_jump_to:
							
							#Set the jumpray_result to the jump_to.
							#ray.from = viable_jump_to["position"]
							
							#bud.jump_height = 10
							ray.from = bud.global_position + bud.global_position.direction_to(viable_jump_to["position"]) * (bud.global_position.distance_to(viable_jump_to["position"]) + 2)
							ray.to = bud.global_position
							
							var jumping_to_edge = space_state.intersect_ray(ray)
							
							jump_to = viable_jump_to["position"]
							
							if jumping_to_edge and bud.global_position.y <= jump_to.y:
								
								bud.can_extend = false
								
								var recheck_pos = jump_to
								
								recheck_pos += (jumping_to_edge["normal"].cross(Vector3.RIGHT).normalized() * 2)
								
								ray.from = recheck_pos + (Vector3.UP)
								ray.to = recheck_pos - (Vector3.UP)
								
								if space_state.intersect_ray(ray):
									#bud.get_child(2).global_position = recheck_pos
									jump_to = recheck_pos
								
						
						if jump_to.y:
							if jump_to.y > bud.leader.body.global_position.y:
								walk_off = true
					
					#endregion
			
			#endregion
			
			var min_data = {
				"hop_up": hop_up,
				"near_cliff": near_cliff,
				"normals": ledge_norms,
				"jump_to": jump_to,
				"walk_off": walk_off,
				"follow_path": path,
				"path_index": path_index,
			}
			
			if bud.state != null:
				#bud.state._update(i, delta, min_data)
				match bud.state:
					BudUtils.state.IDLE:
						BudUtils.idle_state.update(bud, delta, min_data)
						
					BudUtils.state.FOLLOW:
						BudUtils.follow_state.update(bud, delta, min_data)
					
					BudUtils.state.AIRBORNE:
						BudUtils.airborne_state.update(bud, delta, min_data)
				
				#bud.move_and_slide()
