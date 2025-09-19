@tool
class_name TrackPiece
extends Node2D

# ----------------------
# Track Surface
# ----------------------
@export var main_track_type: SurfaceType
@export var outer_track_type: SurfaceType

# ----------------------
# Snap Points
# ----------------------
@export var entry_point: Node2D
@export var exit_point: Node2D
@export var snap_enabled: bool = true  # Only snapping enabled/disabled

# ----------------------
# Curve Settings
# ----------------------
@export_subgroup("Curve Settings")
@export var is_curved: bool = false
@export var curve_radius: float = 200.0
@export var curve_angle: float = 90.0
@export var track_width: float = 100.0
@export var resolution: int = 16

# ----------------------
# Runtime Vars
# ----------------------
var player_body: Node = null
var on_main: bool = false
var on_outer: bool = false

# ----------------------
# Node references
# ----------------------
@onready var main_visual = $RoadSurface/Visual
@onready var outer_visual = $OuterSurface/Visual
@onready var main_track = $RoadSurface
@onready var outer_track = $OuterSurface

# ----------------------
# Lifecycle
# ----------------------
func _ready():
	if Engine.is_editor_hint():
		setup_editor()
	else:
		setup_runtime()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and is_curved:
		generate_curve()
		queue_redraw()

func _draw():
	if Engine.is_editor_hint() and entry_point and exit_point:
		draw_circle(entry_point.global_position, 5, Color.BLUE)
		draw_circle(exit_point.global_position, 5, Color.GREEN)
		var dir = Vector2(cos(exit_angle()), sin(exit_angle())) * 20
		draw_line(exit_point.global_position, exit_point.global_position + dir, Color.RED, 2)

# ----------------------
# Setup
# ----------------------
func setup_editor():
	apply_colors()
	create_snap_points_if_missing()
	if is_curved:
		generate_curve()

func setup_runtime():
	apply_colors()
	setup_collision_shapes()
	connect_signals()

func apply_colors():
	if main_track_type:
		main_visual.color = main_track_type.color
	if outer_track_type:
		outer_visual.color = outer_track_type.color

func setup_collision_shapes():
	main_track.get_node("CollisionPolygon2D").polygon = main_visual.polygon
	outer_track.get_node("CollisionPolygon2D").polygon = outer_visual.polygon

func connect_signals():
	main_track.body_entered.connect(_on_road_surface_body_entered)
	main_track.body_exited.connect(_on_road_surface_body_exited)
	outer_track.body_entered.connect(_on_outer_surface_body_entered)
	outer_track.body_exited.connect(_on_outer_surface_body_exited)

# ----------------------
# Player Surface
# ----------------------
func _on_road_surface_body_entered(body):
	player_body = body
	on_main = true
	update_surface()

func _on_outer_surface_body_entered(body):
	player_body = body
	on_outer = true
	update_surface()

func _on_road_surface_body_exited(body):
	on_main = false
	update_surface()

func _on_outer_surface_body_exited(body):
	on_outer = false
	update_surface()

func update_surface():
	if not player_body:
		return
	if on_main:
		player_body.enter_surface(main_track_type)
	elif on_outer:
		player_body.enter_surface(outer_track_type)
	else:
		player_body.exit_surface()

# ----------------------
# Entry / Exit Points
# ----------------------
func entry_point_global() -> Vector2:
	return entry_point.global_position if entry_point else global_position

func exit_point_global() -> Vector2:
	return exit_point.global_position if exit_point else global_position

func entry_angle() -> float:
	return entry_point.rotation if entry_point else rotation

func exit_angle() -> float:
	return exit_point.rotation if exit_point else rotation

# ----------------------
# Snapping
# ----------------------
func snap_to(other: TrackPiece):
	if not snap_enabled or not other or not entry_point or not other.exit_point:
		return

	var offset = other.exit_point.global_position - entry_point.global_position
	global_position += offset

	var angle_diff = other.exit_point.rotation - entry_point.rotation
	rotation += angle_diff

# ----------------------
# Curve Generation
# ----------------------
func generate_curve():
	if not main_visual:
		return

	var angle_rad = deg_to_rad(curve_angle)
	var half_width = track_width / 2
	var inner_r = max(10, curve_radius - half_width)
	var outer_r = curve_radius + half_width

	var main_outer_points = []
	var main_inner_points = []

	for i in range(resolution + 1):
		var t = float(i) / resolution
		var a = t * angle_rad

		var point_on_radius = Vector2(curve_radius * cos(a), curve_radius * sin(a))

		# 2D perpendicular (right-hand normal)
		var tangent = Vector2(-sin(a), cos(a)).normalized()
		var normal = Vector2(-tangent.y, tangent.x)

		main_outer_points.append(point_on_radius + normal * half_width)
		main_inner_points.append(point_on_radius - normal * half_width)

	# Build main polygon
	var main_poly = PackedVector2Array()
	for p in main_outer_points:
		main_poly.append(p)
	for i in range(main_inner_points.size() - 1, -1, -1):
		main_poly.append(main_inner_points[i])
	main_visual.polygon = main_poly

	# Outer visual offset curve
	if outer_visual:
		var offset = half_width
		var outer_points = []
		var inner_points = []

		for i in range(resolution + 1):
			var t = float(i) / resolution
			var a = t * angle_rad

			var point_on_radius = Vector2(curve_radius * cos(a), curve_radius * sin(a))
			var tangent = Vector2(-sin(a), cos(a)).normalized()
			var normal = Vector2(-tangent.y, tangent.x)

			outer_points.append(point_on_radius + normal * (half_width + offset))
			inner_points.append(point_on_radius - normal * (half_width + offset))

		var outer_poly = PackedVector2Array()
		for p in outer_points:
			outer_poly.append(p)
		for i in range(inner_points.size() - 1, -1, -1):
			outer_poly.append(inner_points[i])
		outer_visual.polygon = outer_poly

# ----------------------
# Snap Points Creation (manual)
# ----------------------
func create_snap_points_if_missing():
	var container = get_node_or_null("SnapPoints")
	if not container:
		container = Node2D.new()
		container.name = "SnapPoints"
		add_child(container)
		container.owner = get_tree().edited_scene_root

	if not entry_point:
		entry_point = Node2D.new()
		entry_point.name = "EntryPoint"
		container.add_child(entry_point)
		entry_point.owner = get_tree().edited_scene_root
		entry_point.position = Vector2.ZERO

	if not exit_point:
		exit_point = Node2D.new()
		exit_point.name = "ExitPoint"
		container.add_child(exit_point)
		exit_point.owner = get_tree().edited_scene_root
		exit_point.position = Vector2(100, 0)  # Default, editable manually
