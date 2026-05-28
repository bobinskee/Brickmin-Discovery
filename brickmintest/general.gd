extends Node

var gravity: float = 50.0
var jump_power_mult: float = 5.0

var throw_start
var throw_control
var throw_end

#var idle_state = preload("res://brickmin/brickmin_states/idle_state.gd").new()
#var follow_state = preload("res://brickmin/brickmin_states/follow_state.gd").new()
#var airborne_state = preload("res://brickmin/brickmin_states/airborne_state.gd").new()

func _set_mask(layer: int) -> int:
	return 1 << (layer - 1)

## Return the highest number of value 1 and value 2. Set the third argument to true
## to inversely return the smallest number out of the two values.
func _get_highest(val1: float, val2: float, invert: bool) -> float:
	
	var final = (val1 + val2 + abs(val1 - val2))/2
	
	if invert:
		final = (val1 + val2 - abs(val1 - val2))/2
	
	return final
