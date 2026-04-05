@tool
extends Control

@onready var graph_edit : GraphEdit = %GraphEdit
@onready var parameter_search : LineEdit = %ParameterSearch
@onready var parameter_add_menu : MenuButton = %ParameterAddMenu
@onready var parameters_menu : VBoxContainer = %Parameters
@onready var transitions_menu : VBoxContainer = %Transitions
@onready var transitions_menu_add_button : Button = %TransitionAddButton

@export var state_graph_node : PackedScene
@export var parameter_node : PackedScene
@export var transition_node : PackedScene
@export var condition_node : PackedScene

@export var states : Array[State]
@export var parameters : Array[Parameter]

var state_machine : StateMachine

var selected_state : State

var draw_layer : Control

func _ready() -> void:
	draw_layer = Control.new()
	draw_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	draw_layer.draw.connect(_on_draw_layer_draw)
	draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_edit.add_child(draw_layer)
	
	graph_edit.connection_request.connect(_graph_edit_connection_request)
	graph_edit.node_selected.connect(_node_selected)
	graph_edit.node_deselected.connect(_node_deselected)
	
	parameter_add_menu.get_popup().id_pressed.connect(_add_parameter)
	transitions_menu_add_button.pressed.connect(_add_transition)

func _process(delta: float) -> void:
	if draw_layer:
		draw_layer.queue_redraw()

func _on_draw_layer_draw() -> void:
	for state in states:
		for transition in state.transitions:
			var from_node : GraphNode = null
			var to_node : GraphNode = null
			
			for child in graph_edit.get_children():
				if child is GraphNode:
					if child.title == state.name:
						from_node = child
					if child.title == transition.toState:
						to_node = child
			
			if from_node == null or to_node == null:
				continue
			
			var from_pos = from_node.position + from_node.size * 0.5 * graph_edit.zoom
			var to_pos = to_node.position + to_node.size * 0.5 * graph_edit.zoom
			
			draw_layer.draw_line(from_pos, to_pos, Color.WHITE, 1, true)
			
			var mid_pos = (from_pos + to_pos) * 0.5
			var direction = (to_pos - from_pos).normalized()
			var arrow_size = 10.0 * graph_edit.zoom
			var arrow_angle = deg_to_rad(45.0)
			var arrow_tip = mid_pos + direction * arrow_size
			var left  = mid_pos - direction.rotated(-arrow_angle) * arrow_size
			var right = mid_pos - direction.rotated( arrow_angle) * arrow_size
			
			var arrow_points = PackedVector2Array([arrow_tip, left, right])
			
			draw_layer.draw_colored_polygon(arrow_points, Color.WHITE)
			
			draw_layer.draw_polyline(
				PackedVector2Array([arrow_tip, left, right, arrow_tip]),
				Color.WHITE, 1.0, true
			)

func set_target(statemachine : StateMachine):
	set_states(statemachine)
	set_parameters(statemachine)
	state_machine = statemachine
	
func set_parameters(statemachine : StateMachine):
	var index : int = 0
	for child in parameters_menu.get_children(true):
		if index == 0:
			index += 1
		elif child is HBoxContainer:
			index += 1
			child.queue_free()
	
	parameters = statemachine.PARAMETERS
	
	for parameter in parameters:
		var instance : HBoxContainer = parameter_node.instantiate()
		instance.get_child(0).text = parameter.name
		instance.get_child(0).text_submitted.connect(_parameter_name_changed.bind(parameter))
		instance.get_child(1).selected = parameter.type
		instance.get_child(1).item_selected.connect(_parameter_item_selected.bind(parameter, instance))
		instance.get_child(2).pressed.connect(_parameter_delete.bind(parameter, instance))
		
		parameters_menu.add_child(instance)
	
func set_states(statemachine : StateMachine):
	for child in graph_edit.get_children(true):
		if child is GraphNode:
			child.free()
	
	states.clear()
	for state in statemachine.get_states():
		states.append(state)
	
	for state in states:
		var instance : GraphNode = state_graph_node.instantiate()
		instance.position_offset = state.node_graph_position
		instance.position_offset_changed.connect(_position_offset_changed.bind(state, instance))
		instance.title = state.name
		graph_edit.add_child(instance)

