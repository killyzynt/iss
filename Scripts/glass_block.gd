class_name GlassBlock
extends MasterBlock

signal block_destroyed(block_ref: Node)

enum BlockColor { RED, BLUE, PURPLE, DARK_PURPLE }
@export var assigned_block_color: BlockColor = BlockColor.RED

var max_thickness: float 
var max_speed: float      
var speed: float
var base_health: float
var active_health: float
var block_color: String = "none"
var local_speed_override: float = 0.0
var local_health_override: float = 0.0
var wave_index_ref: int = 1
var purple_custom_speed_start: float = 0.0
var purple_custom_scale_target: Vector3 = Vector3.ONE
var glass_density: float = 1.0
var size: Dictionary = {}

@onready var block_effects = get_node_or_null("GlassBlockEffects")

func _ready() -> void:
	if super.has_method("_ready"):
		super._ready()
	if local_health_override == 0.0 and local_speed_override == 0.0:
		initialize_special_traits()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if block_effects == null and is_inside_tree():
		print("[Warning] GlassBlockEffects missing from GlassBlock node: ", name)

func configure_glass_block(passed_speed: float, passed_hp: float, wave_index: int, color_override: String = "") -> void:
	self.local_speed_override = passed_speed
	self.local_health_override = passed_hp
	self.wave_index_ref = wave_index
	if not color_override.is_empty():
		assigned_block_color = GlassBlockColors.parse_color_string(color_override) as BlockColor
	initialize_special_traits()
	
func take_damage(amount: float) -> void:
	if is_dying or amount <= 0.0: return
	active_health -= amount
	
	var label = get_node_or_null("HealthDisplayOverlay") as Label3D
	if label: label.text = "HP: %.1f" % [max(0.0, active_health)]
	
	if active_health <= 0.0:
		trigger_block_destruction_sequence()
		return

	var color_int: int = int(assigned_block_color)
	
	var starting_speed: float = GlassBlockConfig.RED_BASE_SPEED
	if color_int == 1: starting_speed = GlassBlockConfig.BLUE_BASE_SPEED
	elif color_int == 2: starting_speed = GlassBlockConfig.PURPLE_BASE_SPEED
	elif color_int == 3: starting_speed = GlassBlockConfig.DARK_PURPLE_BASE_SPEED
	
	if local_speed_override > 0.0:
		starting_speed = local_speed_override

	var calculated_thickness: float = GlassBlockColors.calculate_thickness(
		color_int, active_health, base_health, 
		GlassBlockConfig.RED_BASE_THICKNESS, GlassBlockConfig.RED_BASE_HP, 
		GlassBlockConfig.BLUE_BASE_THICKNESS, GlassBlockConfig.BLUE_BASE_HP, 
		self.max_thickness
	)
	
	var spawn_thickness: float = GlassBlockColors.calculate_thickness(
		color_int, base_health, base_health, 
		GlassBlockConfig.RED_BASE_THICKNESS, GlassBlockConfig.RED_BASE_HP, 
		GlassBlockConfig.BLUE_BASE_THICKNESS, GlassBlockConfig.BLUE_BASE_HP, 
		self.max_thickness
	)
	
	var thickness_before_hit: float = GlassBlockColors.calculate_thickness(
		color_int, active_health + amount, base_health, 
		GlassBlockConfig.RED_BASE_THICKNESS, GlassBlockConfig.RED_BASE_HP, 
		GlassBlockConfig.BLUE_BASE_THICKNESS, GlassBlockConfig.BLUE_BASE_HP, 
		self.max_thickness
	)
	
	var speed_per_step: float = 0.05
	if color_int == 1: speed_per_step = 0.02
	elif color_int == 2: speed_per_step = 0.036  
	elif color_int == 3: speed_per_step = 0.031   
	
	var thickness_lost: float = maxf(0.0, spawn_thickness - calculated_thickness)
	var steps_lost: float = thickness_lost / 0.01
	var speed_gained: float = steps_lost * speed_per_step
	
	self.speed = clampf(starting_speed + speed_gained, starting_speed, self.max_speed)
	var delta_thickness: float = maxf(0.0, thickness_before_hit - calculated_thickness)
	
	if block_effects and block_effects.has_method("update_visual_thickness"):
		block_effects.update_visual_thickness(true)
	
	print("[HIT REG] Color: %s | HP: %.1f/%.1f | Thickness: %.3f (Shredded: %.4f) | Speed: %.2f/%.2f" % [
		block_color, active_health, base_health, calculated_thickness, delta_thickness, self.speed, self.max_speed
	])
