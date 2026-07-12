class_name GlassBlockEffects
extends Node

@onready var parent_block = get_parent()
var scale_initialized: bool = false
var base_scale_x: float = 1.0
var base_scale_y: float = 1.0

var hit_tween: Tween
var merge_tween: Tween
var spawn_tween: Tween

@export var destruction_shards_pool: Array[PackedScene] = []


func _ready() -> void:
	if parent_block:
		if not parent_block.is_node_ready():
			await parent_block.ready
		
		initialize_visual_baselines()
		update_visual_thickness(false) # Initialize size silently on startup without a fake wobble

func initialize_visual_baselines() -> void:
	if parent_block == null or scale_initialized: return
	
	var color_int: int = int(parent_block.assigned_block_color)
	var is_fused: bool = (color_int == 2 or color_int == 3) # PURPLE = 2, DARK_PURPLE = 3
	
	base_scale_x = parent_block.purple_custom_scale_target.x if (is_fused and "purple_custom_scale_target" in parent_block) else parent_block.scale.x
	base_scale_y = parent_block.purple_custom_scale_target.y if (is_fused and "purple_custom_scale_target" in parent_block) else parent_block.scale.y
	scale_initialized = true

## Updates block thickness utilizing the clean 0.01 multiplier math library
func update_visual_thickness(trigger_wobble: bool = true) -> void:
	if parent_block == null or parent_block.is_dying: return
	
	var current_hp: float = parent_block.active_health if "active_health" in parent_block else 1.0
	var max_hp: float = parent_block.base_health if ("base_health" in parent_block and parent_block.base_health > 0.0) else 1.0
	var color_int: int = int(parent_block.assigned_block_color)
	
	# Fetch local metrics from parent variables with failsafe fallback drops
	var red_thick: float = GlassBlockConfig.RED_BASE_THICKNESS
	var red_hp: float = GlassBlockConfig.RED_BASE_HP
	var blue_thick: float = GlassBlockConfig.BLUE_BASE_THICKNESS
	var blue_hp: float = GlassBlockConfig.BLUE_BASE_HP
	var max_thick_limit: float = parent_block.max_thickness if ("max_thickness" in parent_block and parent_block.max_thickness != null) else 6.0
	
	# Call out to the static helper library module for unified 0.01 formula tracking
	var target_thickness: float = GlassBlockColors.calculate_thickness(
		color_int, current_hp, max_hp, 
		red_thick, red_hp, blue_thick, blue_hp, 
		max_thick_limit
	)

	if not scale_initialized:
		initialize_visual_baselines()

	# If we are loading at level spawn, snap properties instantly and skip tween animation logic
	if not trigger_wobble:
		# Keep parent root boundaries completely solid to shield colliders
		parent_block.scale.x = base_scale_x
		parent_block.scale.y = base_scale_y
		parent_block.scale.z = target_thickness
		
		var mesh_node = parent_block.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mesh_node:
			mesh_node.scale = Vector3(1.0, 1.0, 1.0)
		return

	# Play the impact squish loop if called via live projectile hits
	_execute_wobble_animation_track(target_thickness)


