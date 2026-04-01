extends CharacterBody3D

@onready var gimbal: SpringArm3D = $PlayerCamera/SpringArm3D
@onready var testmesh = $"../../MeshInstance3D"

@export var speed: float = 15.0
@export var acceleration: float = 300.0
@export var jump_power: float = 4.0
@export var jump_buffer_timing: float = 0.4

var y_velocity: float = 0.0
var jump_buffer: float = 0.0

var jumping: bool = false
var jump_initiated: bool = false
var can_jump: bool = false
var swarming: bool = false
var new_jump_pos: Vector3 = Vector3.ZERO
var should_jump: bool = false
var shrink_offset: bool = false

var last_dir: Vector3 = Vector3.ZERO

var input_direction: Vector2 = Vector2(0.0, 0.0)
var player_direction: Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready() -> void:
	
	jump_buffer = jump_buffer_timing
	last_dir = self.global_transform.basis.z
	
func _input(_event: InputEvent) -> void:
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_just_pressed("jump"):
		jumping = true
		
	if Input.is_action_pressed("swarm"):
		swarming = true
	else:
		swarming = false
	
func _physics_process(delta: float) -> void:
	var space_state = get_viewport().find_world_3d().direct_space_state
	
	var forward = gimbal.global_basis.z
	var right = gimbal.global_basis.x
	
	forward.y = 0.0
	right.y = 0.0
	
	forward = forward.normalized()
	right = right.normalized()
	
	player_direction = (right * input_direction.x) + (forward * input_direction.y)
	player_direction.y = 0.0
	player_direction = player_direction.normalized()
	
	y_velocity = self.velocity.y
	
	self.velocity = velocity.move_toward((player_direction * speed), (delta * acceleration))
	self.velocity.y = y_velocity - (delta * General.gravity)
	
	if not is_on_floor():
		jump_buffer -= delta * 2
	else:
		jump_buffer = jump_buffer_timing
	
	if jump_buffer > 0.0:
		can_jump = true
	else:
		can_jump = false
	
	if can_jump and jumping:
		if is_on_floor():
			self.velocity.y += (jump_power * General.jump_power_mult)
	
	jumping = false
	
	var move_forward = player_direction.normalized()
	var bottom = Vector3(0.0, (self.get_child(1).mesh.height/2 * 2) + 0.1, 0.0)
	
	if abs(player_direction.x) > 0 or abs(player_direction.z) > 0:
		last_dir = Vector3(move_forward.x, 0.0, move_forward.z)
	
	new_jump_pos = self.global_position
	
	var end = self.global_position - bottom
	
	var underplayer = PhysicsRayQueryParameters3D.create(global_position, end, 1)
	underplayer.exclude = [self.get_rid()]
	var underplayer_result = space_state.intersect_ray(underplayer)
	
	should_jump = false
	
	for i in range(0, 360, 30):
		var cur_angle = deg_to_rad(i)
		var cur_dir = Vector3(cos(cur_angle), 0.0, sin(cur_angle))
		var start = self.global_position + (cur_dir * 3) - bottom
		
		var nearledge = PhysicsRayQueryParameters3D.create(start, end, 1)
		nearledge.exclude = [self.get_rid()]
		var nearledge_result = space_state.intersect_ray(nearledge)
		
		if nearledge_result:
			shrink_offset = true
			
			if nearledge_result["normal"].y < 0.5:
				new_jump_pos -= (nearledge_result["normal"].normalized() * 2) 
	
	new_jump_pos = new_jump_pos - bottom
	
	#testmesh.global_position = new_jump_pos
	
	if underplayer_result:
		should_jump = true
	
	move_and_slide()
	
	
