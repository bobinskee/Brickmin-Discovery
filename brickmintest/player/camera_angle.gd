extends SpringArm3D

## This script controls the camera, or morely the camera gimbal,
## but the terms are used interchangeably. The camera can rotate and
## zoom in and out. It only ever moves in two axes. The vertical
## axis could be applied to either the self.rotation.x or 
## self.rotation.z, it has the exact same effect.
## NOTE: This scripts inputs are fully handled by input_handler.gd.
## I found it more convenient to just load this script in the
## input handler as opposed to loading input handler here.

#region Variables

@export var sensitivity: float = 0.0075 #Camera sensitivity.
@export var max_length: float  = 30.0 #How far the camera can go from the player.
@export var zoom_amt: float = 2.0 #How much the camera zooms each scroll.
@export var smooth_camera: bool = true #Camera smoothing.
@export var invert_horiz: bool = true #Invert camera horizontally.
@export var invert_vert: bool = true #Invert camera vertically.

#The current length of the camera gimbal.
var length: float = self.spring_length

#The direction the mouse is moving in on the screen.
#Is a Vector2 since I just needed to store 2 numbers in one.
var mouse_dir: Vector2 = Vector2.ZERO 

#The amount to move the camera gimbal in.
var rotation_xy: Vector2 = Vector2.ZERO

#endregion

func _process(_delta: float) -> void:
	## Determining where to move and angle the camera.
	
	#Make sure the camera goes farther than the set length.
	length = clamp(length, 1, max_length)
	
	#Multiply the mouse direction by the sensitivity squared and
	#then add it to the rotation_xy.
	rotation_xy -= mouse_dir * (sensitivity * sensitivity)
	
	#Clamp the vertical rotations so loops cannot be done around the
	#player body.
	#Camera's vertical rotation can go between 0 (like, to the ground
	#but not in it) and half of negative PI (exactly above the player
	#body). If you're not getting it, look up a unit circle ig.
	rotation_xy.y = clamp(rotation_xy.y, -PI/2, 0.0)
	
	#If the smooth camera is enabled, the camera angle and length just
	#lerps to the new angle and length.
	if smooth_camera:
		self.rotation = self.rotation.lerp(Vector3(rotation_xy.y, rotation_xy.x, self.rotation.z), 0.25)
		self.spring_length = lerp(self.spring_length, length, 0.25)
	
	#Otherwise, don't do any of that.
	else:
		self.rotation = Vector3(rotation_xy.y, rotation_xy.x, self.rotation.z)
		self.spring_length = length
	
	#Reset the mouse direction afterwards so the camera doesn't spin after
	#it is finished being moved.
	mouse_dir = Vector2.ZERO
