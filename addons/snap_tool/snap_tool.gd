@tool
extends EditorPlugin

var snap_button: Button

func _enter_tree() -> void:
	# Create a toolbar button
	snap_button = Button.new()
	snap_button.text = "Snap Tracks"
	snap_button.pressed.connect(_on_snap_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_button)

func _exit_tree() -> void:
	# Clean up
	if snap_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_button)
		snap_button.queue_free()

func _on_snap_button_pressed() -> void:
	var selection = get_editor_interface().get_selection()
	var selected_nodes = selection.get_selected_nodes()

	if selected_nodes.size() != 2:
		push_error("Please select exactly two track pieces")
		return

	var track_pieces = []
	for node in selected_nodes:
		if node.has_method("get_entry_point") and node.has_method("get_exit_point"):
			track_pieces.append(node)
		else:
			push_error("Selected nodes must be track pieces")
			return

	if track_pieces.size() != 2:
		push_error("Both selected nodes must be track pieces")
		return

	var undo_redo = get_undo_redo()
	var piece_a = track_pieces[0]
	var piece_b = track_pieces[1]
	var exit_point = piece_a.get_exit_point()
	var entry_point = piece_b.get_entry_point()
	var offset = exit_point - entry_point
	var new_position = piece_b.global_position + offset

	undo_redo.create_action("Snap Track Pieces")
	undo_redo.add_do_property(piece_b, "global_position", new_position)
	undo_redo.add_undo_property(piece_b, "global_position", piece_b.global_position)
	undo_redo.commit_action()

	print("Snapped track pieces together")
