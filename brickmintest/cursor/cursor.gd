extends Node3D
## 4/12/26
## Handles the cursor, which is the little dot that follows
## the mouse, the landing visual, which is the little
## graphic that follows under the cursor or onto surfaces
## that are being intersected, and the calldot, which is 
## what calls Brickmin into your squad.
## The logic and calculations are done in _physics_process,
## but the actual global_position and mesh transforming
## is done in _process.

#region Variables

@onready var pointer = $Pointer #The dot that follows the mouse.
@onready var camera = $"../Body&Camera/CharacterBody3D/PlayerCamera/SpringArm3D/Camera3D" #Duh.
@onready var player_body = $"../Body&Camera/CharacterBody3D" #Body of the player who the cursor belongs to.
@onready var land_vis = $LandVis #The point projected to visualize the cursor's location in the world.
@onready var decal = $LandVis/CursorDecal #The actual decal for the land visual.
@onready var player = $".." #The player themself.
@onready var input_handler = $"../InputHandler" #Get some inputs.
@onready var testmesh = $"../MeshInstance3D"
@onready var calldot = $Pointer/CallDot/CallDotMesh

@export var max_range: float = 20.0 #How far the cursor can go.
@export var max_rad:float = 7.5 #How big the calldot can get.
@export var grow_speed: float = 20.0 #How fast the calldot grows.

#The shape the calldot hitball will use.
var calldot_shape := SphereShape3D.new()

#The actual calldot hitball. Used for calling Brickmin. 
#(Literally a hitbox but a ball lol).
var calldot_hitball := PhysicsShapeQueryParameters3D.new()

#The current radius of the calldot shape.
var curr_rad: float = 0.0

#How far to look under the pointer for if there's ground.
var look_down: Vector3 = Vector3.DOWN * 50 

#The distance between the player and pointer.
var dist_playertopointer: float = 0.0 

#Where the pointer would be. 
var pointer_would_be_at: Vector3 = Vector3.ZERO

#The pointer's position in the _physics_process. The actual
#pointer will have its position updated to this in regular
#_process because it's mainly a visual thing.
var physics_pos_pointer: Vector3 = Vector3.ZERO 

#Same as the variable above, but for the landvis
var physics_pos_landvis: Vector3 = Vector3.ZERO

#endregion

func _input(_event: InputEvent) -> void:
	#Only for testing.
	#Will be deleted when done testing.
	if Input.is_action_pressed("pressed_1"):
		BrickminManager._spawn_min(player, pointer.global_position, get_tree().current_scene)
	
