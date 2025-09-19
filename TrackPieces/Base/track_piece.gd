@tool
class_name TrackPiece extends Node2D

@export var main_track_type: SurfaceType 
@export var outer_track_type: SurfaceType
@export var entry_point: Node2D # Snap Points
@export var exit_point: Node2D
@export var snap_enabled: bool = true # Snap Point Settings
@export var snap_distance: float = 50.0

var player_body = null
var on_main: bool = false
var on_outer: bool = false

@onready var main_track = $RoadSurface
@onready var outer_track = $OuterSurface
@onready var main_visual = $RoadSurface/Visual
@onready var outer_visual = $OuterSurface/Visual

func _ready() -> void:
	setup_collision_shapes()
	apply_colors()
	connect_signals()
	
func setup_collision_shapes():
	var road_shape = ConvexPolygonShape2D.new()
	road_shape.points = main_visual.polygon
	main_track.get_node("CollisionShape2D").shape = road_shape
	var outer_shape = ConvexPolygonShape2D.new()
	outer_shape.points = outer_visual.polygon
	outer_track.get_node("CollisionShape2D").shape = outer_shape
	
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
	return exit_point.global_position if exit_point else global_position
	
func get_entry_point() -> Vector2:
	return entry_point.global_position if entry_point else global_position

func snap_to(other_piece: TrackPiece) -> void:
	if not other_piece or not snap_enabled:
		return
	var other_exit = other_piece.get_exit_point()
	var my_entry = get_entry_point()
	
	var offset = other_exit - my_entry
	global_position += offset
