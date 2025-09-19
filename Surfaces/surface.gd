extends Area2D

@export var surface_data: SurfaceType

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if surface_data:
		apply_surface_color()
		
func apply_surface_color():
	var color_rect = $ColorRect
	var coll_shape = $CollisionShape2D
	if coll_shape and coll_shape.shape is RectangleShape2D:
		var shape = coll_shape.shape as RectangleShape2D
		color_rect.position = coll_shape.position - shape.size / 2
		color_rect.size = shape.size
		color_rect.color = surface_data.color
		color_rect.modulate.a = 0.5
		
func _on_body_entered(body) -> void:
	print("ENTERED: ", surface_data.surface_type if surface_data else "no surface")
	print("ENTERED SURFACE:")
	print("  Name: ", surface_data.surface_type)
	print("  Friction Multi: ", surface_data.friction_multi)
	print("  Accel Multi: ", surface_data.accel_multi)
	print("  Max Speed Multi: ", surface_data.max_speed_multi)
	print("  Drift Factor Multi: ", surface_data.drift_factor_multi)
	if body.has_method("enter_surface"):
		body.enter_surface(surface_data)
		
func _on_body_exited(body) -> void:
	print("EXITED: ", surface_data.surface_type if surface_data else "no surface")
	if body.has_method("exit_surface"):
		body.exit_surface()
