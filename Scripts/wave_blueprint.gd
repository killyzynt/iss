@tool
class_name WaveBlueprint
extends Resource

@export var wave_name: String = "Wave"

# The absolute safety limit for block tracks
const MAX_WAVE_BLOCKS: int = 10

# =========================================================================
# 📦 DATA-DRIVEN BLOCK DISTRIBUTION POOL
# =========================================================================
@export_group("Wave Content Layout")

@export var total_blocks_to_spawn: int = 0:
	get:
		var running_total: int = 0
		for config in blocks_to_spawn_pool:
			if config:
				running_total += config.count_to_spawn
		return clampi(running_total, 0, MAX_WAVE_BLOCKS)

@export var blocks_to_spawn_pool: Array[WaveBlockConfig] = []:
	set(value):
		blocks_to_spawn_pool = value
		notify_property_list_changed()

# =========================================================================
# 📉 EASY BLOCK PACING CONTROLS
# =========================================================================
@export_group("Easy Block Pacing Controls")
@export_range(0.0, 1.0, 0.05, "suffix:%") var easy_blocks_percentage: float = 0.25
@export var min_easy_hp_multiplier: float = 0.3
@export var max_easy_hp_multiplier: float = 0.6

# =========================================================================
# ⚡ DYNAMIC PERCENTAGE MULTIPLIERS
# =========================================================================
@export_group("Universal Percentage Modifiers")

## 🟢 PERCENTAGE HEALTH SLIDER: 
## 100% means normal base health (e.g., 2 HP). 1000% shifts the decimal place entirely (shifting 2 HP straight to 20 HP!)
@export_range(0.1, 10.0, 0.05, "or_greater", "suffix:%") var universal_health_multiplier: float = 1.0

## 🟢 PERCENTAGE SPEED SLIDER: Scales the movement speed of all blocks during this wave.
@export_range(0.1, 5.0, 0.05, "or_greater", "suffix:%") var universal_speed_multiplier: float = 1.0
