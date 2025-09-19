extends CharacterBody2D

@export var drift_particles : GPUParticles2D

var current_checkpoint: int = 0
var current_speed: int

var max_speed: int
var acceleration: int
var friction: int
var drift_factor: float
var turn_speed: float

const base_max_speed: int = 1200
const base_acceleration: int = 600
const base_friction: int = 500
const base_drift_factor: float = 0.5
const base_turn_speed: float = 4.0

var current_surface = "normal"

var is_drifting: bool = false

func _ready() -> void:
	add_to_group("player")
	max_speed = base_max_speed
	acceleration = base_acceleration
	friction = base_friction
	drift_factor = base_drift_factor
	turn_speed = base_turn_speed

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	var accel_input = Input.get_action_strength("accelerate")
	var brake_input = Input.get_action_strength("brake")
	
	input_vector.x = accel_input - brake_input
	
	if input_vector.x != 0:
		current_speed += input_vector.x * acceleration * delta
		current_speed = clamp(current_speed, -max_speed * 0.5, max_speed)
	else:
		current_speed = move_toward(current_speed, 0, friction * delta)
	
	var turn_input = Input.get_axis("steer_left", "steer_right")
	var speed_factor = abs(current_speed) / max_speed
	var adjusted_turn_speed = turn_speed * (1.0 - speed_factor * 0.3)
	
	rotation += turn_input * adjusted_turn_speed * delta
	
	is_drifting = Input.is_action_pressed("drift")
	
	if is_drifting and abs(current_speed) > 50:
		drift_particles.emitting = true
		velocity = velocity.lerp(Vector2(current_speed, 0).rotated(rotation), drift_factor * delta * 10)
	else:
		drift_particles.emitting = false
		velocity = Vector2(current_speed, 0).rotated(rotation)
	move_and_slide()

func enter_surface(surface):
	friction = base_friction * surface.accel_multi
	acceleration = base_acceleration * surface.friction_multi
	max_speed = base_max_speed * surface.max_speed_multi
	drift_factor = base_drift_factor * surface.drift_factor_multi
	turn_speed = base_turn_speed * surface.turn_speed_multi
	
func exit_surface():
	current_surface = "normal"
	friction = base_friction
	acceleration = base_acceleration
	max_speed = base_max_speed
	drift_factor = base_drift_factor
	turn_speed = base_turn_speed
	
