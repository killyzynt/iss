extends Control

@onready var left_btn: TouchScreenButton = $LeftButton
@onready var right_btn: TouchScreenButton = $RightButton

func _ready() -> void:
	# 1. Force the layout to automatically scale and adapt to any phone screen size
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 2. Configure the Left Input Button area (Covers the entire left half of the phone)
	left_btn.action = "move_left"
	left_btn.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	
	# 3. Configure the Right Input Button area (Covers the entire right half of the phone)
	right_btn.action = "move_right"
	right_btn.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	
	# Call deferred to allow the engine viewport sizing system to fully settle first
	callable_calculate_touch_zones.call_deferred()

func callable_calculate_touch_zones() -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	var half_width: float = screen_size.x * 0.5
	
	# Set shapes dynamically so they act as massive invisible steering pads
	if left_btn and left_btn.shape:
		left_btn.position = Vector2.ZERO
		# Adjust button bounding shape to fill the left half rectangle
		if left_btn.shape is RectangleShape2D:
			left_btn.shape.size = Vector2(half_width, screen_size.y)
			left_btn.shape.position = Vector2(half_width * 0.5, screen_size.y * 0.5)

	if right_btn and right_btn.shape:
		right_btn.position = Vector2(half_width, 0.0)
		# Adjust button bounding shape to fill the right half rectangle
		if right_btn.shape is RectangleShape2D:
			right_btn.shape.size = Vector2(half_width, screen_size.y)
			right_btn.shape.position = Vector2(half_width * 0.5, screen_size.y * 0.5)
