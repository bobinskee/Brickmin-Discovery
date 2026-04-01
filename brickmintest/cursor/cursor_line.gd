extends Node3D

@export var points_amt: int = 10

var t: float = 0.0
var control_height:float = 10.0
var downthrow_rebound:float = 2.0

var start: Vector3 = Vector3.ZERO
var end: Vector3 = Vector3.ZERO
var control: Vector3 = Vector3.ZERO
var newpos: Vector3 = Vector3.ZERO

var midway

var points_array = []

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			General.aiming = true
	
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_LEFT:
			General.aiming = false

func _ready() -> void:
	start = $"../../Body/CharacterBody3D".position
	end = $"../Pointer".position
	control = start + (end - start)/2
	
	for i in points_amt:
		var point = MeshInstance3D.new()
		add_child(point)
		
		point.mesh = SphereMesh.new()
		
		point.scale = Vector3(0.1, 0.1, 0.1)
		point.position = start
		point.name = str(i)
		point.set_layer_mask_value(1, false)
		point.set_layer_mask_value(2, true)
		var new_mesh = StandardMaterial3D.new()
		new_mesh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		point.set_surface_override_material(0, new_mesh)
		
		point.visible = true
		points_array.append(point)

func _process(_delta: float) -> void:
	
	start = $"../../Body/CharacterBody3D".global_position
	end = $"../Pointer".position
	control = start + (end - start)/2
	
	var distance_y = (end.y - start.y)
	
	var current_height = control_height
	var current_rebound = downthrow_rebound
	var _current_control = control
	var base_position = (start.y + end.y)/2
	
	if General.aiming:
		t += 0.01
		current_height = control_height
		current_rebound = downthrow_rebound
		_current_control = control
		base_position = (start.y + end.y + abs(distance_y))/2
		
	else:
		current_height = 0
		current_rebound = 0
		_current_control = (start.y + end.y)/2
		base_position = (start.y + end.y)/2
	
	var downthrow_offset = clamp((start.y - end.y), 0, current_rebound)
	var final_offset = current_height - clamp(abs(distance_y), 0, current_height) + downthrow_offset
	
	control.y = final_offset + base_position
	
	var base_position_2 = (start.y + end.y + abs(distance_y))/2
	var downthrow_offset_2 = clamp((start.y - end.y), 0, downthrow_rebound)
	var final_offset_2 = control_height - clamp(abs(distance_y), 0, control_height) + downthrow_offset_2
	
	midway = start + (end - start)/2
	midway.y = final_offset_2 + base_position_2
	
	if t >= 1.0/float(points_array.size()):
		t = 0.0
	
	for i in range(points_array.size()):
		var current_point = points_array[i]
		var init_timing = float(i)/float(points_array.size())
		var new_timing = init_timing + t
		var placement = General._bezcurve(new_timing, start, control, end)
		current_point.global_position = placement
	
	General.throw_start = start
	General.throw_end = end
	General.throw_control = control
