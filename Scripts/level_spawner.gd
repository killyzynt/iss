class_name LevelSpawner
extends Node3D

@export_group("Required Links")
@export var blocks_generator_node: BlockGenerator

@export_group("Timeline Progression Control")
@export var wave_timeline: Array[Resource] = []

var lanes: Array[float] = [-2.0, 0.0, 2.0]
var current_wave: Dictionary = {}
var current_step_index: int = 0

var time_accumulated: float = 0.0
var base_spawn_gap: float = 1.0 
var current_spawn_gap: float = 1.0
var wave_count_completed: int = 0

var active_wave_speed_multiplier: float = 1.0
var active_wave_health_multiplier: float = 1.0

func _ready() -> void:
	current_spawn_gap = base_spawn_gap
	wave_count_completed = 0
	current_step_index = 0
	_generate_procedural_wave()

func _physics_process(delta: float) -> void:
	if blocks_generator_node: 
		_track_time_clock(delta)

func _track_time_clock(delta: float) -> void:
	time_accumulated += delta
	if time_accumulated >= current_spawn_gap:
		time_accumulated = 0.0
		_process_spawn_trigger()

func _process_spawn_trigger() -> void:
	# 🟢 CONTINUITY LOOKUP GATES: 
	# If the current wave cache is empty or we have processed every single index step item,
	# we intercept the code frame immediately to prevent null index crashes.
	if current_wave.is_empty() or current_step_index >= current_wave["lanes"].size():
		# Safety fallback check: If we are resting in between waves, stop the spawn clock timer
		return
	
	var lane_x: float = current_wave["lanes"][current_step_index]
	var target_scene: PackedScene = current_wave["scenes_linked"][current_step_index]
	
	if target_scene == null:
		print("[SPAWNER WARNING] Skipped spawn frame at step ", current_step_index, " because target_scene was Nil.")
		current_step_index += 1
		_check_wave_completion_state() # Ensure we check if this was the last block item
		return
	
	var blueprint_speed: float = current_wave["local_speeds"][current_step_index]
	var rolled_speed: float = (blueprint_speed * active_wave_speed_multiplier) if blueprint_speed > 0.0 else 0.0
	
	var blueprint_hp: float = current_wave["local_hps"][current_step_index]
	var rolled_hp: float = (blueprint_hp * active_wave_health_multiplier) if blueprint_hp > 0.0 else 0.0
	
	var file_name: String = target_scene.resource_path.get_file().get_basename()
	var target_material: String = current_wave["material_types"][current_step_index]
	
	# Pass the final unpacked values down to the block factory builder node
	var block_instance = blocks_generator_node.build_enemy_block(
		target_scene, wave_count_completed, rolled_speed, 
		file_name, current_wave["lanes"].size(), rolled_hp, target_material
	) as Area3D
	
	if block_instance:
		block_instance.position = Vector3(lane_x, 1.1, global_position.z)
		
		# 🟢 FIXED PATH: Spawn blocks directly into the active world root tree 
		# so they align perfectly with your player's targeting coordinates.
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.add_child(block_instance)
		else:
			add_child(block_instance) # Safe fallback straight to the spawner node
			
		current_spawn_gap = randf_range(0.5, 1.5)
		
	current_step_index += 1
	_check_wave_completion_state()

## 🟢 NEW SUB-ROUTINE: Evaluates if the current wave timeline has completed its distribution sequence.
## If it finishes, it pauses for a balanced arcade rest window, then automatically builds the next level map!
func _check_wave_completion_state() -> void:
	if current_step_index >= current_wave["lanes"].size():
		print("[LEVEL SYSTEM] Wave ", wave_count_completed, " block distribution completely finished!")
		
		# Reset our tracker variables cleanly
		current_wave = {}
		time_accumulated = 0.0
		
		# Set your desired arcade rest time gap in seconds between waves (e.g., 4.0 seconds)
		var rest_between_waves: float = 4.0
		current_spawn_gap = rest_between_waves
		
		# Create an asynchronous engine callback timer to trigger your next procedural wave sequence safely
		get_tree().create_timer(rest_between_waves).timeout.connect(func():
			_generate_procedural_wave()
		)
