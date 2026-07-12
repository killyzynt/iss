@tool # 🟢 Allows editing actions to push signals up to the master blueprint layout
class_name WaveBlockConfig
extends Resource

# 🟢 THE BALANCING SLIDER MATRIX
enum SpawnPriority {
	LOW_PRIORITY = 1,
	NORMAL = 2,
	HIGH_PRIORITY = 4,
	MAX_BIAS = 8
}

## Drag your Red, Blue, or future custom block .tscn scene file directly into this slot.
@export var block_scene: PackedScene

## Type exactly how many copies of this specific block should spawn during this wave.
@export var count_to_spawn: int = 4:
	set(value):
		count_to_spawn = max(0, value) # Prevents negative entries
		# Push an update alert out to the editor environment cache
		emit_changed()

## 🟢 CHOOSE THE CORE BIAS FOR THIS BLOCK TYPING
## If all color blocks are set to the same bias (like NORMAL or MAX_BIAS), they cancel each other out
## and divide your 10-block wave limit down into a clean 50/50 ratio!
@export var spawn_bias_weight: SpawnPriority = SpawnPriority.NORMAL:
	set(value):
		spawn_bias_weight = value
		emit_changed()
