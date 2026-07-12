class_name MasterBlock
extends Area3D

var block_type: String = "standard"

var is_dying: bool = false
var despawn_z_limit: float = 10.0
var _starting_z_scale: float = 1.0
var _last_safe_coordinates: Vector3 = Vector3.ZERO

func _ready() -> void:
	_starting_z_scale = scale.z
	initialize_special_traits()

func initialize_special_traits() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_dying: return
	if is_inside_tree(): 
		_last_safe_coordinates = global_position
	
	var current_speed: float = self.get("speed") if "speed" in self else 1.0
	global_position.z -= current_speed * delta
	
	var space_state = get_world_3d().direct_space_state
	var current_thickness = _starting_z_scale if _starting_z_scale > 0.0 else scale.z
	
	var ray_start = global_position
	var ray_end = global_position + Vector3(0, 0, -(current_thickness * 0.5 + 0.5))

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result = space_state.intersect_ray(query)
	if result and result.collider is MasterBlock:
		var front_block = result.collider as MasterBlock
		if not front_block.is_dying and global_position.z > front_block.global_position.z:
			if self.has_method("handle_block_impact"):
				self.handle_block_impact(front_block)

	if global_position.z < -despawn_z_limit:
		queue_free()

func take_damage(amount: float) -> void:
	if is_dying or amount <= 0.0: return
	
	if "active_health" in self:
		self.set("active_health", self.get("active_health") - amount)
		
		var current_active_hp: float = self.get("active_health")
		var label = get_node_or_null("HealthDisplayOverlay") as Label3D
		if label:
			label.text = "HP: %.1f" % [max(0.0, current_active_hp)]
		
		if current_active_hp <= 0.0:
			destroy_block()
			return
			
		update_visual_thickness()
	else:
		destroy_block()

func destroy_block() -> void:
	if is_dying: return
	is_dying = true
	
	var fallback_score: float = self.get("base_health") if "base_health" in self else 1.0
	var score_reward: int = clampi(int(fallback_score), 1, 9999)
	
	var current_scene_root = get_tree().current_scene
	if current_scene_root and current_scene_root.has_method("add_score_points"):
		current_scene_root.call("add_score_points", score_reward)
		print("[MASTER BLOCK] Awarded +%d points from master destruction routine" % score_reward)
	
	if self.has_method("execute_material_destruction"):
		self.execute_material_destruction()
		
	queue_free()

func update_visual_thickness() -> void:
	pass

func handle_block_impact(_target: MasterBlock) -> void:
	pass

func execute_material_destruction() -> void:
	pass
	
func configure_block(data: Dictionary) -> void:
	pass