func _position_offset_changed(state: State, instance: GraphNode) -> void:
	state.node_graph_position = instance.position_offset

func _graph_edit_connection_request(from_node : StringName, from_port : int, to_node : StringName, to_port : int):
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _parameter_delete(parameter : Parameter, instance : HBoxContainer):
	instance.queue_free()
	state_machine.PARAMETERS.pop_at(state_machine.PARAMETERS.find(parameter))

func _parameter_item_selected(id : int, parameter : Parameter, instance : HBoxContainer):
	parameter.type = id

func _add_parameter(id : int):
	var parameter : Parameter = Parameter.new()
	parameter.name = "New Parameter " + str(parameters.size())
	parameter.type = id
	
	state_machine.PARAMETERS.append(parameter)
	
	var instance : HBoxContainer = parameter_node.instantiate()
	instance.get_child(0).text = parameter.name
	instance.get_child(0).text_submitted.connect(_parameter_name_changed.bind(parameter))
	instance.get_child(1).selected = id 
	instance.get_child(1).item_selected.connect(_parameter_item_selected.bind(parameter, instance))
	instance.get_child(2).pressed.connect(_parameter_delete.bind(parameter, instance))
	parameters_menu.add_child(instance)

func _parameter_name_changed(string : String, parameter : Parameter):
	parameter.name = string

func _node_selected(node : Node):
	for child in state_machine.get_children():
		if child is State and child.name == node.title:
			selected_state = child
	
	for child in transitions_menu.get_children(true):
		if child is FoldableContainer:
			child.queue_free()
	
	for transition in selected_state.transitions:
		add_transition(transition)

func _node_deselected(node : Node):
	selected_state = null
	for child in transitions_menu.get_children(true):
		if child is FoldableContainer:
			child.queue_free()

func _add_transition():
	if selected_state != null:
		var new_state_transition : StateTransition = StateTransition.new()
		
		var transitions = selected_state.transitions.duplicate()
		transitions.append(new_state_transition)
		selected_state.transitions = transitions
		
		add_transition(new_state_transition)

func add_transition(transition : StateTransition):
	var instance : FoldableContainer = transition_node.instantiate()
	
	instance.title = str(selected_state.name) + " -> " + str(transition.toState)
	
	transitions_menu.add_child(instance)
	
	var line_edit := instance.get_node("VBoxContainer/HBoxContainer/LineEdit") as LineEdit
	line_edit.text = str(transition.toState)
	line_edit.text_submitted.connect(_transition_to_state_changed.bind(transition, instance))
	
	for condition in transition.conditions:
		add_condition(instance, condition, transition)
	
	instance.get_child(0).get_child(2).get_child(0).pressed.connect(_add_condition.bind(instance, transition))
	instance.get_child(0).get_child(2).get_child(1).pressed.connect(_remove_transition.bind(instance, transition))

func _remove_transition(instance : FoldableContainer, transition : StateTransition):
	var transitions = selected_state.transitions.duplicate()
	transitions.pop_at(transitions.find(transition))
	selected_state.transitions = transitions
	instance.queue_free()

func _add_condition(instance : FoldableContainer, transition : StateTransition):
	var new_condition : StateCondition = StateCondition.new()
	
	var conditions = transition.conditions.duplicate()
	conditions.append(new_condition)
	transition.conditions = conditions
	
	add_condition(instance, new_condition, transition)

func add_condition(instance : FoldableContainer, condition : StateCondition, transition : StateTransition):
	var condition_instance : FoldableContainer = condition_node.instantiate()
	var condition_instance_inputs = condition_instance.get_child(0).get_child(0).get_child(1)
	
	edit_condition_name(condition, instance)
	
	condition_instance_inputs.get_child(0).text = condition.variable_name
	condition_instance_inputs.get_child(1).selected = condition.trigger_type
	condition_instance_inputs.get_child(2).selected = condition.trigger_condition
	
	edit_condition_type(condition, condition_instance)
	
	instance.get_child(0).get_child(1).add_child(condition_instance)
	
	condition_instance_inputs.get_child(0).text_submitted.connect(_edit_condition_variable.bind(condition, transition, condition_instance))
	condition_instance_inputs.get_child(1).item_selected.connect(_edit_condition_type.bind(condition, transition, condition_instance))
	condition_instance_inputs.get_child(2).item_selected.connect(_edit_condition_trigger.bind(condition, transition, condition_instance))
	
	condition_instance_inputs.get_child(3).get_child(0).text_submitted.connect(_edit_condition_value_line.bind(condition, transition, condition_instance))
	condition_instance_inputs.get_child(3).get_child(1).toggled.connect(_edit_condition_value_bool.bind(condition, transition, condition_instance))
	
	condition_instance.get_child(0).get_child(1).pressed.connect(remove_condition.bind(condition_instance, condition, transition))