func _generate_procedural_wave() -> void:
	wave_count_completed += 1
	current_step_index = 0
	current_wave = {"lanes":[], "scenes_linked":[], "local_speeds":[], "local_hps":[], "material_types":[]}
	
	var current_scene_root = get_tree().current_scene
	if current_scene_root and current_scene_root.has_method("save_game_progression"):
		current_scene_root.call("save_game_progression", wave_count_completed)
		
	var current_idx: int = wave_count_completed - 1
	var is_endless: bool = current_idx >= wave_timeline.size()
	
	# 🟢 FIXED TIMELINE ARCHITECTURE LAYER:
	# Enforces clean, hard data anchoring. If your timeline contains files, 
	# it is physically impossible to fall back into a blank empty WaveBlueprint copy!
	var active_blueprint: WaveBlueprint = null
	
	if not wave_timeline.is_empty():
		if not is_endless:
			# Standard progression loop matching your custom campaign maps
			active_blueprint = wave_timeline[current_idx] as WaveBlueprint
		else:
			# 🔄 Endless mode seamlessly reuse the blueprint slots you hand-crafted
			var picked_res = wave_timeline.pick_random()
			if picked_res is WaveBlueprint:
				active_blueprint = picked_res
	
	# Failsafe gate if the timeline manager array itself was left totally blank
	if active_blueprint == null:
		print("[SPAWNER CRITICAL WARNING] wave_timeline array is completely empty! Add a blueprint .tres file asset.")
		active_blueprint = WaveBlueprint.new()
		active_blueprint.easy_blocks_percentage = 0.25
		
	# Synchronize active blueprint multipliers cleanly across all continuous loops
	active_wave_speed_multiplier = active_blueprint.universal_speed_multiplier
	active_wave_health_multiplier = active_blueprint.universal_health_multiplier

	# 🧮 1. EXTRACT DATA-DRIVEN SCENES (PRIORITY WEIGHT BIAS ENGINE)
	var temporary_oversized_pool: Array[PackedScene] = []
	
	if !active_blueprint.blocks_to_spawn_pool.is_empty():
		for block_config in active_blueprint.blocks_to_spawn_pool:
			if block_config and block_config.block_scene != null:
				var priority_multiplier: int = 2
				if "spawn_bias_weight" in block_config:
					priority_multiplier = int(block_config.spawn_bias_weight)
					if priority_multiplier <= 0: priority_multiplier = 2
					
				var total_tickets_in_bag: int = block_config.count_to_spawn * priority_multiplier
				
				for count in range(total_tickets_in_bag):
					temporary_oversized_pool.append(block_config.block_scene)
			else:
				print("[BLUEPRINT WARNING] Found an unassigned asset link slot inside your blueprint array config.")
					
	if temporary_oversized_pool.is_empty():
		print("[SPAWNER CRITICAL] Wave blueprint contains zero valid block asset links. Re-check your inspector panel.")
		return

	# Shuffle the oversized deck completely to scatter priority bias items evenly across tracks
	temporary_oversized_pool.shuffle()

	# Slice the array down to fit your strict 10 maximum block lane cap cleanly
	var unpacked_wave_list: Array[PackedScene] = []
	var max_cap: int = 10 
	if "MAX_WAVE_BLOCKS" in active_blueprint:
		max_cap = active_blueprint.MAX_WAVE_BLOCKS

	for i in range(min(temporary_oversized_pool.size(), max_cap)):
		unpacked_wave_list.append(temporary_oversized_pool[i])

	var total_unpacked_count: int = unpacked_wave_list.size()
	if total_unpacked_count == 0: return

	# 🧮 2. RE-DETERMINE EXACT VOLUME COUNT MATRIX FOR EASY TARGETS
	var total_easy_blocks_allowed: int = roundi(total_unpacked_count * active_blueprint.easy_blocks_percentage)
	var easy_blocks_spawned_count: int = 0

	# Map out individual blocks inside the lane dictionary tracks
	var last_lane: float = -99.0
	for i in range(total_unpacked_count):
		var valid_lanes = lanes.duplicate()
		if last_lane != -99.0: 
			valid_lanes.erase(last_lane)
		last_lane = valid_lanes.pick_random() if !valid_lanes.is_empty() else 0.0
		
		var current_scene_file: PackedScene = unpacked_wave_list[i]
		var file_name: String = current_scene_file.resource_path.get_file().get_basename().to_lower()
		
		var block_base_hp: float = 0.0
		var block_base_speed: float = 0.0
		var structural_type_str: String = "glass"
		
		if file_name.contains("metal"): structural_type_str = "metal"
		elif file_name.contains("crystal"): structural_type_str = "crystal"

		# Instantiate a quick temporary background check object to parse native color enum IDs safely
		var color_int: int = 0
		var temp_state_check = current_scene_file.instantiate()
		if temp_state_check:
			if "assigned_block_color" in temp_state_check:
				color_int = int(temp_state_check.assigned_block_color)
			temp_state_check.queue_free()

		# Map data parameters from the static config file sheet constants
		var base_spawn_hp: float = GlassBlockConfig.RED_BASE_HP
		var base_spawn_speed: float = GlassBlockConfig.RED_BASE_SPEED
		# Also track the absolute maximum allowed health for this block color
		var max_allowed_hp: float = GlassBlockConfig.RED_MAX_HP
		
		if color_int == 1:
			base_spawn_hp = GlassBlockConfig.BLUE_BASE_HP
			base_spawn_speed = GlassBlockConfig.BLUE_BASE_SPEED
			max_allowed_hp = GlassBlockConfig.BLUE_MAX_HP
		elif color_int == 2:
			base_spawn_hp = GlassBlockConfig.PURPLE_BASE_HP
			base_spawn_speed = GlassBlockConfig.PURPLE_BASE_SPEED
			max_allowed_hp = GlassBlockConfig.PURPLE_MAX_HP
		elif color_int == 3:
			base_spawn_hp = GlassBlockConfig.DARK_PURPLE_BASE_HP
			base_spawn_speed = GlassBlockConfig.DARK_PURPLE_BASE_SPEED
			max_allowed_hp = GlassBlockConfig.DARK_PURPLE_MAX_HP

		# Step B: Layer on your unique Wave Blueprint Multipliers
		if active_wave_health_multiplier != 1.0:
			block_base_hp = base_spawn_hp * active_wave_health_multiplier
		else:
			block_base_hp = base_spawn_hp
			
		block_base_speed = base_spawn_speed * active_wave_speed_multiplier

		# Step C: Evaluate your Pacing Sliders (Nerfs specific blocks if they roll an easy target slot)
		if easy_blocks_spawned_count < total_easy_blocks_allowed:
			var hp_nerf: float = randf_range(active_blueprint.min_easy_hp_multiplier, active_blueprint.max_easy_hp_multiplier)
			block_base_hp = block_base_hp * hp_nerf
			easy_blocks_spawned_count += 1
		
		# Step D: THE GLOBAL PROGRESSION ADDITION
		# Always adds +1.0 HP per wave, layered perfectly on top of blueprint stats
		block_base_hp += float(wave_count_completed - 1) * 1.0

		block_base_hp = clampf(block_base_hp, 0.1, max_allowed_hp)

		# Pack the finalized values safely straight into the active lane maps
		current_wave["lanes"].append(last_lane)
		current_wave["scenes_linked"].append(current_scene_file)
		current_wave["local_speeds"].append(block_base_speed)
		current_wave["local_hps"].append(block_base_hp)
		current_wave["material_types"].append(structural_type_str)
	# 🔄 4. FINAL MAP SHUFFLE FOR LAYOUT UNPREDICTABILITY
	var shuffle_map: Array[int] = []
	for idx in range(total_unpacked_count): shuffle_map.append(idx)
	shuffle_map.shuffle()
	
	var shuffled_wave_workspace = {"lanes":[], "scenes_linked":[], "local_speeds":[], "local_hps":[], "material_types":[]}
	for shuffled_idx in shuffle_map:
		shuffled_wave_workspace["lanes"].append(current_wave["lanes"][shuffled_idx])
		shuffled_wave_workspace["scenes_linked"].append(current_wave["scenes_linked"][shuffled_idx])
		shuffled_wave_workspace["local_speeds"].append(current_wave["local_speeds"][shuffled_idx])
		shuffled_wave_workspace["shuffled_hps" if "shuffled_hps" in shuffled_wave_workspace else "local_hps"].append(current_wave["local_hps"][shuffled_idx])
		shuffled_wave_workspace["material_types"].append(current_wave["material_types"][shuffled_idx])
	
	current_wave = shuffled_wave_workspace
