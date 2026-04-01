extends Node

var aiming: bool = false

var gravity: float = 50.0
var jump_power_mult: float = 5.0

var throw_start
var throw_control
var throw_end

func _bezcurve(time: float, start: Vector3, control: Vector3, end: Vector3) -> Vector3:
	
	var l0 = start + (time * (control - start))
	var l1 = control + (time * (end - control))
	
	return l0 + (time * (l1 - l0))
