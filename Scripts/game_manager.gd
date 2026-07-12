extends Node3D

const HUD_SCENE = preload("res://PackedScenes/GameplayHUD.tscn")
const PAUSE_SCENE = preload("res://PackedScenes/PauseMenu.tscn")
const RETRY_SCENE = preload("res://PackedScenes/RetryMenu.tscn")
const SHARD_SCENE = preload("res://PackedScenes/GlassShards.tscn")
const BULLET_SCENE = preload("res://PackedScenes/bullet.tscn")

@export var mobile_input_resource: Resource

var current_player_score: int = 0
var all_time_best_score: int = 0 

var score_display_label: Label = null
var best_score_display_label: Label = null 

var is_game_active: bool = false
var is_paused: bool = false
const SAVE_FILE_PATH: String = "user://arcade_runner_save.dat"
var active_wave_number: int = 1

var hud_canvas_layer: CanvasLayer
var gameplay_hud: Control
var mobile_pause_button: Button

var pause_canvas_layer: CanvasLayer
var retry_canvas_layer: CanvasLayer

var pause_menu: Control
var resume_button: Button
var main_menu_button: Button

var retry_menu: Control
var retry_button: Button
var retry_exit_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 1. ALWAYS LOAD DISK STORAGE FIRST: This preserves high scores across total app restarts
	_load_game_progression_with_best_run()

	if HUD_SCENE != null:
		hud_canvas_layer = CanvasLayer.new()
		hud_canvas_layer.layer = 1 
		add_child(hud_canvas_layer)
		
		gameplay_hud = HUD_SCENE.instantiate() as Control
		hud_canvas_layer.add_child(gameplay_hud)
		gameplay_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		score_display_label = gameplay_hud.get_node_or_null("ScoreLabel") as Label
		if score_display_label == null:
			score_display_label = gameplay_hud.find_child("*Score*", true, false) as Label
			
		best_score_display_label = gameplay_hud.get_node_or_null("BestScoreLabel") as Label
		if best_score_display_label == null:
			best_score_display_label = gameplay_hud.find_child("*Best*", true, false) as Label
		if best_score_display_label == null:
			best_score_display_label = gameplay_hud.find_child("*High*", true, false) as Label
			
		mobile_pause_button = gameplay_hud.get_node_or_null("PauseButton") as Button
		if mobile_pause_button == null:
			mobile_pause_button = gameplay_hud.find_child("*Pause*", true, false) as Button
			
		if mobile_pause_button:
			mobile_pause_button.pressed.connect(func(): toggle_pause())

	if OS.has_feature("mobile") or OS.has_feature("editor"):
		if mobile_input_resource and mobile_input_resource.has_method("attach_mobile_controls"):
			mobile_input_resource.call("attach_mobile_controls", self)

	_warm_up_game_assets()
	start_new_game()
	_defer_menu_initialization()

func _warm_up_game_assets() -> void:
	if SHARD_SCENE != null:
		var fake_shard = SHARD_SCENE.instantiate() as Area3D
		if fake_shard:
			fake_shard.visible = false
			fake_shard.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(fake_shard)
			fake_shard.queue_free()
		
	if BULLET_SCENE != null:
		var fake_bullet = BULLET_SCENE.instantiate() as Area3D
		if fake_bullet:
			fake_bullet.visible = false
			fake_bullet.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(fake_bullet)
			fake_bullet.queue_free()

