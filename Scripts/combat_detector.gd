class_name CombatDetector
extends Node3D

var host: MasterBlock = null

func _ready() -> void:
	# Reference the main moving block this detector component is attached to
	host = get_parent() as MasterBlock

func _physics_process(delta: float) -> void:
	if host == null or host.is_dying:
		return
		
	# Calculate exactly how far this block will jump on this physics frame tick
	var frame_jump: float = host.speed * delta
	
	# Project the target search vector straight forward down the lane axis (-Z direction)
	# Raycast reaches out slightly past the frame jump zone to capture incoming fusions early
	var target_vector: Vector3 = host.global_position + Vector3(0.0, 0.0, -(frame_jump + 1.5))
	
	var space_state = host.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(host.global_position, target_vector)
	
	# Configuration Layers: Set to listen to Layer 2 (Obstacles Layer)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [host.get_rid()] # Ignore our own active block collision boundaries
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return
		
	var hit_target = result.collider
	if hit_target == null or not "speed" in hit_target:
		return
	if "is_dying" in hit_target and hit_target.is_dying:
		return
		
	# PHYSICS GATING RULE: Only trigger impact logic if our block is traveling FASTER 
	# than the block ahead, catching it from behind down the tracking line.
	if host.speed > hit_target.speed:
		if host.has_method("handle_impact_as_attacker"):
			# PASS HANDSHAKE TO CODE: Hand over control directly to the specialized block
			# script to let it calculate its color fusions or shrapnel bursts.
			host.handle_impact_as_attacker(hit_target)
