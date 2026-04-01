extends Camera3D

var max_rot_speed = 0.08

var y_rotation = 0
var y_mouse_direction = 0
var smooth_camera = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	y_rotation = self.rotation.y
	
func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		y_mouse_direction = clamp(event.screen_relative.x, -max_rot_speed, max_rot_speed)
		
func _process(_delta: float) -> void:
	pass
	
