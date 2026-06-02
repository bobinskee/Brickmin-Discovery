extends BudBehavior

func update(bud: Brickbud, delta: float) -> void:
	
	if bud.velocity.is_finite():
		
		var y_vel = bud.velocity.y
		bud.velocity.y = Utils_Math._apply_gravity(delta, y_vel)
	
	else:
		push_warning("Velocity is infinite!!!")
