extends Control

@export_file("*.tscn") var gameplay_scene_path: String = "res://main.tscn"

# 🟢 PATH MAPPING SAFE FALLBACKS:
# We use get_node_or_null to allow the code to look at BOTH path setups ("MainButtons" or "VBoxContainer")
# so it never crashes your engine startup loop if you rename your nodes!
@onready var main_buttons_container: VBoxContainer = get_node_or_null("MainButtons") if has_node("MainButtons") else get_node_or_null("VBoxContainer")

@onready var start_button: Button = get_node_or_null("MainButtons/StartButton") if has_node("MainButtons") else get_node_or_null("VBoxContainer/StartButton")
@onready var continue_button: Button = get_node_or_null("MainButtons/ContinueButton") if has_node("MainButtons") else get_node_or_null("VBoxContainer/ContinueButton")
@onready var options_button: Button = get_node_or_null("MainButtons/OptionsButton") if has_node("MainButtons") else get_node_or_null("VBoxContainer/OptionsButton")
@onready var exit_button: Button = get_node_or_null("MainButtons/ExitButton") if has_node("MainButtons") else get_node_or_null("VBoxContainer/ExitButton")

@onready var options_menu: OptionsMenu = $OptionsMenu

const SAVE_FILE_PATH: String = "user://arcade_runner_save.dat"

func _ready() -> void:
	# 🟢 FIXED DEFENSIVE GUARDS: 
	# Added safe checks to every single line. The game will now boot up flawlessly,
	# and will tell you exactly which button path has a spelling error in your output!
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	else:
		print("[PATH ERROR] StartButton node not found inside your main button container container.")

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	else:
		print("[PATH ERROR] ContinueButton node not found inside your main button container container.")

	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	else:
		print("[PATH ALERT] OptionsButton node not found. Drag a new Button into your container named OptionsButton!")

	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	else:
		print("[PATH ERROR] ExitButton node not found inside your main button container container.")
	
	if options_menu:
		options_menu.back_pressed.connect(_on_options_back_pressed)
		options_menu.hide()
	
	# Verify save profiles
	var has_save_file: bool = FileAccess.file_exists(SAVE_FILE_PATH)
	if continue_button:
		continue_button.disabled = not has_save_file
		continue_button.modulate.a = 0.35 if not has_save_file else 1.0

func _on_start_pressed() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		
	if has_node("/root/ProgressionTracker"):
		get_node("/root/ProgressionTracker").current_saved_wave = 1
		
	get_tree().change_scene_to_file(gameplay_scene_path)

func _on_continue_pressed() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var saved_wave: int = file.get_32()
		file.close()
		
		if has_node("/root/ProgressionTracker"):
			get_node("/root/ProgressionTracker").set("current_saved_wave", saved_wave)
			
	get_tree().change_scene_to_file(gameplay_scene_path)

func _on_options_pressed() -> void:
	if main_buttons_container and options_menu:
		main_buttons_container.hide()
		options_menu.show()

func _on_options_back_pressed() -> void:
	if options_menu and main_buttons_container:
		options_menu.hide()
		main_buttons_container.show()

func _on_exit_pressed() -> void:
	get_tree().quit()
