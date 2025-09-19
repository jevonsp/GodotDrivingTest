@tool
class_name TrackPiece extends Node2D


@export var main_track_type: SurfaceType 
@export var outer_track_type: SurfaceType

#region Snap Settings
@export var entry_point: Node2D # Snap Points
@export var exit_point: Node2D
@export var auto_position_snap_points: bool = true
@export var snap_enabled: bool = true # Snap Point Settings
@export var snap_distance: float = 50.0
#endregion
#region Curve Settings
@export_subgroup("Curve Settings")
@export var is_curved: bool = false
@export var curve_radius: float = 200.0
@export var curve_angle: float = 90.0  # degrees
@export var track_width: float = 100.0
@export var resolution: int = 16  # Number of segments
#endregion

var player_body = null
var on_main: bool = false
var on_outer: bool = false

@onready var main_track = $RoadSurface
@onready var outer_track = $OuterSurface
@onready var main_visual = $RoadSurface/Visual
@onready var outer_visual = $OuterSurface/Visual

func _ready() -> void:
	if Engine.is_editor_hint():
		setup_editor()
	else:
		setup_runtime()
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint() and is_curved:
		generate_curve()
		update_snap_points()
		queue_redraw()  # Keep the visualization updated
		
func _draw():
	if Engine.is_editor_hint():
		# Draw the calculated exit point position
		var exit_pos = get_exit_point() - global_position
		draw_circle(exit_pos, 5, Color.GREEN)
		
		# Draw direction indicator
		var exit_angle = get_exit_angle()
		var direction = Vector2(cos(exit_angle), sin(exit_angle)) * 20
		draw_line(exit_pos, exit_pos + direction, Color.RED, 2)
		
		# Draw entry point
		var entry_pos = get_entry_point() - global_position
		draw_circle(entry_pos, 5, Color.BLUE)
		
func setup_editor() -> void:
	apply_colors()
	if is_curved:
		generate_curve()
		update_snap_points()
	create_snap_points_if_missing()
		
func setup_runtime() -> void:
	setup_collision_shapes()
	apply_colors()
	connect_signals()
	
func setup_collision_shapes():
	var road_poly = main_visual.polygon
	var col = main_track.get_node("CollisionPolygon2D")
	col.polygon = road_poly
	
	var outer_poly = outer_visual.polygon
	var col_outer = outer_track.get_node("CollisionPolygon2D")
	col_outer.polygon = outer_poly
	
func apply_colors():
	if main_track_type:
		main_visual.color = main_track_type.color
	if outer_track_type:
		outer_visual.color = outer_track_type.color
		
func connect_signals():
	main_track.body_entered.connect(_on_road_surface_body_entered)
	outer_track.body_entered.connect(_on_outer_surface_body_entered)
	main_track.body_exited.connect(_on_road_surface_body_exited)
	outer_track.body_exited.connect(_on_outer_surface_body_exited)
	
func _on_road_surface_body_entered(body: Node2D) -> void:
	player_body = body
	on_main = true
	update_surface()
	
func _on_outer_surface_body_entered(body: Node2D) -> void:
	player_body = body
	on_outer = true
	update_surface()
	
func _on_road_surface_body_exited(body: Node2D) -> void:
	on_main = false
	update_surface()
	
func _on_outer_surface_body_exited(body: Node2D) -> void:
	on_outer = false
	update_surface()

func update_surface():
	if not player_body:
		return
	if on_main:
		player_body.enter_surface(main_track_type)
		print("entered: ", main_track_type.surface_type)
	elif on_outer:
		player_body.enter_surface(outer_track_type)
		print("entered: ", outer_track_type.surface_type)
	else:
		player_body.exit_surface()

func get_exit_point() -> Vector2:
	if not auto_position_snap_points and exit_point:
		return exit_point.global_position
	elif is_curved:
		var angle_rad = deg_to_rad(curve_angle)
		return global_position + Vector2(
			curve_radius * (1 - cos(angle_rad)),
			curve_radius * sin(angle_rad)
		)
	return global_position + Vector2(100, 0)
	
func get_entry_point() -> Vector2:
	if not auto_position_snap_points and entry_point:
		return entry_point.global_position
	return global_position
	
