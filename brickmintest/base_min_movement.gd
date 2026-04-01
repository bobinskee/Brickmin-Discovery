extends CharacterBody3D

@onready var parent = self.get_parent()
@onready var nav_agent = $NavigationAgent3D
@export var acceleration: float = 300.0
@export var jump_power: float = 4.0

var y_velocity: float = 0.0
var move_speed: float = 15.0

var printed = false

var target_node

func _ready() -> void:
	
	y_velocity = self.velocity.y

func _set_target(target: Node3D):
	target_node = target

func _physics_process(delta: float) -> void:
	
	y_velocity = self.velocity.y
	
	self.velocity.y = y_velocity - (delta * General.gravity)
	
	if target_node:
		if abs(target_node.global_position.distance_squared_to(global_position)) > 50:
		
			nav_agent.set_target_position(target_node.global_position)
			var next_pos = nav_agent.get_next_path_position()
			var cur_pos = self.global_position
			var new_velo = (next_pos - cur_pos).normalized() 
		
			velocity = velocity.move_toward((new_velo * move_speed), (delta * acceleration))
	
	move_and_slide()
