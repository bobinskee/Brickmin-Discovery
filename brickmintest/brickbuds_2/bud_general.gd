class_name General_Bud

enum types_list { BASE, AQKO }

static var all_buds: Array[Brickbud] = []

static var limit: int = 3

static var bud_data_loaded: bool = false
static var types_logged: bool = false

static var all_types: Dictionary = _log_types()

static func _log_types() -> Dictionary:
	
	#print("logging")
	
	var temp: Dictionary = {}
	
	for i in types_list.keys():
		temp[i] = {
			"active": false,
			"reference": null,
		}
	
	types_logged = true
	
	return temp
