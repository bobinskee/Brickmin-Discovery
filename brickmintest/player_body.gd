extends CharacterBody3D
## 4/11/26
## This script lets the player move around, jump, and also feeds the jump_to
## position to the Brickmin manager for Brickmin gap jumping.

#region Variable dump
@onready var gimbal: SpringArm3D = $PlayerCamera/SpringArm3D #Gimbal that controls the camera.
@onready var testmesh = $"../../MeshInstance3D"
@onready var input_handler = $"../../InputHandler"

@export var speed: float = 15.0 #Player movement speed.
@export var acceleration: float = 300.0 #How fast player reaches max speed.
@export var jump_power: float = 4.0 #How high player can jump.
@export var jump_buffer_timing: float = 0.5 #Time to give a player a bit of jump leeway if they walk of a ledge but intended to jump.

var y_velocity: float = 0.0 #Previous player y velocity.
var jump_buffer: float = 0.0 #Doesn't do anything just yet...
var can_bufferjump: bool = false #Able to jump.

var has_jumped: bool = false #Whether the player jumped or not.

var swarming: bool = false #Player is holding E to swarm.

var jump_to: Vector3 = Vector3.ZERO #New position for Brickmin to jump to found.
var should_jump: bool = false #The Brickmin want to actually jump to the jump position found.
var shrink_offset: bool = false #Whether the amount of randomization in the Brickmin landing position is shrunk or not (makes where Brickmin jump more precise).

var player_direction: Vector3 = Vector3(0.0, 0.0, 0.0) #Player's current direction.
#endregion

func _ready() -> void:
	##Initialize jump_buffer.
	
	jump_buffer = jump_buffer_timing #Set the jump buffer to the jump buffer's timing.
	
