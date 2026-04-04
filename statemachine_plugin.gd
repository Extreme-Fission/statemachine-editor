@tool
extends EditorPlugin

var dock
var current_state_machine : StateMachine

func _enable_plugin() -> void:
	# Add autoloads here.
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	var dock_scene = preload("res://addons/statemachine-editor/statemachine_editor.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	dock.title = "Statemachine Editor"
	dock.default_slot = DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_ALL | EditorDock.DOCK_LAYOUT_FLOATING
	dock.custom_minimum_size = Vector2(0, 450)
	
	add_dock(dock)
	
	dock.close()

func _handles(object) -> bool:
	if object is StateMachine:
		current_state_machine = object
		return true
	elif object is State:
		if object.get_parent() is StateMachine:
			current_state_machine = object.get_parent()
		return true
	else:
		return false
	
	#return object is StateMachine or object is State

func _edit(object):
	if object:
		dock.make_visible()
		dock.get_child(0).set_target(current_state_machine)
	else:
		dock.close()

func _exit_tree() -> void:
	# Remove the dock.
	remove_dock(dock)
	# Erase the control from the memory.
	dock.queue_free()
