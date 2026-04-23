extends Node
## 4/12/26
## This script handles things relating to interacting with the squad,
## such as throwing and disbanding. 
## NOTE: Swarming is already handled in the input manager, as it's just
## a boolean lol.
## NOTE: Whistling is handled by cursor.gd. I feel like it made more
## sense to just keep it there.

#region Variables

#Obvious stuff.
@onready var player_body = %CharacterBody3D
@onready var input_handler = $"../InputHandler" 
@onready var cursor_line = $"../Cursor/CursorLine"

var all_min: Array = BrickminManager.total_min #Every Brickmin on the field.

#The squad array. Is automatically filled with whatever Brickmin have a leader
#with a name that matches the player's.
var squad: Array = []

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
				if not squad[i].state == "airborne" and squad[i].is_on_floor():
					squad[i].state = "idle"
				
				#Remove the Brickmin's leader.
				squad[i].leader = null
				
				#Remove the current Brickmin from the squad.
				squad.remove_at(i)
		
		#Don't let the game try to do this all in one frame.
		#Prevents the game from lagging.
		await get_tree().process_frame

func _throw() -> void:
	##Throw a Brickmin.
	
	#If you have Brickmin in your squad...
	if squad.size() > 0: 
		var current = squad[squad.size() - 1] #get the last one in the squad,
		current.leader = null #remove their leader,
		squad.remove_at(squad.size() - 1) #remove them from the squad,
		
		#set their state to the throw state,
		current.state = "airborne"
		current.t = 0.0 #reset their bezier curve time,
		current.global_position = player_body.global_position
		current.velocity = Vector3.ZERO
		current.start = player_body.global_position #assign their start,
		current.mid = cursor_line.middle #middle,
		current.end = cursor_line.end #and end.
		current.thrown = true

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
