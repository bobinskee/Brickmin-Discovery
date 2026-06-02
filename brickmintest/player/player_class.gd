class_name Player
extends Node3D

var player_ID: int = 1

@onready var body: CharacterBody3D = %CharacterBody3D
@onready var cursor: Node3D = %Pointer
@onready var input: Node = %InputHandler

var swarm_offsets: Array = []  
