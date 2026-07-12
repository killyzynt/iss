class_name RunnerPlayer
extends Node3D

@export_group("Lane Attributes")
@export var target_speed: float = 14.0
@export var horizontal_lane_step: float = 2.0

@export_group("Mobile Swipe Setup")
@export var minimum_swipe_threshold: float = 50.0

var lane_positions: Array[float] = [-2.0, 0.0, 2.0]
var current_lane_index: int = 1 

var touch_start_position: Vector2 = Vector2.ZERO
var is_tracking_swipe: bool = false

func _ready() -> void:
	global_position.x = lane_positions[current_lane_index]

func _input(event: InputEvent) -> void:
	# Query the options menu choice: 0 = ARROWS, 1 = SWIPE
	var current_control_mode: int = Engine.get_meta("control_type", 0)
	if current_control_mode != 1: 
		return # Block mobile swipes instantly if set to Arrows!

	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_position = event.position
			is_tracking_swipe = true
		else:
			if is_tracking_swipe:
				_evaluate_swipe_vector(event.position)
				is_tracking_swipe = false
				
	elif event is InputEventScreenDrag and is_tracking_swipe:
		var total_displacement = event.position - touch_start_position
		if total_displacement.length() >= minimum_swipe_threshold:
			_evaluate_swipe_vector(event.position)
			is_tracking_swipe = false 

func _physics_process(delta: float) -> void:
	# Query the options menu choice: 0 = ARROWS, 1 = SWIPE
	var current_control_mode: int = Engine.get_meta("control_type", 0)
	
	if current_control_mode == 0:
		# Only process button mappings or keyboard arrow triggers if set to Arrows mode
		if Input.is_action_just_pressed("ui_left"):
			_shift_lane(1)
		elif Input.is_action_just_pressed("ui_right"):
			_shift_lane(-1)
		
	# Smoothly slide your character to the target lane coordinate on screen
	var target_x: float = lane_positions[current_lane_index]
	global_position.x = lerp(global_position.x, target_x, target_speed * delta)

func _evaluate_swipe_vector(finger_current_position: Vector2) -> void:
	var swipe_vector: Vector2 = finger_current_position - touch_start_position
	if swipe_vector.length() < minimum_swipe_threshold: return
	
	if abs(swipe_vector.x) > abs(swipe_vector.y):
		var directional_shift: int = 1 if swipe_vector.x > 0.0 else -1
		_shift_lane(directional_shift)

func _shift_lane(lane_offset: int) -> void:
	var calculated_index: int = current_lane_index + lane_offset
	current_lane_index = clampi(calculated_index, 0, lane_positions.size() - 1)

func _on_hitbox_area_entered(incoming_area: Area3D) -> void:
	if incoming_area == null: return
	
	var target_to_test: Node = incoming_area
	var is_deadly_obstacle: bool = false
	
	for depth in range(3):
		if target_to_test == null: break
		if target_to_test.has_method("take_damage") or "assigned_color" in target_to_test:
			is_deadly_obstacle = true
			break
		target_to_test = target_to_test.get_parent()

	if is_deadly_obstacle:
		var current_scene_root = get_tree().current_scene
		if current_scene_root and current_scene_root.has_method("trigger_game_over"):
			print("[PLAYER] Lethal crash detected! Informing GameManager system loop...")
			current_scene_root.call("trigger_game_over")
