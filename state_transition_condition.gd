class_name StateCondition
extends Resource

enum TriggerTypeEnum {
	float,
	int,
	bool,
	Signal
}

enum TriggerConditionEnum {
	Greater,
	Less,
	Equal,
	NotEqual,
}

@export var variable_name : StringName
@export var trigger_type : TriggerTypeEnum
@export var trigger_condition : TriggerConditionEnum

@export var trigger_value : float

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
