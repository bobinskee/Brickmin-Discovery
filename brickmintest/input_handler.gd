extends Node
## Consolidates all player inputs into one place (organization, hooray!!!)
## and is used across other scripts in the player.
## NOTE: "external" means that variable is shipped out to other scripts.

#2D directional input (left, right, up, down).
var input_direction: Vector2 = Vector2(0.0, 0.0) #external

#2D position of the mouse on screen.
var mouse_position: Vector2 = Vector2(0.0, 0.0) #external

#Specific self-explanatory player action booleans.
var player_jump: bool = false #external
var player_swarming: bool = false #external
var player_aiming: bool = false #external
var holding_RMB: bool = false

#Signals for throwing and disbanding.
signal player_throw #external
signal player_disbanded #external

func _input(event: InputEvent) -> void:
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
	
	if event.is_action_released("throw"):
		player_throw.emit()
	
	if Input.is_action_just_pressed("disband"):
		player_disbanded.emit()
		
	#endregion
	
	#region Mouse inputs.
	## Also pretty self-explanatory.
	
	#If RMB is not being held, the mouse can move around the screen.
	#Otherwise, it remains in place while the camera shifts.
	if event is InputEventMouseMotion and not holding_RMB:
		mouse_position = event.position
	
	#Inputs for the mouse buttons. Very straight-forward.
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				holding_RMB = true
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				player_aiming = true
		
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				holding_RMB = false
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				player_aiming = false
		
	#endregion
	