func initialize_special_traits() -> void:
	self.block_type = "glass"
	
	if self.block_color != "":
		self.assigned_block_color = GlassBlockColors.parse_color_string(self.block_color) as BlockColor
		
	var color_int: int = int(assigned_block_color)
	var is_fused: bool = (color_int == 2 or color_int == 3)
	
	if color_int == 0: 
		self.block_color = "red"
		self.max_thickness = GlassBlockConfig.RED_MAX_THICKNESS 
	elif color_int == 1: 
		self.block_color = "blue"
		self.max_thickness = GlassBlockConfig.BLUE_MAX_THICKNESS 
	elif color_int == 2: 
		self.block_color = "purple"
		self.max_thickness = GlassBlockConfig.PURPLE_MAX_THICKNESS
	elif color_int == 3: 
		self.block_color = "dark_purple"
		self.max_thickness = GlassBlockConfig.DARK_PURPLE_MAX_THICKNESS
	
	self.glass_density = 1.0 
	
	var native_scene_hp: float = self.active_health
	if native_scene_hp <= 0.0:
		native_scene_hp = GlassBlockConfig.RED_BASE_HP if color_int == 0 else GlassBlockConfig.BLUE_BASE_HP
		if color_int == 2: native_scene_hp = GlassBlockConfig.PURPLE_BASE_HP
		elif color_int == 3: native_scene_hp = GlassBlockConfig.DARK_PURPLE_BASE_HP
	
	var native_scene_speed: float = self.speed
	if native_scene_speed <= 0.0:
		native_scene_speed = GlassBlockConfig.RED_BASE_SPEED if color_int == 0 else GlassBlockConfig.BLUE_BASE_SPEED
		if color_int == 2: native_scene_speed = GlassBlockConfig.PURPLE_BASE_SPEED
		elif color_int == 3: native_scene_speed = GlassBlockConfig.DARK_PURPLE_BASE_SPEED
	
	if color_int == 0: self.max_speed = GlassBlockConfig.RED_MAX_SPEED
	elif color_int == 1: self.max_speed = GlassBlockConfig.BLUE_MAX_SPEED
	elif color_int == 2: self.max_speed = GlassBlockConfig.PURPLE_MAX_SPEED
	elif color_int == 3: self.max_speed = GlassBlockConfig.DARK_PURPLE_MAX_SPEED
	
	var baseline_hp: float = native_scene_hp
	if local_health_override > 0.0:
		baseline_hp = local_health_override
		
	if is_fused:
		self.base_health = local_health_override if local_health_override > 0.0 else native_scene_hp
	else:
		self.base_health = baseline_hp + ((max(0, wave_index_ref - 1)) * 1.0)
		
	if color_int == 0: self.base_health = clampf(self.base_health, 0.1, GlassBlockConfig.RED_MAX_HP)
	elif color_int == 1: self.base_health = clampf(self.base_health, 0.1, GlassBlockConfig.BLUE_MAX_HP)
	elif color_int == 2: self.base_health = clampf(self.base_health, 0.1, GlassBlockConfig.PURPLE_MAX_HP)
	elif color_int == 3: self.base_health = clampf(self.base_health, 0.1, GlassBlockConfig.DARK_PURPLE_MAX_HP)
		
	self.active_health = self.base_health
	
	self.speed = local_speed_override if local_speed_override > 0.0 else native_scene_speed
	self.speed = clamp(self.speed, 0.1, self.max_speed)
	
	var true_thickness: float = GlassBlockColors.calculate_thickness(
		color_int, active_health, base_health, 
		GlassBlockConfig.RED_BASE_THICKNESS, GlassBlockConfig.RED_BASE_HP, 
		GlassBlockConfig.BLUE_BASE_THICKNESS, GlassBlockConfig.BLUE_BASE_HP, 
		self.max_thickness
	)
	
	var mesh_node = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_node and mesh_node.mesh is BoxMesh: 
		mesh_node.mesh = mesh_node.mesh.duplicate()
		mesh_node.mesh.size.z = 1.0
		# 🟢 FIXED: Create a completely UNIQUE material copy on frame one so blocks don't share textures!
		var native_material: StandardMaterial3D = GlassBlockColors.generate_glass_material(self.block_color, true_thickness)
		mesh_node.material_override = native_material.duplicate()
		
	var collision_node = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_node and collision_node.shape is BoxShape3D: 
		collision_node.shape = collision_node.shape.duplicate(true)
		collision_node.shape.size.z = 1.0
		
	size = {"name": "fused_block" if is_fused else "base_block", "thickness": true_thickness, "max_health": base_health, "active_health": active_health}
	if "health" in self: self.health = self.base_health
	
	if color_int == 3:
		self.collision_layer = (1 << 0) | (1 << 1); self.collision_mask = (1 << 0) | (1 << 1)
	elif color_int == 2:
		self.collision_layer = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3); self.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
		
	PhysicsServer3D.call_deferred("set_active", true)

	if not is_fused:
		if block_effects and block_effects.has_method("play_birth_pop"):
			block_effects.play_birth_pop(true_thickness)
	else:
		self.scale.x = 1.0
		self.scale.y = 1.0
		self.scale.z = true_thickness


