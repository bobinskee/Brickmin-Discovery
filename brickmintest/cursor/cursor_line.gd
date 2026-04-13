extends Node3D
## 4/12/26

#region Variables

@onready var input_handler = $"../../InputHandler" #Needed for input.

@export var points_amt: int = 10 #How many points make up the line.
@export var points_size: float = 0.15 #How big the line points are.

#Array that holds all the points after they are loaded.
var points_array: Array = [] 

#The amount that each point moves on the calculated line or arch.
var t: float = 0.0 

#When aiming, this is how high the arch will go from the player
#before it becomes less of an arch and more like half of a
#parabola (it's kind of hard to explain).
var aiming_height:float = 10.0

#How much to rebound the throw curve upwards if the player is aiming at a
#spot lower than where they are.
var downthrow_rebound:float = 5.0 

#Initialize the start, middle, and end positions. This also makes
#them public variables, which is important as the squad_handler
#requires these variables for throwing Brickmin.
var start: Vector3 = Vector3.ZERO
var middle: Vector3 = Vector3.ZERO
var end: Vector3 = Vector3.ZERO

#endregion

func _ready() -> void:
	## Create the needed amount of dot meshes for the cursor line.
	
	#For the amount of points determined for the cursor line...
	for i in points_amt:
		
		var point = MeshInstance3D.new() #Create a new mesh.
		add_child(point) #Add the new mesh to the scene tree.
		
		point.mesh = SphereMesh.new() #Make the mesh a sphere.
		
		#Set the mesh size to whatever it was set at.
		point.scale = Vector3(points_size, points_size, points_size) 
		
		#Make the landing visual decal not project onto the meshes.
		#The landing visual decal ignores layer mask 2, so
		#remove the mesh from layer mask 1 (the default) and
		#add it to layer mask 2.
		point.set_layer_mask_value(1, false)
		point.set_layer_mask_value(2, true)
		
		#Create a new unshaded material that the point will use, then
		#set the points material to it.
		var new_material = StandardMaterial3D.new()
		new_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		point.set_surface_override_material(0, new_material)
		
		#Add the point to the points_array.
		points_array.append(point)

func _process(_delta: float) -> void:
	## https://www.desmos.com/calculator/uyarq4tlce
	
	#Set the start and end positions (each frame) to the positions
	#of the player body and pointer respectively.
	start = $"../../Body/CharacterBody3D".global_position
	end = $"../Pointer".position
	
	#Set the middle position.
	#Goes half of the distance between the start and end positions.
	#Start is added so the middle always follows the player.
	middle = start + ((end - start)/2)
	
	#Get the distance in the y-positions of the start and end.
	var distance_y = abs(start.y - end.y)
	
	#Set the offsets for aiming and for the downthrow rebound.
	var aim_offset = aiming_height
	var rebound_offset = downthrow_rebound
	
	#The middle of the start and end's y-positions.
	var middle_y = (start.y + end.y)/2
	
	#If the player is aiming...
	if input_handler.player_aiming:
		#Increase the timer to cause the points to move in the.
		#direction being aimed at.
		#Decreasing would make the points run backwards, from
		#the pointer to the player.
		t += 0.01 
		
		#Set the middle_y to either the start or end's y-position,
		#depending on what's higher.
		#How it works:
		#1. Add up the start and end. For the example, start = 2
		#   and end = 5. So, that makes 7.
		#2. Get the distance between the start and end, and add
		#   it. (2 + 5) + abs(2 - 5) -> 7 + 3 -> 10.
		#3. Halve the result. 10/2 = 5. So, our end is the higher
		#   position.
		middle_y = (start.y + end.y + distance_y)/2
	
	#Player is idle, not aiming, so...
	else:
		#Cancel both height offsets so the line from the player to
		#the pointer is perfectly straight.
		aim_offset = 0
		rebound_offset = 0
		
		#Zero the time (not required but eh).
		t = 0
	
	#The final downthrow offset, which goes from the start to the 
	#end (order matters, since this is only supposed to apply if
	#the start is higher than the end) and clamps it between 0 and
	#the curren repbound offset (either 0 or whatever it was initially
	#set to).
	var downthrow_offset = clamp((start.y - end.y), 0, rebound_offset)
	
	#The final offset for the line or arch that the points will travel 
	#along. Adds the aim offset and downthrow offset. Then, clamps the
	#distance_y between 0 and the current aim offset, and then
	#subtracts that from the sum of the aim and downthrow offsets.
	var final_offset = (aim_offset + downthrow_offset) - clamp(distance_y, 0, aim_offset)
	
	#Sets the middle y-position to the previously set middle_y, along
	#with the final offset in case the player is aiming, and whether
	#they're aiming down to a lower spot or not.
	middle.y = middle_y + final_offset
	
	#If the time is greater than 1 divided by the amount of points...
	#1 is divided by the point count to make a seamless moving arch
	#of points. Depending on how many points there are, when the
	#time is equal to 1 divided by the amount, the points will all be
	#at where the one in front of them just was.
	#NOTE: Uses the absolute value of t to allow the points to move 
	#both backwards and forwards between the player and pointer.
	if abs(t) >= 1.0/float(points_array.size()):
		#Reset the timer to move all the points back to their initial
		#positions.
		t = 0.0 
	
	#For all the points...
	for i in range(points_array.size()):
		#Get the inital timing by dividing the index of the current
		#point by the total array size.
		#For instance, the point with an index of 4, in an array 
		#of 10, would having an initial timing of 0.4 (4/10).
		var init_timing = float(i)/float(points_array.size())
		
		#Add the value of t to the initial time.
		var new_timing = init_timing + t
		
		#Use the bezier curve function in the General script, 
		#using the new timing, start, middle, and end as arguments,
		#to find where the current point should be placed.
		var placement = General._bezcurve(new_timing, start, middle, end)
		
		#Set the current points position to the placement along the
		#path.
		points_array[i].global_position = placement