func _execute_wobble_animation_track(target_thickness: float) -> void:
	if parent_block == null: return
	var mesh_node = parent_block.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node == null: return

	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()

	# Ensure parent root depth matches live health metrics natively
	parent_block.scale.z = target_thickness

	# 🧮 DYNAMIC MOBILE-SAFE SPRING MULTIPLIERS
	var peak_1_mult: float = clampf(remap(target_thickness, 0.01, 6.5, 1.50, 1.10), 1.10, 1.50)
	var peak_2_mult: float = clampf(remap(target_thickness, 0.01, 6.5, 0.70, 0.95), 0.70, 0.95)
	
	hit_tween = create_tween()
	hit_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Peak 1: Squash and stretch outward inversely on bullet hit (Targeting mesh node scale matrix)
	hit_tween.tween_property(mesh_node, "scale:x", peak_1_mult, 0.05)
	hit_tween.parallel().tween_property(mesh_node, "scale:y", peak_1_mult, 0.05)
	hit_tween.parallel().tween_property(mesh_node, "scale:z", 0.6, 0.05)
	
	# Peak 2: Compression spring overshoot rebound
	hit_tween.tween_property(mesh_node, "scale:x", peak_2_mult, 0.06)
	hit_tween.parallel().tween_property(mesh_node, "scale:y", peak_2_mult, 0.06)
	hit_tween.parallel().tween_property(mesh_node, "scale:z", 1.3, 0.06)
	
	# Peak 3: Settle bounce drop cleanly back to current baselines (1.0 baseline proportions relative to parent scale)
	hit_tween.tween_property(mesh_node, "scale:x", 1.0, 0.08)
	hit_tween.parallel().tween_property(mesh_node, "scale:y", 1.0, 0.08)
	hit_tween.parallel().tween_property(mesh_node, "scale:z", 1.0, 0.08)
	
	# Re-sync standard depth constraints across internal geometry containers upon completion
	hit_tween.tween_callback(func():
		var collision_node = parent_block.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision_node and collision_node.shape: 
			collision_node.shape.size.z = 1.0
			
		if mesh_node and mesh_node.mesh is BoxMesh:
			mesh_node.mesh.size.z = 1.0
	)
## --- ✨ EXPLOSIVE FUSION WOBBLE ENGINE ---
## Handles the juicy dynamic jelly-style visual bounce on the mesh layers upon block collision merges.
func play_fusion_wobble(final_thickness: float) -> void:
	if parent_block == null: return
	var mesh_node = parent_block.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node == null: return
	
	if not scale_initialized:
		initialize_visual_baselines()
		
	# Instantly snap parent depth to final merged baseline boundaries
	parent_block.scale.z = final_thickness
		
	# 1. Immediate Impact State: Splat wide out to the sides on mesh child layers
	mesh_node.scale = Vector3(2.2, 2.2, 0.15)
	
	if merge_tween and merge_tween.is_valid():
		merge_tween.kill()
		
	merge_tween = create_tween()
	merge_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Bounce 1: Snap tall and skinny, balloon deep forward on thickness depth
	merge_tween.tween_property(mesh_node, "scale:x", 0.4, 0.08)
	merge_tween.parallel().tween_property(mesh_node, "scale:y", 0.4, 0.08)
	merge_tween.parallel().tween_property(mesh_node, "scale:z", 1.8, 0.08)
	
	# Bounce 2: Counter-wobble wide again, crush thickness back down slightly
	merge_tween.tween_property(mesh_node, "scale:x", 1.4, 0.08)
	merge_tween.parallel().tween_property(mesh_node, "scale:y", 1.4, 0.08)
	merge_tween.parallel().tween_property(mesh_node, "scale:z", 0.6, 0.08)
	
	# Bounce 3: Smoothly settle straight down onto target non-distorted lane bounds (1.0 width/height)
	merge_tween.tween_property(mesh_node, "scale:x", 1.0, 0.12)
	merge_tween.parallel().tween_property(mesh_node, "scale:y", 1.0, 0.12)
	merge_tween.parallel().tween_property(mesh_node, "scale:z", 1.0, 0.12)
	
	merge_tween.tween_callback(func():
		var collision_node = parent_block.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision_node and collision_node.shape: 
			collision_node.shape.size.z = 1.0
			
		if mesh_node and mesh_node.mesh is BoxMesh:
			mesh_node.mesh.size.z = 1.0
	)

