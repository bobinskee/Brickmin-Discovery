extends SpringArm3D

@export var sensitivity = 0.075
@export var smooth_camera: bool = true

var rot_speed_x: float = 0.1
var rot_speed_y: float = 0.1
var rotation_x: float = 0.0
var rotation_y: float = 0.0
var direction_x: float = 0.0
var direction_y: float = 0.0
var max_length: float  = 30.0
var zoom_amt: float = 2.0
var length: float  = self.spring_length

var mouse_lastpos

func _ready() -> void:
	
	rotation_x = self.rotation.x
	rotation_y = self.rotation.y
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_lastpos = get_viewport().get_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and length < max_length:
			length += zoom_amt
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and length > 1:
			length -= zoom_amt
		
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		direction_y = event.screen_relative.x * sensitivity
		direction_x = event.screen_relative.y * sensitivity
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if not mouse_lastpos:
				mouse_lastpos = Vector2.ZERO
			else:
				Input.warp_mouse(mouse_lastpos)
			
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_lastpos = null

func _process(_delta: float) -> void:
	
	rotation_y -= (direction_y * sensitivity)
	
	rotation_x -= (direction_x * sensitivity)
	rotation_x = clamp(rotation_x, -PI/2, 0.0)
	
	length = clamp(length, 1, max_length)
	
	if smooth_camera:
		self.rotation = self.rotation.lerp(Vector3(rotation_x, rotation_y, self.rotation.z), 0.25)
		self.spring_length = lerp(self.spring_length, length, 0.25)
		
	else:
		self.rotation = Vector3(rotation_x, rotation_y, self.rotation.z)
		self.spring_length = length
		
	direction_y = 0
	direction_x = 0
