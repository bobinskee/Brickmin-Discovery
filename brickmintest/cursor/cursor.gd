extends Node3D
## 4/12/26
## Handles the cursor, which is the little dot that follows
## the mouse, and the landing visual, which is the little
## graphic that follows under the cursor or onto surfaces
## that are being intersected. The logic and calculations
## are done in _physics_process, but the actual
## global_position setting is done in _process.

#region Variable dump
@onready var pointer = $Pointer #The dot that follows the mouse.
@onready var camera = $"../Body/CharacterBody3D/PlayerCamera/SpringArm3D/Camera3D" #Duh.
@onready var player_body = $"../Body/CharacterBody3D" #Body of the player who the cursor belongs to.
@onready var land_vis = $LandVis #The point projected to visualize the cursor's location in the world.
@onready var decal = $LandVis/CursorDecal #The actual decal for the land visual.
@onready var player = $".." #The player themself.
@onready var input_handler = $"../InputHandler" #Get some inputs.

@export var max_range: float = 20.0 #How far the cursor can go.

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
	if Input.is_action_pressed("pressed_1"):
		BrickminManager._spawn_min(player, pointer.global_position, get_tree().current_scene)
	
func _physics_process(_delta: float) -> void:
	## Do 3 raycasts, then a bunch of if-statements.
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
	
	if rayhit_pointer and not too_far:
		#Something has been hit, and the pointer is in bounds.
		physics_pos_pointer = (rayhit_pointer["position"])
		
	elif not rayhit_pointer and not too_far:
		#Nothing has been hit, and the pointer is still in bounds.
		physics_pos_pointer = max_vector
	
	elif too_far:
		#Cursor's out of bounds! Extend the pointer as far as we 
		#allow it in the direction of the player to the pointer.
		physics_pos_pointer = player_body.global_position + (player_body.global_position.direction_to(pointer_would_be_at) * max_range) 
	
	#endregion
	
	#region Stuff pertaining to the landing visual.
	## The player-to-pointer raycast is mainly for the landing
	## visual, actually. Though, it's just basic if-statements
	## here.
	
	#If there's something between the player and pointer...
	if rayhit_playertopointer: 
		#Rotate the land visual to match and move its physics position to where
		#the hit occurred.
		land_vis.rotation.x = rayhit_playertopointer["normal"].z * 90.0
		land_vis.rotation.z = rayhit_playertopointer["normal"].x * 90.0
		physics_pos_landvis = rayhit_playertopointer["position"]
	
	#But if there isn't anything between the player and pointer,
	#and there's ground underneath...
	elif rayhit_landvis and not rayhit_playertopointer:
		#No land visual rotation, and again, set the physics position to hit
		#location.
		land_vis.rotation = Vector3.ZERO
		physics_pos_landvis = rayhit_landvis["position"]
	
	#Otherwise, your pointer is above a void, or very deep pit, so...
	else:
		#Default land visual physics position the pointers.
		physics_pos_landvis = physics_pos_pointer
	
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
