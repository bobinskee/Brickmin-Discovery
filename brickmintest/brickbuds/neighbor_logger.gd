extends Area3D

var neighbors: Array[Node3D] = []

func _ready() -> void:
	area_entered.connect(_hello_neighbor)
	area_exited.connect(_goodbye_neighbor)

func _hello_neighbor(area: Area3D) -> void:
	if area == self:
		return
	
	neighbors.append(area)

func _goodbye_neighbor(area: Area3D) -> void:
	neighbors.erase(area)

#func _process(_delta: float) -> void:
#	print(neighbors.size())
