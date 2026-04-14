extends Node
## 4/12/26
## This script handles things relating to interacting with the squad,
## such as throwing and disbanding. 
## NOTE: Swarming is already handled in the input manager, as it's just
## a boolean lol.

#region Variables

#Obvious stuff.
@onready var player_body = self.get_parent().get_node(^"Body&Camera").get_node(^"CharacterBody3D").global_position
@onready var input_handler = $"../InputHandler" 

var all_min: Array = BrickminManager.total_min #Every Brickmin on the field.

#The squad array. Is automatically filled with whatever Brickmin have a leader
#with a name that matches the player's.
var squad: Array = []

#Where the start, middle, and end variables are gotten for entering throw state.
var cursor_line:Node3D

var delta_global: float = 0.0

#endregion

func  _ready() -> void:
	## Set up the custom signals connections.
	
	input_handler.player_disbanded.connect(_disband)
	input_handler.player_throw.connect(_throw)
	#BrickminManager.total_min_update.connect(_check_all_min)

func _disband() -> void:
	## Clear out the player's Brickmin squad.
	
	#For as long as you have Brickmin...
	while squad.size() > 0:
		
		#Count down to avoid index shift bug (start at amount of 
		#Brickmin, go down by 1, and stop before hitting -1).
		for i in range(squad.size() - 1, -1, -1):
			
			#Decrease the current Brickmin's reaction time a bit.
			squad[i].reaction_time -= 0.1
			
			#If the Brickmin's reaction time is up...
			if squad[i].reaction_time <= 0:
				
				#If the current Brickmin isn't mid-gap jump, then set 
				#their state to idle.
				if not squad[i].state is GapJumpState:
					squad[i].state = load("res://brickmin/brickmin_states/idle_state.tres")
				
				#Remove the Brickmin's leader.
				squad[i].leader = null
				
				#Remove the current Brickmin from the squad.
				squad.remove_at(i)
		
		#Don't let the game try to do this all in one frame.
		#Prevents the game from lagging.
		await get_tree().process_frame

func _throw() -> void:
	##Throw a Brickmin.
	
	#Get the cursor line node, which has the start, middle, and end
	#variables we need to make our throw bezier curve.
	cursor_line = self.get_parent().get_node(^"Cursor").get_node(^"CursorLine")
	
	#If you have Brickmin in your squad...
	if squad.size() > 0: 
		var current = squad.pop_front() #get whatever one's up next,
		current.leader = null #remove their leader,
		
		#set their state to the throw state,
		current.state = load("res://brickmin/brickmin_states/throw_state.tres")
		current.t = 0.0 #reset their bezier curve time,
		current.start = cursor_line.start #assign their start,
		current.mid = cursor_line.middle #middle,
		current.end = cursor_line.end #and end.

#func _check_all_min() -> void:
func _process(_delta: float) -> void:
	## Check all Brickmin present on the field.
	
	#For all the Brickmin...
	for i in (all_min):
		
		#if the current Brickmin has a leader, but the player's 
		#squad doesn't have them, then...
		if i.leader and not squad.has(i):
			
			#if the Brickmin leader name matches the player's
			#name, then...
			if i.leader.name == $"..".name:
				squad.append(i) #add the Brickmin to the squad.
