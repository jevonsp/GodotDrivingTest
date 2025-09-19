extends Node2D

@export var total_laps: int = 3
@export var timer: Timer

var total_checkpoints: int = 0
var current_checkpoint: int = 0
var current_lap: int = 0
var lap_timer: float = 0.0
var race_timer: float = 0.0

func _ready() -> void:
	add_to_group("race_manager")
	call_deferred("count_checkpoints")
	
func _process(delta: float) -> void:
	if current_checkpoint > 0 and current_lap < total_laps:
		lap_timer += delta
	
func count_checkpoints():
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	total_checkpoints = checkpoints.size()
	print("Race setup: ", total_checkpoints, " checkpoints, ", total_laps, " laps")

func enter_checkpoint(num: int) -> void:
	print("Trying checkpoint ", num, " - current is ", current_checkpoint)
	if num == 0:
		if current_checkpoint == 0:
			current_checkpoint += 1
			print("Race started! Checkpoint 1/", total_checkpoints)
		elif current_checkpoint == total_checkpoints:
			current_lap += 1
			current_checkpoint = 1
			print("Lap ", current_lap, "/", total_laps, " completed!")
			if current_lap >= total_laps:
				print("Race Finished!")
				print("Race finished in: ", "%.2f" % race_timer)
			else:
				print("Lap finished in: ", "%.2f" % lap_timer, "seconds!")
				race_timer += lap_timer
				lap_timer = 0.0
				print("Starting lap ", current_lap + 1, " - next: checkpoint 1")
		else:
			print("Must complete all checkpoints before returning to start!")
	elif num == current_checkpoint:
		current_checkpoint += 1
		print("Checkpoint ", num, " completed! Next: ", 
			"checkpoint " + str(current_checkpoint) if current_checkpoint < total_checkpoints else "finish line")
	else:
		print("Wrong checkpoint! Expected ", current_checkpoint, " got ", num)
