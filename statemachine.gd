@tool
class_name StateMachine
extends Node

@export var STATES : Array[State]
@export var PARAMETERS : Array[Parameter]

@export var start_state : State
var current_state : State

func _ready() -> void:
	if Engine.is_editor_hint():
		STATES = get_states()
	else:
		STATES = get_states()
		
		for parameter in PARAMETERS:
			parameter.emitted.connect(parameter_signal_emitted.bind(parameter))
	
	current_state = start_state

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		STATES = get_states()
	else:
		if current_state:
			current_state.set_process(true)
			current_state.set_physics_process(true)
			for transition in current_state.transitions:
				var to_state : State
				for state in STATES:
					if state.name == transition.toState:
						to_state = state
				
				if to_state == null: continue
				
				for condition in transition.conditions:
					var referenced_parameter : Parameter
					for parameter in PARAMETERS:
						if parameter.name == condition.variable_name:
							referenced_parameter = parameter
					
					if referenced_parameter == null: continue
					
					match condition.trigger_type:
						condition.TriggerTypeEnum.float:
							if check_trigger(referenced_parameter.value, condition.trigger_value, condition.trigger_condition):
								transition(current_state, to_state)
						condition.TriggerTypeEnum.int:
							if check_trigger(int(referenced_parameter.value), int(condition.trigger_value), condition.trigger_condition):
								transition(current_state, to_state)
						condition.TriggerTypeEnum.bool:
							if referenced_parameter.value == condition.trigger_value:
								transition(current_state, to_state)
						condition.TriggerTypeEnum.Signal:
							pass

func check_trigger(value : float, trigger_value : float, trigger_condition : int) -> bool:
	match trigger_condition:
		StateCondition.TriggerConditionEnum.Greater:
			if value > trigger_value: return true
		StateCondition.TriggerConditionEnum.Less:
			if value < trigger_value: return true
		StateCondition.TriggerConditionEnum.Equal:
			if value == trigger_value: return true
		StateCondition.TriggerConditionEnum.NotEqual:
			if value != trigger_value: return true
	
	return false

func parameter_signal_emitted(parameter : Parameter):
	for transition in current_state.transitions:
		var to_state : State
		for state in STATES:
			if state.name == transition.toState:
				to_state = state
		
		if to_state == null: continue
		
		for condition in transition.conditions:
			if condition.trigger_type != condition.TriggerTypeEnum.Signal: continue
			if condition.variable_name == parameter.name:
				transition(current_state, to_state)

func transition(from_state : State, to_state : State):
	from_state.set_process(false)
	from_state.set_physics_process(false)
	current_state = to_state

func get_states() -> Array:
	var states : Array[State]
	for child in get_children():
		if child is State:
			states.append(child)
	return states
