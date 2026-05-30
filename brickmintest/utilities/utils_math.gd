extends RefCounted
class_name Utils_Math

static func bezier_curve(time: float, start: Vector3, middle: Vector3, end: Vector3) -> Vector3:
	
	var l0 = start + (time * (middle - start))
	var l1 = middle + (time * (end - middle))
	
	return l0 + (time * (l1 - l0))
	
	#A more long-winded of calculating this...
	#return (((1 - time) * (1 - time)) * start) + ((2 * (1 - time)) * time * middle) + ((time * time) * end)

#region : Physics and collision

static func _apply_gravity(delta: float, y_vel: float) -> float:
	
	var current_y = y_vel
	return current_y - (delta * Constants.gravity)

static func _check_collisions(object: Databody, motion: Vector3, origin: Vector3) -> PhysicsTestMotionResult3D:
	
	var col_params = PhysicsTestMotionParameters3D.new()
	col_params.from = Transform3D(object.transform_g.basis, origin)
	col_params.motion = motion
	col_params.margin = 0.01
	col_params.recovery_as_collision = true
	
	var col_results: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	
	if PhysicsServer3D.body_test_motion(object.body_RID, col_params, col_results):
		return col_results
	
	return null

static func _move_object(object: Databody, motion: Vector3, check_amt: int = 4) -> Vector3:
	
	var final_position: Vector3 = object.transform_g.origin
	
	var safe_margin: float = 0.001
	
	for i in range(check_amt):
		
		if motion.is_zero_approx():
			break
		
		var collision = _check_collisions(object, motion, final_position)
		
		if not collision:
			final_position += motion
			break
		
		var travel = collision.get_travel()
		
		if travel.length() > safe_margin:
			travel = travel.normalized() * (travel.length() - safe_margin)
		
		else:
			travel = Vector3.ZERO
		
		motion -= travel
		final_position += travel
		
		var col_norm: Vector3 = Vector3.ZERO
		
		for k in range(collision.get_collision_count()):
			col_norm += collision.get_collision_normal(k)
		
		motion = motion.slide(col_norm.normalized())
		object.velocity = object.velocity.slide(col_norm.normalized())
		
	return final_position

static func _update_position(object: Databody, delta: float):
	
	var velocity = object.velocity * delta
	
	object.transform_g.origin = _move_object(object, velocity)

#endregion : Physics and collision

#region : Lowlevel

static func _Transform3D_to_PackedFloat32(t: Transform3D) -> PackedFloat32Array:
	
	var template = PackedFloat32Array([
		t.basis.x.x, t.basis.y.x, t.basis.z.x, t.origin.x, 
		t.basis.x.y, t.basis.y.y, t.basis.z.y, t.origin.y,
		t.basis.x.z, t.basis.y.z, t.basis.z.z, t.origin.z
	])
	
	return template

static func _bitshift_left(value: int) -> int:
	return 1 << (value - 1)

#endregion : Lowlevel