func _physics_process(delta: float) -> void:
	## Makes player move based on camera position, 
	## sets stuff with gravity and velocity,
	## handles jumping and bufferjumping,
	## and handles the jump_to position, which gets fed to the Brickmin manager.
	
	#We need this for raycasts (my beloved).
	var space_state = get_viewport().find_world_3d().direct_space_state 
	
	#region Moving the player based on the camera.
	## Games always feel more natural when they control based on the camera's orientation.
	## (...at least in my experience).
	## This region just defines the forward and right directions,
	## and then converts the 2D directional inputs to 3D ones.
	
	#Gets the forward and right directions from the camera's (or gimbal's) perspective.
	var forward = gimbal.global_basis.z 
	var right = gimbal.global_basis.x
	
	#Take out the y-axis for forward and right.
	forward.y = 0.0 
	right.y = 0.0
	
	#Normalize the x-axis and z-axis.
	forward = forward.normalized()
	right = right.normalized()
	
	#Move the player left, right, forwards, or backwards. How it works:
	#1: Make sure input handler is loaded. We need this for inputs.
	#2: The right pertains to the x-axis, and forward to the z-axis.
	#3: For the axis, it is multiplied by either 0 (no input), 1 (in that direction), or -1 (opposite or that direction).
	#4: right * 1 (D press) = moving right, forward * -1 (S press) = moving backwards
	#if input_handler.input_direction:
	var input_2D = input_handler.input_direction
	player_direction = (right * input_2D.x) + (forward * input_2D.y)
	
	player_direction.y = 0.0 #Remove the y-axis from the direction.
	player_direction = player_direction.normalized() #Normalize the final direction.
	#endregion
	
	#region Player velocity and gravity.
	## Self-explanatory, not much going on here. Just initializing stuff, essentially.
	
	#y_velocity is equal to the velocity.y of the player.
	#This will be used to snapshot the y-velocity of the prior frame.
	y_velocity = self.velocity.y 
	
	#Move the velocity to the player's normalized direction at the set speed...
	#using the established acceleraton and delta for consistency.
	self.velocity = velocity.move_toward((player_direction * speed), (delta * acceleration)) 
	
	#The player velocity.y is equal to the velocity.y of the previous frame...
	#minus the delta times the set gravity.
	self.velocity.y = y_velocity - (delta * General.gravity)
	#endregion
	
	#region Handling jumping and bufferjumping.
	## You already know what jumping is, but what is bufferjumping?
	## While I don't know the actual name for it, I call a bufferjump a jump that can be done
	## if the player has just stepped off a platform (a few frames) but still wants to jump.
	## Because this is a RTS game first, I wanted to make platforming more forgiving by giving
	## players a window to still jump, even if they may have walked off a platform, but for only
	## a few frames. 
	## I know the DKC games had a similar feature, where if you rolled of a ledge you could still
	## do a jump. 
	
	if not is_on_floor(): #If the player has left the ground...
		if self.velocity.y > 0: #And the y velocity has increased at all...
			has_jumped = true #They have jumped
		
		jump_buffer -= delta * 2 #If not on ground, decrease buffer time.
	else:
		has_jumped = false #Hasn't left ground, hasn't jumped.
		jump_buffer = jump_buffer_timing #If player is on ground, jump buffer resets to the jump buffer timing.
	
	if jump_buffer > 0.0 and not has_jumped:
		can_bufferjump = true #Can bufferjump so long as there's buffer time and player didn't already jump.
	else:
		can_bufferjump = false #Cannot bufferjump.
	
	if input_handler.player_jump: #If jump button pressed...
		if can_bufferjump: 
			self.velocity.y = 0 #Cancel out any negative y-velocity from the gravity.
		
		if is_on_floor() or can_bufferjump: #Jump if either conditions are met.
			self.velocity.y += (jump_power * General.jump_power_mult) #Normal jump.
	
	input_handler.player_jump = false #Reset jumping to false 
	#endregion 
	
	#region Position for Brickmin to jump to when gap jumping.
	## Wow! Jumping in a Pikmin-like! Breaking new ground here!
	## This section just handles where the Brickmin will try to jump to. 
	## The jump_to just gets fed to the Brickmin manager, and from there
	## the actual jumping calculations are handled.
	## By default, the Brickmin will try to jump to the player position. 
	## However, if the player is too close to a ledge, Brickmin are prone to
	## falling off. Not good. So, some extra ledge-checking is done to get a
	## direction to move the determined jump position in, and the Brickmin
	## will safely hop there, instead.
	## NOTE: It doesn't function exactly how I imagined, but it does indeed work
	## as intended. In my head, I was thinking more: "If near ledge, move the 
	## jump_to position to a fixed distance away from the detected ledge, and keep
	## it there until the player moves past it." Kind of like setting down a tape
	## measurer; it stays in place but you can move towards it. Maybe one of
	## these days I'll figure out how to do that, but as of now, this works fine.
	## So long as Brickmin don't accidentally jump off ledges, it works.
	
	#The position the Brickmin will jump to when gap jumping. By default, this is the players...
	#global position.
	jump_to = self.global_position 
	
	#The direction to move the jump_to position if the player is near a ledge, ensuring
	#that Brickmin won't accidentally fall off a ledge when jumping to the player.
	var safe_direction: Vector3 = Vector3.ZERO
	
	var ledge_norm: Vector3 = Vector3.ZERO #Variable that stores checked ledge normals.
	
	#Gets the bottom of the player model (with a 0.1 extension).
	var bottom: Vector3 = Vector3(0.0, ((self.get_child(1).mesh.height) + 0.1), 0.0)
	
	var end: Vector3 = self.global_position - bottom #Position for where the raycast will end.
	
	for i in range(0, 360, 30): #Iterates from 0 to 360 degrees by 30 (12 angles for simplicity).
		var curr_angle = deg_to_rad(i) #Convert the current angle to radians.
		
		#Convert the angle to directions on the x-axis and z-axis.
		#cos(curr_angle) is for the x-axis, and sin(curr_angle) is for the z-axis.
		#Flatten the y-axis since we don't wanna mess with that.
		var curr_direction = Vector3(cos(curr_angle), 0.0, sin(curr_angle))
		
		#Start of the raycast. Positioned at the bottom of the player, in the direction of...
		#the current direction. For each direction, it's just arrow that starts just under...
		#the player but in the direction of the current direction, pointing towards the...
		#bottom-middle of the player (idk how good I'm explaining ts lol).
		var start = self.global_position + (curr_direction.normalized() * 3) - bottom
		
		var nearledge = PhysicsRayQueryParameters3D.create(start, end, 1) #Actual raycast.
		nearledge.exclude = [self.get_rid()] #Exclude player, only check the world.
		var nearledge_result = space_state.intersect_ray(nearledge) #Anything hit?
		
		if nearledge_result: #Found a ledge.
			if nearledge_result["normal"].y < 0.5: #If ledge normal's y is steeper than 0.5...
				if nearledge_result["normal"] != ledge_norm: #And this is a new ledge normal...
					#Add this new ledge normal to the ledge_norm variable
					#Adding allows for smoothing between detected angles.
					ledge_norm += nearledge_result["normal"] 
		
		else: #No ledge found.
			ledge_norm = Vector3.ZERO #No more ledge normal.
		
		if ledge_norm: #We have logged ledges.
			#Subtract the safe direction to the normalized ledge normal.
			#Makes the safe direction point away from any nearby ledges, as we do not want
			#Brickmin jumping off ledges.
			safe_direction -= (ledge_norm.normalized())
			
			#Flattening y-axis just to be safe because we really have no need for it.
			safe_direction.y = 0 
	
	#Lower the jump_to to the bottom of the player, and include the safe direction vector.
	#Bottom is required because jump_to is used as a raycast end position in the Brickmin
	#manager, and the end position needs to be touching ground in order for the Brickmin
	#to do a jump.
	jump_to = jump_to - bottom + (safe_direction.normalized() * 5)
	#endregion
	
	testmesh.global_position = jump_to #Debug thing for visualizing jump_to.
	
	move_and_slide() #Need this at end to actually move.
