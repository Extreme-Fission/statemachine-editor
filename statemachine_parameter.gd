class_name Parameter
extends Resource

enum TypeEnum {
	float,
	int,
	bool,
	Signal
}

@export var name : String
@export var type : TypeEnum

@export var value : float
signal emitted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