func get_exit_angle() -> float:
	if is_curved:
		return deg_to_rad(curve_angle)
	return 0.0
	
func snap_to(other_piece: TrackPiece) -> void:
	if not other_piece or not snap_enabled:
		return
	var other_exit = other_piece.get_exit_point()
	var my_entry = get_entry_point()
	
	var offset = other_exit - my_entry
	print("Other exit: ", other_exit)
	print("My entry: ", my_entry)
	print("Offset: ", offset)

	global_position += offset

func generate_curve():
	if not main_visual:
		return
	
	var angle_rad = deg_to_rad(curve_angle)
	
	var outer_radius = curve_radius + track_width / 2
	var inner_radius = max(10, curve_radius - track_width / 2)
	
	var off_outer_radius = curve_radius + track_width * 2
	var off_inner_radius =max(10, curve_radius - track_width)
	
	var outer_points = []
	var inner_points = []
	var off_outer_points = []
	var off_inner_points = []
	
	for i in range(resolution + 1):
		var t = float(i) / resolution
		var angle = t * angle_rad
		
		outer_points.append(Vector2(outer_radius * cos(angle), outer_radius * sin(angle)))
		inner_points.append(Vector2(inner_radius * cos(angle), inner_radius * sin(angle)))
		
		off_outer_points.append(Vector2(off_outer_radius * cos(angle), off_outer_radius * sin(angle)))
		off_inner_points.append(Vector2(off_inner_radius * cos(angle), off_inner_radius * sin(angle)))
	
	var road_poly = PackedVector2Array()
	for p in outer_points:
		road_poly.append(p)
	for i in range(inner_points.size() - 1, -1, -1):
		road_poly.append(inner_points[i])
	main_visual.polygon = road_poly
	
	if outer_visual:
		var offroad_poly = PackedVector2Array()
		for p in off_outer_points:
			offroad_poly.append(p)
		for i in range(off_inner_points.size() - 1, -1, -1):
			offroad_poly.append(off_inner_points[i])
		outer_visual.polygon = offroad_poly
	
	if Engine.is_editor_hint():
		if main_track:
			var col = main_track.get_node("CollisionPolygon2D")
			col.polygon = road_poly
		if outer_track:
			var col_outer = outer_track.get_node("CollisionPolygon2D")
			col_outer.polygon = outer_visual.polygon
		
func update_snap_points():
	if not Engine.is_editor_hint() or not auto_position_snap_points:
		return
	if is_curved:
		var exit_pos = get_exit_point() - global_position
		var entry_pos = get_entry_point() - global_position
		if exit_point:
			exit_point.position = exit_pos
			exit_point.rotation = get_exit_angle()
		if entry_point:
			entry_point.position = entry_pos
		
func create_snap_points_if_missing():
	if not Engine.is_editor_hint():
		return
		
	if not exit_point:
		var exit_node = Node2D.new()
		exit_node.name = "ExitPoint"
		# Look for existing SnapPoints container or create one
		var snap_points_container = get_node_or_null("SnapPoints")
		if not snap_points_container:
			snap_points_container = Node2D.new()
			snap_points_container.name = "SnapPoints"
			add_child(snap_points_container)
			snap_points_container.owner = get_tree().edited_scene_root
		
		snap_points_container.add_child(exit_node)
		exit_node.owner = get_tree().edited_scene_root
		exit_point = exit_node
	
	# Create entry snap point if missing
	if not entry_point:
		var entry_node = Node2D.new()
		entry_node.name = "EntryPoint"
		var snap_points_container = get_node_or_null("SnapPoints")
		if not snap_points_container:
			snap_points_container = Node2D.new()
			snap_points_container.name = "SnapPoints"
			add_child(snap_points_container)
			snap_points_container.owner = get_tree().edited_scene_root
		
		snap_points_container.add_child(entry_node)
		entry_node.owner = get_tree().edited_scene_root
		entry_point = entry_node
	

	
func _property_changed(property, value, field, changing):
	if Engine.is_editor_hint():
		if property in ["curve_radius", "curve_angle", "track_width", "resolution", "is_curved"]:
			generate_curve()
			update_snap_points()
			queue_redraw()