## --- ✨ BIRTH POP ENGINE ---
## Plays a scaling entrance pop animation when standard wave blocks are initialized on track lanes.
func play_birth_pop(final_thickness: float) -> void:
	if parent_block == null: return
	var mesh_node = parent_block.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node == null: return
	
	# Lock root bounds to intended metrics instantly
	parent_block.scale.z = final_thickness
	
	# Start visual mesh tiny on frame one
	mesh_node.scale = Vector3(0.10, 0.10, 0.10)
	
	if spawn_tween and spawn_tween.is_valid():
		spawn_tween.kill()
		
	spawn_tween = create_tween()
	spawn_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Pop 1: Pop out wide slightly on birth
	spawn_tween.tween_property(mesh_node, "scale:x", 1.3, 0.08)
	spawn_tween.parallel().tween_property(mesh_node, "scale:y", 1.3, 0.08)
	spawn_tween.parallel().tween_property(mesh_node, "scale:z", 1.3, 0.08)
	
	# Pop 2: Counter-squeeze slightly
	spawn_tween.tween_property(mesh_node, "scale:x", 0.9, 0.08)
	spawn_tween.parallel().tween_property(mesh_node, "scale:y", 0.9, 0.08)
	spawn_tween.parallel().tween_property(mesh_node, "scale:z", 0.9, 0.08)
	
	# Pop 3: Settle perfectly onto flat 1.0 scale internal layout
	spawn_tween.tween_property(mesh_node, "scale:x", 1.0, 0.12)
	spawn_tween.parallel().tween_property(mesh_node, "scale:y", 1.0, 0.12)
	spawn_tween.parallel().tween_property(mesh_node, "scale:z", 1.0, 0.12)
	
	spawn_tween.tween_callback(func():
		var collision_node = parent_block.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision_node and collision_node.shape: 
			collision_node.shape.size.z = 1.0
	)


## --- ✨ DYNAMIC DESTRUCTION SHARD ENGINE ---
## Adjusts the shard count, sizing metrics, and travel speeds dynamically based on block tier.
func spawn_destruction_shards() -> void:
	if parent_block == null: return
	print("[VFX] Spawning glass destruction fragments for: ", parent_block.name)
	
	if destruction_shards_pool.is_empty() or destruction_shards_pool == null:
		print("[VFX ERROR] No shard scene assigned in element slot 0 of the array pool!")
		return
		
	# FIXED Array Pointer Type Pass
	var packed_shard: PackedScene = destruction_shards_pool[0]
	var color_int: int = int(parent_block.assigned_block_color) if "assigned_block_color" in parent_block else 0
	
	# 📐 THE SPREAD MATRIX DEFINITIONS
	var total_shards_to_spawn: int = 7
	var custom_shard_scale: float = 1.0
	
	if color_int == 1: # 🔵 BLUE: Small but many!
		total_shards_to_spawn = 12
		custom_shard_scale = 0.5
	elif color_int == 0: # 🔴 RED: Bigger than blue, fewer in number!
		total_shards_to_spawn = 8
		custom_shard_scale = 1.0
	elif color_int == 2: # 🪻 PURPLE: Bigger than red, fewer in number!
		total_shards_to_spawn = 5
		custom_shard_scale = 1.5
	elif color_int == 3: # 🔮 DARK PURPLE: Massive, heavy chunks!
		total_shards_to_spawn = 3
		custom_shard_scale = 2.0

	# Execute the dynamic structural scattering loops
	for i in range(total_shards_to_spawn):
		if packed_shard:
			var shard_instance = packed_shard.instantiate() as Area3D
			if shard_instance:
				var current_scene = get_tree().current_scene
				if current_scene:
					current_scene.add_child(shard_instance)
					shard_instance.global_position = parent_block.global_position
					
					# Adding a tiny random variance to the 360 angle so the cluster looks organic
					var base_angle: float = (2.0 * 3.14159 / total_shards_to_spawn) * i
					var random_angle: float = base_angle + randf_range(-0.15, 0.15)
					
					if "direction" in shard_instance:
						shard_instance.direction = Vector3(cos(random_angle), 0.0, sin(random_angle)).normalized()
					
					# Pass layout scaling parameters directly to the instantiated object container
					shard_instance.scale = Vector3(custom_shard_scale, custom_shard_scale, custom_shard_scale)
					
					# Hand over colors and target metadata tags
					var source_color_str = parent_block.block_color if "block_color" in parent_block else "red"
					shard_instance.set_meta("source_color", source_color_str)
					shard_instance.set_meta("kinetic_weight", 1.0)
					
					# Execute its internal asset material shading passes
					if shard_instance.has_method("_apply_runtime_shard_color_and_tuning"):
						shard_instance.call("_apply_runtime_shard_color_and_tuning")
