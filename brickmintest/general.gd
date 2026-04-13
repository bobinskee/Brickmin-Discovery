extends Node

var gravity: float = 50.0
var jump_power_mult: float = 5.0

var throw_start
var throw_control
var throw_end

func _bezcurve(time: float, start: Vector3, middle: Vector3, end: Vector3) -> Vector3:
	
	var l0 = start + (time * (middle - start))
	var l1 = middle + (time * (end - middle))
	
	return l0 + (time * (l1 - l0))
