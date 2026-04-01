extends Node3D

@onready var pointer = $Pointer
@onready var camera = $"../Body/CharacterBody3D/PlayerCamera/SpringArm3D/Camera3D"
@onready var player_body = $"../Body/CharacterBody3D"
@onready var land_vis = $LandVis
@onready var decal = $LandVis/CursorDecal
@onready var player = $".."

var squad: Array = []

var all_min: Array = BrickminManager.total_min

var max_range: float = 20.0
var hit_distance: float = 0.0
var decal_rotspeed: float = 2.0

var cursor_too_far: bool = false
var holding_RMB: bool = false

var mouse_pos:Vector2 = Vector2(0.0, 0.0)
var mouse_pos_cur:Vector2 = Vector2(0.0, 0.0)
var pointer_down_init: Vector3 = Vector3(0.0, -50.0, 0.0)
var hit_pos:Vector3 = Vector3(0.0, 0.0, 0.0)

var distance
var old_position
var cur_raypos

var where_pointer = Vector3.ZERO

func _ready() -> void:
	
	pointer.global_position = Vector3(0.0, 0.0, 0.0)
	old_position = pointer.global_position
	hit_pos = Vector3(0.0, 0.0, 0.0)
	hit_distance = 0.0
	cur_raypos = Vector3(0.0, 0.0, 0.0)
	
func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		mouse_pos = (event.position)
		
	if not holding_RMB:
		mouse_pos_cur = mouse_pos
	else:
		mouse_pos_cur = mouse_pos_cur
	
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			holding_RMB = true
			
	
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_RIGHT:
			holding_RMB = false
		
	if Input.is_action_pressed("pressed_1"):
		BrickminManager._spawn_min(player, pointer.global_position, get_tree().current_scene)
	
	if Input.is_action_just_pressed("disband"):
		for i in range(squad.size()):
			squad[i].leader = null
			squad[i].state = load("res://brickmin/brickmin_states/idle_state.tres")
			
			if i == squad.size() - 1:
				squad.clear()
				
	if event.is_action_released("throw"):
		
		if squad.size() > 0: 
			var current = squad.pop_front()
			current.leader = null
			current.t = 0.0
			current.start = get_node("CursorLine").start
			current.end = get_node("CursorLine").end
			current.mid = get_node("CursorLine").midway
			current.state = load("res://brickmin/brickmin_states/throw_state.tres")
			current.global_position = player_body.global_position
	
func _process(_delta: float) -> void:
	
	for i in (all_min):
		if i.leader and not squad.has(i):
			var actual_player = (i.leader.get_parent().get_parent().name)
			if actual_player == $"..".name:
				squad.append(i)
	
	pointer = $Pointer
	camera = $"../Body/CharacterBody3D/PlayerCamera/SpringArm3D/Camera3D"
	player_body = $"../Body/CharacterBody3D"
	decal = $LandVis/CursorDecal
	
	var cam_player_dist = camera.global_position.distance_to(player_body.global_position)
	var current_pointer_down = pointer_down_init
	
	var space_state = get_world_3d().direct_space_state
	
	var start_baseray = camera.project_ray_origin(mouse_pos_cur)
	var end_baseray = start_baseray + camera.project_ray_normal(mouse_pos_cur) * (max_range + cam_player_dist)
	
	var rayquery_baseray = PhysicsRayQueryParameters3D.create(start_baseray, end_baseray, 1)
	rayquery_baseray.collide_with_bodies = true
	rayquery_baseray.exclude = [player_body.get_rid()]
	
	var rayhit_baseray = space_state.intersect_ray(rayquery_baseray)
	
	var rayquery_pointer = PhysicsRayQueryParameters3D.create(pointer.position, pointer.position + current_pointer_down, 1)
	rayquery_pointer.collide_with_bodies = true
	rayquery_pointer.exclude = [player_body.get_rid()]
	
	var rayhit_pointer = space_state.intersect_ray(rayquery_pointer)
	
	var pp_direction = (pointer.global_position - player_body.global_position).normalized()
	var end_playerpointer = player_body.global_position + (pp_direction * max_range)
	
	var rayquery_playerpointer = PhysicsRayQueryParameters3D.create(player_body.global_position, end_playerpointer, 1)
	rayquery_playerpointer.collide_with_bodies = true
	rayquery_playerpointer.exclude = [player_body.get_rid()]
	
	var rayhit_playerpointer = space_state.intersect_ray(rayquery_playerpointer)
	
	if rayhit_baseray:
		distance = player_body.global_position.distance_to(rayhit_baseray["position"])
		cur_raypos = (rayhit_baseray["position"])
		
	else:
		distance = player_body.global_position.distance_to(end_baseray)
		cur_raypos = end_baseray
	
	if distance > max_range:
		cursor_too_far = true
	else:
		cursor_too_far = false
	
	if rayhit_baseray and not cursor_too_far:
		pointer.global_position = (rayhit_baseray["position"])
		
	elif not rayhit_baseray and not cursor_too_far:
		pointer.global_position = end_baseray

	elif cursor_too_far:
		pointer.global_position = (player_body.global_position.direction_to(cur_raypos) * max_range + player_body.global_position)
	
	if rayhit_playerpointer:
		land_vis.rotation.x = rayhit_playerpointer["normal"].z * 90.0
		land_vis.rotation.z = rayhit_playerpointer["normal"].x * 90.0
		land_vis.global_position = rayhit_playerpointer["position"]
	
	elif rayhit_pointer and not rayhit_playerpointer:
		land_vis.global_position = rayhit_pointer["position"]
		land_vis.rotation = Vector3.ZERO
	
	else:
		land_vis.global_position = pointer.global_position
	
	if General.aiming:
		decal_rotspeed = 0.05
	else:
		decal_rotspeed = 0.02
	
	decal.rotation.y += decal_rotspeed
	
	var pointerdown = PhysicsRayQueryParameters3D.create(pointer.global_position, pointer.global_position + (Vector3.DOWN * 50), 1)
	
	var pointerdown_result = space_state.intersect_ray(pointerdown)
	
	if pointerdown_result:
		where_pointer = pointerdown_result["position"]
