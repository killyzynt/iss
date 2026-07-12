class_name OptionsMenu
extends Control

signal back_pressed

@onready var control_toggle_button: Button = $PanelContainer/VBoxContainer/ControlToggleButton
@onready var back_button: Button = $PanelContainer/VBoxContainer/BackButton

func _ready() -> void:
	# Connect the only two buttons you need
	control_toggle_button.pressed.connect(_on_control_toggle_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Force the text to display the correct active control scheme at launch
	_update_control_button_text()

func _on_control_toggle_pressed() -> void:
	# Look at the global metadata engine: 0 = ARROWS, 1 = SWIPE
	if Engine.get_meta("control_type", 0) == 0:
		Engine.set_meta("control_type", 1)
	else:
		Engine.set_meta("control_type", 0)
	
	_update_control_button_text()

func _update_control_button_text() -> void:
	if Engine.get_meta("control_type", 0) == 0:
		control_toggle_button.text = "Control Style: ARROWS"
	else:
		control_toggle_button.text = "Control Style: SWIPE"

func _on_back_button_pressed() -> void:
	back_pressed.emit()
