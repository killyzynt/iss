extends Control

# Inside your active gameplay HUD.gd or Arrow Buttons parent script:

## Keep the mobile arrow buttons visibility locked to the options menu metadata toggle
func _process(_delta: float) -> void:
	# Query the safe engine metadata register: 0 = ARROWS, 1 = SWIPE
	var current_control_mode: int = Engine.get_meta("control_type", 0)
	
	if current_control_mode == 0:
		# 🟢 SHOW ARROWS: Make the UI layer completely visible so players can tap them
		self.visible = true
	else:
		# 🔴 HIDE ARROWS: Completely hide them from the screen layout while Swipe mode is running
		self.visible = false
