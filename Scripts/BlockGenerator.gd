class_name BlockGenerator
extends Node

func build_enemy_block(base_scene: PackedScene, wave_count: int, baseline_speed: float, file_name: String, wave_length: int, hp_scaler: float, material_category_string: String = "glass") -> Area3D:
	if base_scene == null: 
		return null
	
	var obstacle_instance = base_scene.instantiate() as Area3D
	var lower_material: String = material_category_string.to_lower().strip_edges()
	obstacle_instance.name = "%s_W%d" % [file_name, wave_count]
	
	# 🟢 THE INSTANCE INJECTION FIX:
	# Instead of guessing the internal enum structures of GlassBlock from the outside,
	# we write the string data straight to properties or fallback meta containers.
	if "block_color" in obstacle_instance:
		var check_name: String = file_name.to_lower()
		if check_name.contains("dark"):
			obstacle_instance.block_color = "dark_purple"
		elif check_name.contains("purple"):
			obstacle_instance.block_color = "purple"
		elif check_name.contains("blue"):
			obstacle_instance.block_color = "blue"
		else:
			obstacle_instance.block_color = "red"
			
	if "block_type" in obstacle_instance:
		obstacle_instance.block_type = lower_material

	if obstacle_instance is GlassBlock:
		obstacle_instance.local_speed_override = baseline_speed
		obstacle_instance.local_health_override = hp_scaler
		obstacle_instance.wave_index_ref = wave_count
		
		# 🧠 Runs initialize_special_traits() where GlassBlock will handle mapping 
		# its own internal enums using the block_color string we passed above!
		obstacle_instance.initialize_special_traits()
	else:
		if "assigned_material_type" in obstacle_instance:
			obstacle_instance.set("assigned_material_type", lower_material)
		if "movement_speed" in obstacle_instance:
			obstacle_instance.set("movement_speed", baseline_speed)
			
	var detector_node = CombatDetector.new()
	detector_node.name = "CombatDetector"
	obstacle_instance.add_child(detector_node)
	
	var hp_label = Label3D.new()
	hp_label.name = "HealthDisplayOverlay"
	
	# Grab active_health AFTER running initialize_special_traits() 
	# so it captures the new +1.0 health per wave multiplier cleanly
	var live_hp: float = 1.0
	if obstacle_instance is GlassBlock:
		live_hp = obstacle_instance.active_health
	else:
		live_hp = obstacle_instance.get("active_health") if "active_health" in obstacle_instance else 1.0
		
	hp_label.text = "HP: %.1f" % [live_hp]
	
	hp_label.pixel_size = 0.005
	hp_label.position = Vector3(0.0, 1.5, 0.0)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.modulate = Color(1.0, 1.0, 1.0)
	obstacle_instance.add_child(hp_label)
	
	# Fetch the integer value safely for tracking logs without breaking compilation
	var tracking_color_id: int = 0
	if "assigned_block_color" in obstacle_instance:
		tracking_color_id = int(obstacle_instance.assigned_block_color)
		
	print("[SPAWN CHECK] Block: %s | Material: %s | Color Enum ID: %d | Starting HP: %.1f" % [
		obstacle_instance.name, lower_material, tracking_color_id, live_hp
	])

	return obstacle_instance
