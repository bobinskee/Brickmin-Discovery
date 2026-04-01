extends Node3D

var squad: Array = []

var all_min: Array = BrickminManager.total_min

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("disband"):
		for i in range(squad.size()):
			squad[i].leader = null
			squad[i].state = load("res://brickmin/brickmin_states/idle_state.tres")
			
			if i == squad.size() - 1:
				squad.clear()
				
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if squad.size() > 0: 
			for i in range(squad.size()):
				squad[i].leader = null
				squad[i].state = load("res://brickmin/brickmin_states/idle_state.tres")
				squad.erase(squad[i])

func _process(_delta: float) -> void:
	
	for i in (all_min):
		if i.leader and not squad.has(i):
			var actual_player = (i.leader.get_parent().get_parent().name)
			if actual_player == self.name:
				squad.append(i)
