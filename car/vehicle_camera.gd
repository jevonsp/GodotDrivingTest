extends Camera2D

@export var player: CharacterBody2D
var base_zoom: float = 1.0
var max_zoom: float = 0.7

func _physics_process(delta: float) -> void:
	position = player.position
	
	var speed_factor = min(abs(player.current_speed) / (player.max_speed * 0.8), 1.0)
	var target_zoom = lerp(base_zoom, max_zoom, speed_factor)
	
	zoom = lerp(zoom, Vector2(target_zoom, target_zoom), 5.0 * delta)
