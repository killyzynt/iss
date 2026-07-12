@tool
extends Resource

@export var left_arrow_texture: Texture2D
@export var right_arrow_texture: Texture2D
@export var button_scale: Vector2 = Vector2(1.0, 1.0)

func attach_mobile_controls(target_scene: Node) -> void:
	if target_scene == null: return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "MobileCanvasOverlay"
	canvas_layer.layer = 2
	
	var layout_control = Control.new()
	layout_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# CRITICAL FIX: Stops this invisible full-screen wrapper from blocking clicks 
	# to your HUD's pause button or menus beneath it!
	layout_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	canvas_layer.add_child(layout_control)
	
	var left_button = TouchScreenButton.new()
	var right_button = TouchScreenButton.new()
	
	left_button.action = "ui_left"
	right_button.action = "ui_right"
	
	left_button.scale = button_scale
	right_button.scale = button_scale
	
	if left_arrow_texture: left_button.texture_normal = left_arrow_texture
	if right_arrow_texture: right_button.texture_normal = right_arrow_texture
	
	layout_control.add_child(left_button)
	layout_control.add_child(right_button)
	target_scene.add_child(canvas_layer)
	
	var screen_resize_handler = func():
		var screen_size: Vector2 = target_scene.get_viewport().get_visible_rect().size
		var margin: float = 40.0
		
		var left_height = (left_button.get_texture_normal().get_height() * button_scale.y) if left_button.get_texture_normal() else 100.0
		left_button.position = Vector2(margin, screen_size.y - left_height - margin)
		
		var right_width = (right_button.get_texture_normal().get_width() * button_scale.x) if right_button.get_texture_normal() else 100.0
		var right_height = (right_button.get_texture_normal().get_height() * button_scale.y) if right_button.get_texture_normal() else 100.0
		right_button.position = Vector2(screen_size.x - right_width - margin, screen_size.y - right_height - margin)
		
	screen_resize_handler.call()
	target_scene.get_viewport().size_changed.connect(screen_resize_handler)