func _defer_menu_initialization() -> void:
	for i in range(10):
		await get_tree().process_frame
		
	if PAUSE_SCENE != null and pause_menu == null:
		pause_canvas_layer = CanvasLayer.new()
		pause_canvas_layer.layer = 10 
		pause_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(pause_canvas_layer)
		
		pause_menu = PAUSE_SCENE.instantiate() as Control
		pause_canvas_layer.add_child(pause_menu)
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		resume_button = pause_menu.get_node_or_null("VBoxContainer/ResumeGame")
		main_menu_button = pause_menu.get_node_or_null("VBoxContainer/MainMenu")
		if resume_button: resume_button.pressed.connect(func(): toggle_pause())
		if main_menu_button: main_menu_button.pressed.connect(func(): _on_main_menu_pressed())
		pause_canvas_layer.visible = false

	for i in range(10):
		await get_tree().process_frame

	if RETRY_SCENE != null and retry_menu == null:
		retry_canvas_layer = CanvasLayer.new()
		retry_canvas_layer.layer = 11
		retry_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(retry_canvas_layer)
		
		retry_menu = RETRY_SCENE.instantiate() as Control
		retry_canvas_layer.add_child(retry_menu)
		retry_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		retry_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		retry_button = retry_menu.get_node_or_null("VBoxContainer/RetryGame")
		retry_exit_button = retry_menu.get_node_or_null("VBoxContainer/MainMenu")
		if retry_button: retry_button.pressed.connect(func(): _on_retry_clicked())
		if retry_exit_button: retry_exit_button.pressed.connect(func(): _on_main_menu_pressed())
		retry_canvas_layer.visible = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and is_game_active:
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause() -> void:
	if not pause_canvas_layer: return
	
	is_paused = not is_paused
	pause_canvas_layer.visible = is_paused
	
	if mobile_pause_button:
		mobile_pause_button.visible = not is_paused
	
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Engine.time_scale = 0.0
		get_tree().paused = true
	else:
		Engine.time_scale = 1.0
		get_tree().paused = false

func start_new_game() -> void:
	is_game_active = true
	is_paused = false
	current_player_score = 0 
	
	# FIXED: Do not reset or re-read high scores here. Leave file data alone!
	update_score_ui()
	
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	if pause_canvas_layer: pause_canvas_layer.visible = false
	if retry_canvas_layer: retry_canvas_layer.visible = false
	if mobile_pause_button: mobile_pause_button.visible = true
		
	if has_node("/root/ProgressionTracker"):
		var tracker = get_node("/root/ProgressionTracker")
		active_wave_number = tracker.current_saved_wave
		
	var spawner = get_node_or_null("ObstacleSystem/LevelSpawner")
	if spawner and "wave_count_completed" in spawner:
		spawner.wave_count_completed = active_wave_number - 1
		spawner.current_step_index = 0
		spawner.current_wave.clear()
		if spawner.has_method("_generate_procedural_wave"):
			spawner.call("_generate_procedural_wave")

func save_game_progression(completed_wave_id: int) -> void:
	if not is_game_active: return
	active_wave_number = completed_wave_id
	
	if has_node("/root/ProgressionTracker"):
		get_node("/root/ProgressionTracker").set("current_saved_wave", active_wave_number)
		
	_write_save_file_to_user_folder()

func _write_save_file_to_user_folder() -> void:
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_32(active_wave_number)
		save_file.store_32(all_time_best_score)
		save_file.close()

func _load_game_progression_with_best_run() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if save_file:
			active_wave_number = save_file.get_32()
			if save_file.get_position() < save_file.get_length():
				all_time_best_score = save_file.get_32()
			save_file.close()

func trigger_game_over() -> void:
	if not is_game_active: return
	is_game_active = false
	
	if current_player_score > all_time_best_score:
		all_time_best_score = current_player_score
	
	_write_save_file_to_user_folder()
	
	if mobile_pause_button:
		mobile_pause_button.visible = false
		
	if retry_canvas_layer:
		retry_canvas_layer.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	Engine.time_scale = 0.0
	get_tree().paused = true

func _on_retry_clicked() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_timer_spawn_timeout() -> void:
	pass

func _on_bullet_area_entered(_area: Area3D) -> void:
	pass

func add_score_points(points_to_grant: int) -> void:
	if not is_game_active: return
	current_player_score += points_to_grant
	
	if current_player_score > all_time_best_score:
		all_time_best_score = current_player_score
		
	update_score_ui()

func update_score_ui() -> void:
	if score_display_label:
		score_display_label.text = "SCORE: %d" % current_player_score
		
	if best_score_display_label:
		best_score_display_label.text = "BEST: %d" % all_time_best_score
