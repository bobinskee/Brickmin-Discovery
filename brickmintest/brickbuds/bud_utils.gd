extends RefCounted
class_name BudUtils

#region Game variables
static var bud_limit = 10

#endregion

enum state {IDLE, FOLLOW, AIRBORNE}

static var idle_state: BudState = preload("res://brickbuds/bud_states/idle_state.gd").new()
static var follow_state: BudState = preload("res://brickbuds/bud_states/follow_state.gd").new()
static var airborne_state: BudState = preload("res://brickbuds/bud_states/airborne_state.gd").new()
#static var follow_v2: BudnState = preload("res://brickbuds/bud_states/followstate_v2.gd").new() 

static var spatial_grid: Dictionary = {}
const grid_size: float = 1

##Return a normalized vector pointing away from any too-close neighbors.
static func setup_spatial_grid(all_buds: Array) -> void:
	
	spatial_grid.clear()
	
	for bud in all_buds:
	
		var grid_pos = Vector2i(bud.global_position.x / grid_size, bud.global_position.z / grid_size)
		
		if not spatial_grid.has(grid_pos):
			spatial_grid[grid_pos] = []
		
		spatial_grid[grid_pos].append(bud)

static func get_repel_vector(bud: CharacterBody3D, check_cap: int) -> Vector3:
	
	var repel_vector = Vector3.ZERO
	
	var bud_pos = Vector2i(floori(bud.global_position.x / grid_size), floori(bud.global_position.z / grid_size))
	
	var checked_buds: int = 0
	
	for x in range(3):
		for z in range(3):
			var curr_pos = bud_pos + Vector2i(x - 1, z - 1)
			
			if spatial_grid.has(curr_pos):
				for other in spatial_grid[curr_pos]:
					if other == bud:
						continue
					
					if checked_buds >= check_cap:
						break
					
					var difference = bud.global_position - other.global_position
					
					if difference.length_squared() < 0.0001:
						repel_vector += Vector3(randf() - 0.5, 0, randf() - 0.5)
						checked_buds += 1
					
					elif difference.length_squared() < pow(grid_size, 2):
						repel_vector += difference.normalized()
						checked_buds += 1
		
		if checked_buds >= check_cap:
			break
	
	return repel_vector

static func cliff_slide(cur_move: Vector3, normals: Array) -> Vector3:
	
	var new_norms = []
	var combined_norm = Vector3.ZERO
	var new_vector = Vector3.ZERO
	
	for i in range(2):
		#var cur_norm = min_data["normals"][i]
		var cur_norm = normals[i]
		
		if cur_norm != Vector3.ZERO and not cur_norm in new_norms:
			new_norms.append(cur_norm)
			combined_norm += cur_norm
		
	if cur_move and combined_norm:
		combined_norm = combined_norm.normalized()
		
		if combined_norm.dot(cur_move) > 0:
			new_vector = cur_move.slide(combined_norm)
	
	return new_vector
