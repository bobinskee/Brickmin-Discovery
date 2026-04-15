extends Node
## 4/12/26
## Consolidates all player inputs into one place (organization, hooray!!!)
## and is used across other scripts in the player.
## NOTE: "external" means that variable or signal is shipped out to other 
## scripts.
## NOTE: camera_angle.gd is fully controlled here.

#region Variables

@onready var camera = $"../Body&Camera/CharacterBody3D/PlayerCamera/SpringArm3D"

#2D directional input (left, right, up, down).
var input_direction: Vector2 = Vector2.ZERO #external

#2D position of the mouse on screen.
var mouse_position: Vector2 = Vector2.ZERO #external

#Where the mouse will snap back to after the camera is finished being shifted.
var snap_to: Vector2 = Vector2.ZERO

#Specific self-explanatory player action booleans.
var player_jump: bool = false #external
var player_calling: bool = false #external
var player_swarming: bool = false #external
var player_aiming: bool = false #external
var holding_RMB: bool = false

#Signals for throwing and disbanding.
signal player_throw #external
signal player_disbanded #external

#endregion

func _unhandled_input(event: InputEvent) -> void:
	## Where the actual inputs are logged.
	
	#region Buttons and keys.
	## Pretty self-explanatory.
	
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down") 
	
	if Input.is_action_just_pressed("jump"):
		player_jump = true
		
	if Input.is_action_pressed("swarm"):
		player_swarming = true
	else:
		player_swarming = false
	
	if Input.is_key_pressed(KEY_F):
		player_calling = true
	else:
		player_calling = false
	
	if event.is_action_released("throw"):
		player_throw.emit()
	
	if Input.is_action_just_pressed("disband"):
		player_disbanded.emit()
		
	#endregion
	
	#region Mouse inputs.
	## Also pretty self-explanatory.
	
	#If RMB is not being held, the mouse can move around the screen.
	#Otherwise, it remains in place while the camera shifts.
	if event is InputEventMouseMotion:
		if not holding_RMB:
			mouse_position = event.position
		
		#Everything within this if-statement pertains to the
		#camera_angle.gd script.
		#If RMB is being held down...
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			
			#Horizontal mouse movements get logged in the x of
			#mouse_dir.
			camera.mouse_dir.x = event.screen_relative.x
			
			#Vertical mouse movements get logged in the y of
			#mouse_dir.
			camera.mouse_dir.y = event.screen_relative.y
			
			#If you don't want the camera controls inverted 
			#horizontally...
			if not camera.invert_horiz:
				camera.mouse_dir.x = -camera.mouse_dir.y
			
			#If you don't want the camera controls inverted
			#vertically...
			if not camera.invert_vert:
				camera.mouse_dir.y = -camera.mouse_dir.x
			
			#Hide the mouse to indicate you're shifting the camera.
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
	#If a mouse button is...
	if event is InputEventMouseButton:
		
		#being pressed, then...
		if event.is_pressed():
			
			#If its RMB, set holding RMB to true...
			if event.button_index == MOUSE_BUTTON_RIGHT:
				holding_RMB = true
				
				#And make the position the mouse will snap back to
				#once RMB is released be the position where the mouse
				#was when it was pressed.
				snap_to = get_viewport().get_mouse_position()
			
			#If its LMB, the player is aiming.
			if event.button_index == MOUSE_BUTTON_LEFT:
				player_aiming = true
			
			#If the scroll wheel is scrolled down,
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				
				#zoom the camera out.
				camera.length += camera.zoom_amt
			
			#Otherwise, if the scroll wheel is scrolled down,
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				
				#zoom the camera in.
				camera.length -= camera.zoom_amt
			
			#(The camera's length is clamped in camera_angle.gd,
			#so there's no need to worry about it here).
		
		#released, then...
		if event.is_released():
			
			#If it was RMB, RMB is no longer being held...
			if event.button_index == MOUSE_BUTTON_RIGHT:
				holding_RMB = false
				
				#and if there was not a logged snap_to position,
				#just default the mouse to the top-left corner of
				#the screen (which is (0,0)).
				if not snap_to:
					snap_to = Vector2.ZERO
				
				#otherwise, there was a logged snap_to position,
				#so snap the mouse to it.
				else:
					Input.warp_mouse(snap_to)
				
				#Make the mouse visible again.
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
			#If it was LMB, the player is no longer aiming.
			if event.button_index == MOUSE_BUTTON_LEFT:
				player_aiming = false
		
	#endregion
	
