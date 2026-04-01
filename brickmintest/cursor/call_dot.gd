extends Node3D

@onready var player = $"../../.."
@onready var pointer = $".."
@onready var calldot_mesh = $CallDotMesh

var cur_radius: float = 0.01
var max_radius:float = 10.0

var calling: bool = false

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F):
		calling = true
		
	else: 
		calling = false
		
func _physics_process(delta: float) -> void:
	
	if calling:
		
		cur_radius = move_toward(cur_radius, max_radius/pointer.scale.x, delta * 20)
		
		var hitbubble_shape = SphereShape3D.new()
		hitbubble_shape.radius = cur_radius/2
		
		var call_hitbubble = PhysicsShapeQueryParameters3D.new()
		call_hitbubble.shape = hitbubble_shape
		call_hitbubble.transform = pointer.transform
		call_hitbubble.collision_mask = 4 #idk why this corresponds to layer 3 but whatever
		
		var any_called = get_world_3d().direct_space_state.intersect_shape(call_hitbubble)
		
		for i in any_called:
			var who_was_called = i["collider"]
			if who_was_called.is_in_group("brickmin"):
				who_was_called.leader = $"../../../Body/CharacterBody3D"
				who_was_called.state = load("res://brickmin/brickmin_states/follow_state.tres")
				who_was_called.t = 0.0
				who_was_called.being_called = true
		
	else:
		cur_radius = 0.01
		
func _process(_delta: float) -> void:
	pass
	calldot_mesh.scale = Vector3.ONE * cur_radius
