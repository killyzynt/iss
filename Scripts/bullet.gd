extends Area3D

@export var bullet_speed: float = 40.0
@export var bullet_damage: float = 1.0
@export var despawn_z_limit: float = 60.0

@onready var laser_radar: RayCast3D = $LaserRadar

var _has_delivered_damage: bool = false

func _ready() -> void:
	# FIXED: Forces the damage back to 1.0 at runtime, completely wiping out old Inspector overrides
	bullet_damage = 1.0

func _physics_process(delta: float) -> void:
	if _has_delivered_damage: 
		return
		
	var frame_distance: float = bullet_speed * delta
	
	if laser_radar:
		laser_radar.target_position = Vector3(0.0, 0.0, -(frame_distance + 1.5))
		laser_radar.force_raycast_update()
		
		if laser_radar.is_colliding():
			var hit_target = laser_radar.get_collider()
			if hit_target and hit_target.has_method("take_damage"):
				_apply_safe_damage(hit_target)
				return

	global_position.z += frame_distance

	if global_position.z > despawn_z_limit:
		queue_free()

func _apply_safe_damage(target: Node) -> void:
	if _has_delivered_damage:
		return
		
	_has_delivered_damage = true
	
	if laser_radar:
		laser_radar.enabled = false
		laser_radar.clear_exceptions()
		
	var bullet_collider = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if bullet_collider:
		bullet_collider.disabled = true
	
	print("[BULLET HIT] Target: %s | Base Damage: %.1f | Target Starting HP: %.1f" % [target.name, bullet_damage, target.get("active_health") if "active_health" in target else 0.0])
	
	if target.has_method("take_damage"):
		target.take_damage(bullet_damage)
	
	set_physics_process(false) 
	queue_free()
