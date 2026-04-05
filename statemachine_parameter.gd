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
