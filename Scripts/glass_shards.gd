extends Area3D

@export var speed: float = 15.0

var direction: Vector3 = Vector3.ZERO
var damage_multiplier: float = 1.0
var lifetime: float = 0.1
var is_visual_only: bool = false

var red_material: StandardMaterial3D = null
var blue_material: StandardMaterial3D = null
var purple_material: StandardMaterial3D = null

func _ready() -> void:
	if not area_entered.is_connected(_on_obstacle_impact):
		area_entered.connect(_on_obstacle_impact)
		add_to_group("shards")
		
	# Shards only need to look outward to hit blocks; they don't need to be tracked back
	self.set_deferred("monitorable", false)
	self.set_deferred("monitoring", true)
	
	# 🟢 KINETIC SHATTER BURST MECHANIC:
	# Instantly randomize speed and lifetime right at birth to simulate real glass breaking physics!
	self.speed = randf_range(28.0, 42.0)
	self.lifetime = randf_range(0.08, 0.16)
	
	_apply_runtime_shard_color_and_tuning()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _apply_runtime_shard_color_and_tuning() -> void:
	var mesh_node = get_node_or_null("MeshInstance3D") as MeshInstance3D
	var collision_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if mesh_node == null: return
		# --- UPDATE THESE 3 MATERIAL BLOCKS INSIDE GlassShard.gd ---
		# --- UPDATE THESE 3 MATERIAL BLOCKS INSIDE GlassShard.gd ---
	if red_material == null:
		red_material = StandardMaterial3D.new()
		red_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		
		# 🟢 TWO-SIDED RENDERING: Draws the inner layers of the shards so they look thick!
		red_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		
		red_material.roughness = 0.08
		red_material.metallic_specular = 1.0
		
		# Balanced HDR red profile
		red_material.albedo_color = Color(1.1, 0.02, 0.02, 0.82) 
		red_material.rim_enabled = true
		red_material.rim = 1.0
		red_material.rim_tint = 1.0
		red_material.emission_enabled = true
		red_material.emission = Color(0.45, 0.01, 0.01)
		
	if blue_material == null:
		blue_material = StandardMaterial3D.new()
		blue_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		blue_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		blue_material.roughness = 0.08
		blue_material.metallic_specular = 1.0
		
		# Boosted HDR electric blue profile
		blue_material.albedo_color = Color(0.0, 0.40, 1.8, 0.82)
		blue_material.rim_enabled = true
		blue_material.rim = 1.0
		blue_material.rim_tint = 1.0
		blue_material.emission_enabled = true
		blue_material.emission = Color(0.0, 0.20, 0.85)
		
	if purple_material == null:
		purple_material = StandardMaterial3D.new()
		purple_material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		purple_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		purple_material.roughness = 0.08
		purple_material.metallic_specular = 1.0
		
		# Matching cyber purple profile
		purple_material.albedo_color = Color(0.85, 0.02, 1.4, 0.85)
		purple_material.rim_enabled = true
		purple_material.rim = 1.0
		purple_material.rim_tint = 1.0
		purple_material.emission_enabled = true
		purple_material.emission = Color(0.35, 0.02, 0.55)

	var source_color: String = "red"
	if self.has_meta("source_color"): source_color = self.get_meta("source_color").to_lower()
	
	# Give debris fragments diverse, chaotic sizes (some tiny dust, some large chunks)
	var random_size: float = randf_range(0.2, 0.8)
	scale = Vector3(random_size, random_size, random_size)
	if collision_node: collision_node.scale = Vector3(random_size, random_size, random_size)
	
	if is_visual_only:
		mesh_node.set_surface_override_material(0, blue_material)
	elif source_color == "blue":
		mesh_node.set_surface_override_material(0, blue_material)
	elif source_color == "purple" or source_color == "dark_purple":
		mesh_node.set_surface_override_material(0, purple_material)
	else:
		mesh_node.set_surface_override_material(0, red_material)

func _on_obstacle_impact(area: Area3D) -> void:
	if is_visual_only:
		queue_free()
		return
		
	if area == null: return
	
	# Target the base block node directly
	var block_node = area
	if not ("assigned_block_color" in block_node):
		block_node = area.get_parent()
		if block_node == null or not ("assigned_block_color" in block_node): return
	
	if "is_dying" in block_node and block_node.is_dying: return
	var color_int: int = int(block_node.assigned_block_color)
	
	# --- LOOK FOR THE DAMAGE CALCULATION BLOCK INSIDE _on_obstacle_impact() ---
	
	# Fetch the target block's maximum structural health pool when it was born
	# We use 'base_health' as our reference, fallback to 10.0 if missing
	var max_spawn_health: float = block_node.base_health if "base_health" in block_node else 10.0
	
	# Pull metadata markers passed down from the parent block that spawned this shard
	var source_color: String = "red"
	if self.has_meta("source_color"): source_color = self.get_meta("source_color").to_lower()
	
	var inherited_shard_power: float = 1.0
	if self.has_meta("kinetic_weight"): inherited_shard_power = self.get_meta("kinetic_weight")
		
	# Blue shards are smaller and lighter, meaning they deal half structural damage natively
	var shard_type_modifier: float = 0.5 if source_color == "blue" else 1.0
	var final_inflicted_damage: float = 0.0
	
	# 🧮 PERCENTAGE-BASED ELEMENTAL DAMAGE MATRIX (Red=0, Blue=1, Purple=2, Dark=3)
	if color_int == 1: # 🔵 Blue Block: Shards instantly shave off 10% of its max health
		final_inflicted_damage = max_spawn_health * 0.10 * damage_multiplier * shard_type_modifier * inherited_shard_power
	elif color_int == 0: # 🔴 Red Block: Shards instantly shave off 15% of its max health
		final_inflicted_damage = max_spawn_health * 0.15 * damage_multiplier * shard_type_modifier * inherited_shard_power
	elif color_int == 2: # 🪻 Purple Block: Shards instantly shave off 20% of its max health
		final_inflicted_damage = max_spawn_health * 0.20 * damage_multiplier * shard_type_modifier * inherited_shard_power
	elif color_int == 3: # 🔮 Dark Purple Block: Shards instantly shave off 25% of its max health
		final_inflicted_damage = max_spawn_health * 0.25 * damage_multiplier * shard_type_modifier * inherited_shard_power
	else:
		final_inflicted_damage = max_spawn_health * 0.10 * damage_multiplier * shard_type_modifier * inherited_shard_power
		
	# Ensure the shard always inflicts at least a minimal 1.0 HP dent upon connection
	final_inflicted_damage = maxf(final_inflicted_damage, 1.0)
	
	# 💥 INFLICT DAMAGE ON TARGET
	if block_node.has_method("take_damage"):
		block_node.call("take_damage", final_inflicted_damage)
	else:
		# FALLBACK: Manually subtract health if the primary method is bypassed
		block_node.active_health -= final_inflicted_damage
		
		var effects_node = block_node.get_node_or_null("GlassBlockEffects")
		if effects_node and effects_node.has_method("update_visual_thickness"):
			effects_node.call("update_visual_thickness")
			
		if block_node.active_health <= 0.0:
			block_node.is_dying = true
			if block_node.has_method("trigger_block_destruction_sequence"):
				block_node.call("trigger_block_destruction_sequence")
			else:
				block_node.queue_free()
			
	queue_free()
