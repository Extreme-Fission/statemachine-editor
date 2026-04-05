class_name State
extends Node

@export var transitions : Array[StateTransition] = []

@export var node_graph_position : Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

func _process(delta: float) -> void:
	pass
