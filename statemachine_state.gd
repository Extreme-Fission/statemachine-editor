class_name State
extends Node

@export var transitions : Array[StateTransition] = []

@export var node_graph_position : Vector2 = Vector2.ZERO

var is_current : bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _start() -> void:
	pass

func _stop() -> void:
	pass