func _physics_process(delta: float) -> void:
	## Do 3 raycasts, then a bunch of if-statements, and
	## stuff for calling Brickmin.
	## No actual object positions are set here since the
	## objects are all just visualizers.
	
	#Needed for raycasts.
	var space_state = get_world_3d().direct_space_state
	
	#region Raycasts gallore.
	## 3 Raycasts:
	## 1: Fundamental; shot from the mouse 2D position to the 3D world.
	##    Dictates the position of the pointer.
	## 2: Landvis; points down from the pointer position (physics position)
	##    to check if there's ground to place the landing visual on.
	## 3: Player-to-pointer; goes from the player to the raw pointer 
	##    position to see if anything is between. If so, stamp the landing
	##    visual there, instead.
	## 4: Wall-finder; used to verify if the pointer is at a wall or not.
	 
	#Get the distance from the camera to the player.
	var cam_player_dist = camera.global_position.distance_to(player_body.global_position)
	
	var curr_mouse_pos = input_handler.mouse_position #Current mouse position on screen.
	
	#Start the mouse 2D-to-3D raycast at the mouse 2D screen position.
	var from_camera = camera.project_ray_origin(curr_mouse_pos)
	
	#The longest/maximum-length vector used.
	#Goes in the direction of the projected ray normal, to the max set range, 
	#with camera-player distance offset soeverything lines up.
	#This is also used if the raycast doesn't hit anything.
	var max_vector = from_camera + camera.project_ray_normal(curr_mouse_pos) * (max_range + cam_player_dist)
	
	#The fundamental raycast projected from the 2D mouse position to the 3D world.
	#This isn't visualized, it's just the raw mouse to 3D world raycast.
	#If this ray hits an object in the world, it makes the pointer move to
	#where the collision occurred.
	var ray_pointer = PhysicsRayQueryParameters3D.create(from_camera, max_vector, 1)
	ray_pointer.exclude = [player_body.get_rid()]
	var rayhit_pointer = space_state.intersect_ray(ray_pointer)
	
	#Raycast for finding ground to place the landing visual. 
	#Landing visual is basically to show the x-z position of the pointer(physics position).
	var ray_landvis = PhysicsRayQueryParameters3D.create(physics_pos_pointer, physics_pos_pointer + look_down, 1)
	ray_landvis.exclude = [player_body.get_rid()]
	var rayhit_landvis = space_state.intersect_ray(ray_landvis)
	
	#Direction of the player to the pointer(physics position).
	var dir_playertopointer = (physics_pos_pointer - player_body.global_position).normalized()
	var end_playerpointer = player_body.global_position + (dir_playertopointer * max_range)
	
	#A raycast that goes from the player to the position of the pointer.
	#If something is hit by this, the landing visual is moved to that spot.
	var ray_playertopointer = PhysicsRayQueryParameters3D.create(player_body.global_position, end_playerpointer, 1)
	ray_playertopointer.exclude = [player_body.get_rid()]
	var rayhit_playertopointer = space_state.intersect_ray(ray_playertopointer)
	
	#A point that checks if the pointer is touching a wall.
	var end_findwall = physics_pos_pointer + (dir_playertopointer * 1.5)
		#testmesh.global_position = end_findwall
	
	#Raycast for finding if the pointer is at a wall. It checks the pointer
	#position to in the direction of the pointer to the player, and looks for
	#walls and such.
	var ray_findwall = PhysicsRayQueryParameters3D.create(physics_pos_pointer, end_findwall, 1)
	ray_findwall.exclude = [player_body.get_rid()]
	ray_findwall.hit_from_inside = true #Needed for it to detect walls.
	var rayhit_foundwall = space_state.intersect_ray(ray_findwall)
	
	#endregion
	
	#region Logic to decide what raycast data to use and what not.
	## Just a lot of if-statements and one comparison.
	## It's nothing complicated, just a lot.
	
	#We've hit ground or a wall or something.
	if rayhit_pointer: 
		dist_playertopointer = player_body.global_position.distance_to(rayhit_pointer["position"])
		pointer_would_be_at = (rayhit_pointer["position"])
	
	#Aiming at the sky, or simply not hitting anything.
	else: 
		dist_playertopointer = player_body.global_position.distance_to(max_vector)
		pointer_would_be_at = max_vector #Set ray to max distance possible.
	
	var too_far: bool = false #Is the distance too far?
	
	#Self-explanatory, but this is used to ensure the actual pointer
	#never exceeds its set range.
	if dist_playertopointer > max_range:
		too_far = true
		
	#Something has been hit, and the pointer is in bounds.
	if rayhit_pointer and not too_far:
		#Set the physics position of the pointer to whatever position
		#the hit was at.
		physics_pos_pointer = (rayhit_pointer["position"])
	
	#Nothing has been hit, and the pointer is still in bounds.
	elif not rayhit_pointer and not too_far:
		#The physics position of the pointer is at max.
		physics_pos_pointer = max_vector
	
	#Cursor's out of bounds!
	elif too_far:
		#Extend the pointer as far as we allow it in the 
		#direction of the player to the pointer.
		physics_pos_pointer = player_body.global_position + (player_body.global_position.direction_to(pointer_would_be_at) * max_range) 
	
	#endregion
	
	#region Stuff pertaining to the landing visual.
	## The player-to-pointer raycast is mainly for the landing
	## visual, actually. Though, it's just basic if-statements
	## here.
	
	#If there's something between the player and pointer and the
	#pointer is at a wall...
	if rayhit_playertopointer and rayhit_foundwall:
		 
		#Rotate the land visual to match and move its physics position to where
		#the hit occurred.
		land_vis.rotation.x = rayhit_playertopointer["normal"].z * 90.0
		land_vis.rotation.z = rayhit_playertopointer["normal"].x * 90.0
		physics_pos_landvis = rayhit_playertopointer["position"]
	
	#If the pointer isn't at a wall and there's ground underneath...
	elif rayhit_landvis and not rayhit_foundwall:
		#No land visual rotation, and again, set the physics position to hit
		#location.
		land_vis.rotation = Vector3.ZERO
		physics_pos_landvis = rayhit_landvis["position"]
	
	#Otherwise, your pointer is above a void, or very deep pit, so...
	else:
		#Default land visual physics position the pointers.
		physics_pos_landvis = physics_pos_pointer
	
	#endregion
	
	#region Calling Brickmin
	
	#If the player is calling...
	if input_handler.player_calling:
		
		#Increase the current radius to the maximum radius size. Its
		#growth speed is delta times the growth speed.
		curr_rad = move_toward(curr_rad, max_rad, delta * grow_speed)
		
		#The radius of the calldot shape is set to the current radius.
		calldot_shape.radius = curr_rad
		
		#The actual hitball has its shape, transform (positioning),
		#and collision mask set.
		#Had to make a custom function become I'm a lazy chud who
		#doesn't feel like dealing with deciphering binary layer
		#masks lol.
		calldot_hitball.shape = calldot_shape
		calldot_hitball.transform.origin = physics_pos_pointer
		calldot_hitball.collision_mask = General._set_mask(3)
		
		#Check if anything collided with the hitball.
		var called = get_world_3d().direct_space_state.intersect_shape(calldot_hitball)
		
		#For all the things that collided with the hitball...
		for i in called:
			
			#Make a variable out of the current iteration.
			var who_was_called = i["collider"]
			
			#If the current iteration is a Brickmin...
			if who_was_called.is_in_group("brickmin"):
				
				#make the leader the player that called them,
				who_was_called.leader = player 
				
				#put them into the follow state,
				who_was_called.state = load("res://brickmin/brickmin_states/follow_state.tres")
				
				#zero their t (as a safety measure)
				#(This is for when they're in throw state or
				#gap jump state),
				who_was_called.t = 0.0
				
				#and make their being_called variable true.
				who_was_called.being_called = true
	
	#Otherwise, player isn't calling.
	else:
		#Keep the current radius at 0.
		curr_rad = 0.0
	
	#endregion
	
func _process(_delta: float) -> void:
	## This is for the visuals-side of the cursor.
	## _process is dependent on your device framerate and not the 60fps
	## that _physics_process uses, so we use this for smoother visuals
	## while retaining consistency using _physics_process.
	
	#Variable for determining the rotation speed of the landing visual
	#decal.
	var rotation_speed:float = 0.02
	
	#Make the landing visual decal rotate a tad faster if aiming.
	if input_handler.player_aiming:
		rotation_speed = 0.05
	
	#Make the decal spin.
	decal.rotation.y += rotation_speed
	
	#Set the pointer and landing visual to their final determined
	#physics positions.
	pointer.global_position = physics_pos_pointer
	land_vis.global_position = physics_pos_landvis
	
	#Set the calldot mesh scale to whatever the current radius is.
	#Vector3.ONE is just to make a Vector3 with all floats equal to
	#the current radius.
	calldot.scale = Vector3.ONE * curr_rad
