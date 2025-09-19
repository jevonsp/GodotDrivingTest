extends Area2D

@export var checkpoint_num: int = 0

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	apply_surface_color()
	
func apply_surface_color():
	var color_rect = $ColorRect
	var coll_shape = $CollisionShape2D
	if coll_shape and coll_shape.shape is RectangleShape2D:
		var shape = coll_shape.shape as RectangleShape2D
		color_rect.position = coll_shape.position - shape.size / 2
		color_rect.size = shape.size
		color_rect.color = Color.WHITE
		color_rect.modulate.a = 0.5
	
func _on_body_entered(body) -> void:
	var race_manager = get_tree().get_first_node_in_group("race_manager")
	if body.is_in_group("player"):
		race_manager.enter_checkpoint(checkpoint_num)
