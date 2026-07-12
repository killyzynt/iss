extends Node3D

@export var bullet_scene: PackedScene
@export var automatic_fire_rate: float = 5.0

var time_since_last_shot: float = 0.0

func _physics_process(delta: float) -> void:
	# Clamp to prevent division-by-zero crashes if set to 0
	var fire_frequency: float = maxf(0.01, automatic_fire_rate)
	# Converts frequency into an actual seconds-delay interval (e.g., 5.0 means every 0.2s)
	var required_delay: float = 1.0 / fire_frequency
	
	time_since_last_shot += delta
	if time_since_last_shot >= required_delay:
		time_since_last_shot = 0.0
		fire_projectile()

func fire_projectile() -> void:
	if bullet_scene == null:
		return
		
	var bullet_instance = bullet_scene.instantiate() as Area3D
	if bullet_instance:
		var spawn_root: Node = get_tree().current_scene
		if spawn_root:
			spawn_root.add_child(bullet_instance)
			bullet_instance.global_position = Vector3(
				self.global_position.x, 
				0.5,
				self.global_position.z
			)
