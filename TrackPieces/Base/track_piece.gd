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
@export var snap_enabled: bool = true

# ----------------------
# Runtime Vars
# ----------------------
var player_body: Node = null
var on_main: bool = false
var on_outer: bool = false

# ----------------------
# Node references
# ----------------------
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

# ----------------------
# Setup
# ----------------------
func setup_editor():
	setup_surface(main_track, main_track_type)
	setup_surface(outer_track, outer_track_type)
	create_snap_points_if_missing()

func setup_runtime():
	setup_surface(main_track, main_track_type)
	setup_surface(outer_track, outer_track_type)
	connect_signals()

func setup_surface(surface_node: Node, surface_type: SurfaceType) -> void:
	if not surface_node or not surface_type:
		return

	var collision: CollisionPolygon2D = surface_node.get_node_or_null("CollisionPolygon2D")
	if not collision:
		return

	# Look for a child with a node named "Fill"
	var fill: Node = null
	for child in surface_node.get_children():
		var candidate = child.get_node_or_null("Fill")
		if candidate:
			fill = candidate
			break

	if fill:
		# Apply color
		if "color" in fill:
			fill.color = surface_type.color

		# Sync polygon, adjusting for transforms
		if "polygon" in fill:
			var transformed_poly := PackedVector2Array()
			for p in fill.polygon:
				# Convert from Fill local → Collision local
				var global_point = fill.to_global(p)
				var local_point = collision.to_local(global_point)
				transformed_poly.append(local_point)
			collision.polygon = transformed_poly


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
		exit_point.position = Vector2(100, 0)  # default position