func _edit_condition_value_bool(is_pressed : bool, condition : StateCondition, transition : StateTransition, condition_instance : FoldableContainer):
	transition.conditions[transition.conditions.find(condition)].trigger_value = is_pressed
	edit_condition_name(condition, condition_instance)

func _edit_condition_value_line(new_text : String, condition : StateCondition, transition : StateTransition, condition_instance : FoldableContainer):
	transition.conditions[transition.conditions.find(condition)].trigger_value = new_text.to_float()
	edit_condition_name(condition, condition_instance)

func _edit_condition_variable(new_text : String, condition : StateCondition, transition : StateTransition, condition_instance : FoldableContainer):
	transition.conditions[transition.conditions.find(condition)].variable_name = new_text
	edit_condition_name(condition, condition_instance)

func _edit_condition_type(id : int, condition : StateCondition, transition : StateTransition, condition_instance : FoldableContainer):
	transition.conditions[transition.conditions.find(condition)].trigger_type = id
	edit_condition_name(condition, condition_instance)
	edit_condition_type(condition, condition_instance)

func edit_condition_type(condition : StateCondition, condition_instance : FoldableContainer):
	var condition_instance_inputs = condition_instance.get_child(0).get_child(0)
	var condition_value_label = condition_instance_inputs.get_child(0).get_child(3)
	var condition_instance_inputs2 = condition_instance_inputs.get_child(1).get_child(3)
	
	if condition.TriggerTypeEnum.find_key(condition.trigger_type) == "bool":
		condition_value_label.visible = true
		condition_instance_inputs2.get_child(1).visible = true
		condition_instance_inputs2.get_child(1).button_pressed = condition.trigger_value == 1
		condition_instance_inputs2.get_child(0).visible = false
		condition_instance_inputs.get_child(1).get_child(2).visible = false
		condition_instance_inputs.get_child(0).get_child(2).visible = false
	elif condition.TriggerTypeEnum.find_key(condition.trigger_type) == "Signal":
		condition_value_label.visible = false
		condition_instance_inputs2.get_child(0).visible = false
		condition_instance_inputs2.get_child(1).visible = false
		condition_instance_inputs.get_child(1).get_child(2).visible = false
		condition_instance_inputs.get_child(0).get_child(2).visible = false
	else:
		condition_value_label.visible = true
		condition_instance_inputs2.get_child(0).visible = true
		condition_instance_inputs2.get_child(0).text = str(condition.trigger_value)
		condition_instance_inputs2.get_child(1).visible = false
		condition_instance_inputs.get_child(1).get_child(2).visible = true
		condition_instance_inputs.get_child(0).get_child(2).visible = true
		
func edit_condition_name(condition : StateCondition, condition_instance : FoldableContainer):
	condition_instance.title = condition.variable_name + " " + \
		condition.TriggerConditionEnum.find_key(condition.trigger_condition) + " " + \
		str(condition.trigger_value)
	
func _edit_condition_trigger(id : int, condition : StateCondition, transition : StateTransition, condition_instance):
	transition.conditions[transition.conditions.find(condition)].trigger_condition = id
	edit_condition_name(condition, condition_instance)

func remove_condition(condition_instance : FoldableContainer, condition : StateCondition, transition : StateTransition):
	var conditions = transition.conditions.duplicate()
	conditions.pop_at(conditions.find(condition))
	transition.conditions = conditions
	condition_instance.queue_free()
	
func _transition_to_state_changed(string : String, transition : StateTransition, instance : FoldableContainer):
	transition.toState = string
	instance.title = str(selected_state.name) + " -> " + str(transition.toState)
	
