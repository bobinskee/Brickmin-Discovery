extends Resource
class_name BudStats

enum type { BASE }

const stats = {
	
	type.BASE: {
		
		"name" : "base bud",
		
		#Speed
		"top_speed" : 15.0,
		"acceleration" : 50,
		
		#Jumping
		"jump_power" : 4,
		"jump_height" : 10,
		
		#Health
		"max_health" : 10,
		
		"shape_scale": {"height": 2.0, "radius": 0.5},
		
		"mesh": "res://brickbuds_2/objects/models/test_pillbud.tres",
	},
	
}
