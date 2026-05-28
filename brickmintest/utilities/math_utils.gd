extends RefCounted
class_name MathUtils

static func bezier_curve(time: float, start: Vector3, middle: Vector3, end: Vector3) -> Vector3:
	
	var l0 = start + (time * (middle - start))
	var l1 = middle + (time * (end - middle))
	
	return l0 + (time * (l1 - l0))
	
	#A more long-winded of calculating this...
	#return (((1 - time) * (1 - time)) * start) + ((2 * (1 - time)) * time * middle) + ((time * time) * end)
