@tool
extends EditorPlugin

var snap_button: Button

func _enter_tree() -> void:
	snap_button = Button.new()
	snap_button.text = "Snap Tracks"
	snap_button.pressed.connect(_on_snap_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_button)

func _exit_tree() -> void:
	if snap_button:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, snap_button)
		snap_button.queue_free()

func _on_snap_button_pressed() -> void:
	var selection = get_editor_interface().get_selection()
	var selected_nodes = selection.get_selected_nodes()

	if selected_nodes.size() != 2:
		push_error("Please select exactly two track pieces")
		return

	var pieces = []
	for node in selected_nodes:
		if node is TrackPiece:
			pieces.append(node)
		else:
			push_warning("Selected nodes must be TrackPiece nodes")

	if pieces.size() != 2:
		push_error("Both selected nodes must be TrackPiece nodes")
		return

	var piece_a = pieces[0]
	var piece_b = pieces[1]

	# Compare distances between entry/exit points to determine snapping direction
	var pairs = [
		{ "from": piece_a.exit_point_global(), "to": piece_b.entry_point_global(), "snap_piece": piece_b },
		{ "from": piece_b.exit_point_global(), "to": piece_a.entry_point_global(), "snap_piece": piece_a }
	]

	var best_pair = pairs[0]
	var min_dist = pairs[0]["from"].distance_to(pairs[0]["to"])

	for p in pairs:
		var dist = p["from"].distance_to(p["to"])
		if dist < min_dist:
			min_dist = dist
			best_pair = p

	var snap_piece = best_pair["snap_piece"]
	var target_pos = best_pair["from"]
	var snap_entry = best_pair["to"]

	var offset = target_pos - snap_entry
	var new_position = snap_piece.global_position + offset

	# Align rotation
	var angle_diff = 0.0
	if snap_piece == piece_b:
		angle_diff = piece_a.exit_angle() - piece_b.entry_angle()
	else:
		angle_diff = piece_b.exit_angle() - piece_a.entry_angle()

	var undo_redo = get_undo_redo()
	undo_redo.create_action("Snap Track Pieces")
	undo_redo.add_do_property(snap_piece, "global_position", new_position)
	undo_redo.add_undo_property(snap_piece, "global_position", snap_piece.global_position)
	undo_redo.add_do_property(snap_piece, "rotation", snap_piece.rotation + angle_diff)
	undo_redo.add_undo_property(snap_piece, "rotation", snap_piece.rotation)
	undo_redo.commit_action()

	print("Snapped track pieces together")
