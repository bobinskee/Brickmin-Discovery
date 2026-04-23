extends CharacterBody3D

var leader: Node3D = null
var state: String = "idle"
var id: int = 0
var disbanded: bool = false

var set_leader = false

var thrown: bool = false
var gapjumped: bool = false

var speed: float = 15.0
var acceleration: float = 50.0
var jump_power: float = 4
var jump_height: float = 10
var being_called: bool = false
var last_pos: Vector3 = Vector3.ZERO
var space_min: float = 1.0
var space_leader: float = 1.85

#follow state hopping variables
var can_hop: bool = false
var cur_pos: Vector3 = Vector3.ZERO
var follow_index = 0
var time_before_pathfind = 3
var next_pos: Vector3 = Vector3.ZERO
var pathing: bool = false
var hopped: bool = false
var jump_t: float = 0.0
var awaiting_hop_position:bool = true
var made_it: bool = false
var following: bool = false
var where_to_hop: Vector3 = Vector3.ZERO
var fallback: float = 5.0
var xz_rand = (randf_range(0, 5))
var near_cliff: bool = false
var walk_off: bool = true

var reaction_time = 1 + randf_range(0, 0.3)
var failsafe_jump: bool = false
var can_extend: bool = true

#stuff for gap jumping
var comb_force: Vector3 = Vector3.ZERO
var wanna_jump: bool = false
var jump_timer = randf_range(0, 0.2)

var player_cursor: Vector3
var swarming
var leader_body

#thrown state stuff
var t: float = 0.0
var start: Vector3 = Vector3.ZERO
var end: Vector3 = Vector3.ZERO
var mid: Vector3 = Vector3.ZERO