func _on_area_entered(incoming_area: Area3D) -> void:
	if is_dying or ("is_dying" in incoming_area and incoming_area.is_dying): return
	if incoming_area is GlassBlock:
		var handled_merge: bool = false
		var target_color: String = ""
		
		if assigned_block_color == BlockColor.RED and incoming_area.assigned_block_color == BlockColor.BLUE:
			target_color = "purple"; handled_merge = true
		elif assigned_block_color == BlockColor.BLUE and incoming_area.assigned_block_color == BlockColor.RED:
			target_color = "purple"; handled_merge = true
		elif assigned_block_color == BlockColor.PURPLE and incoming_area.assigned_block_color == BlockColor.PURPLE:
			if self.get_instance_id() < incoming_area.get_instance_id():
				target_color = "dark_purple"; handled_merge = true
		elif assigned_block_color == BlockColor.RED and incoming_area.assigned_block_color == BlockColor.PURPLE:
			target_color = "dark_purple"; handled_merge = true
		elif assigned_block_color == BlockColor.PURPLE and incoming_area.assigned_block_color == BlockColor.RED:
			target_color = "dark_purple"; handled_merge = true
		elif assigned_block_color == BlockColor.BLUE and incoming_area.assigned_block_color == BlockColor.PURPLE:
			target_color = "dark_purple"; handled_merge = true
		elif assigned_block_color == BlockColor.PURPLE and incoming_area.assigned_block_color == BlockColor.BLUE:
			target_color = "dark_purple"; handled_merge = true
				
		# --- LEVEL 3: 🛡️ DARK PURPLE ABSORPTION GATE ---
		elif assigned_block_color == BlockColor.DARK_PURPLE and (incoming_area.assigned_block_color == BlockColor.RED or incoming_area.assigned_block_color == BlockColor.BLUE):
			incoming_area.is_dying = true 
			
			self.active_health += incoming_area.active_health
			self.base_health += incoming_area.base_health
			
			# 🟢 FIXED: Capitalized and linked constants straight to GlassBlockConfig
			self.active_health = clampf(self.active_health, 0.1, GlassBlockConfig.DARK_PURPLE_MAX_HP)
			self.base_health = clampf(self.base_health, 0.1, GlassBlockConfig.DARK_PURPLE_MAX_HP)
			
			var color_int: int = int(assigned_block_color)
			var computed_thickness: float = GlassBlockColors.calculate_thickness(
				color_int, self.active_health, self.base_health, 
				GlassBlockConfig.RED_BASE_THICKNESS, GlassBlockConfig.RED_BASE_HP, 
				GlassBlockConfig.BLUE_BASE_THICKNESS, GlassBlockConfig.BLUE_BASE_HP, 
				self.max_thickness
			)
			
			if block_effects and block_effects.has_method("play_fusion_wobble"):
				block_effects.play_fusion_wobble(computed_thickness)
				
			incoming_area.queue_free()
			return

		# Handle standard color merge creations
		if handled_merge and not target_color.is_empty():
			incoming_area.is_dying = true
			self.is_dying = true
			
			var factory_node = get_parent()
			if factory_node and factory_node.has_method("build_enemy_block"):
				var combined_hp: float = self.active_health + incoming_area.active_health
				var combined_speed: float = minf(self.speed, incoming_area.speed)
				
				# Spawn the new fused block resource scene onto the track lanes
				var fused_instance = factory_node.call(
					"build_enemy_block", null, wave_index_ref, combined_speed, 
					target_color, 1, combined_hp, "glass"
				) as Area3D
				
				if fused_instance:
					fused_instance.global_position = self.global_position
					factory_node.add_child(fused_instance)
					
			incoming_area.queue_free()
			self.queue_free()


func trigger_block_destruction_sequence() -> void:
	if is_dying: return
	is_dying = true
	block_destroyed.emit(self)
	
	if block_effects and block_effects.has_method("spawn_destruction_shards"):
		block_effects.spawn_destruction_shards()
		
	# 🟢 GLOBAL AUTOLOAD ARCADE Payout
	var color_int: int = int(assigned_block_color)
	var point_reward: int = 100 
	
	if color_int == 2: point_reward = 300      
	elif color_int == 3: point_reward = 600   
	
	if has_node("/root/ScoreManager"):
		get_node("/root/ScoreManager").current_score += point_reward
		print("[SCORE ENGINE] Total Points: ", get_node("/root/ScoreManager").current_score)
		
	queue_free()
