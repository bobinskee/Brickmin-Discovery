extends Node3D

@onready var characterBody = $CharacterBody3D

var leader
var min_ID: int = 0
var leader_RIDs = []

func _set_leader(player_name):
	if leader == null:
		leader = str(player_name)
		
		var all_leaders = get_tree().get_nodes_in_group("leaders")
		
		for i in all_leaders:
			
			if i.name == leader:
				var leader_node = i
				var leader_body = leader_node.get_child(0).get_child(0)
				#print(leader_body)
				
				characterBody._set_target(leader_body)
