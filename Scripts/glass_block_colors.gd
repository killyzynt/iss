class_name GlassBlockColors
extends Node

static func parse_color_string(color_str: String) -> int:
	match color_str.to_lower():
		"red": return 0
		"blue": return 1
		"purple": return 2
		"dark_purple": return 3
	return 0

## 🟢 FIXED GENERATOR: Now accepts the current_thickness variable dynamically!
## This means your library handles ALL math, keeping your main game loops clean.
static func generate_glass_material(color_name: String, current_thickness: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	
	# 1. OPTIMIZED HIGH-TRANSPARENCY BLENDING
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Two-sided rendering to see back walls
	
	# 2. STANDARD SMOOTH GLASS SPECULARITY
	mat.roughness = 0.08
	mat.metallic = 0.10
	mat.metallic_specular = 1.0 
	
	# 3. BRIGHT NEON CONTOUR OUTLINES
	mat.rim_enabled = true
	mat.rim = 1.0
	mat.rim_tint = 1.0
	
	# 4. ALWAYS EMISSIVE
	mat.emission_enabled = true

	# 🧮 5. DYNAMIC OPACITY & BRIGHTNESS EXTENSIONS
	var dynamic_alpha: float = clampf(remap(current_thickness, 0.01, 6.5, 0.40, 0.95), 0.40, 0.95)
	var brightness_factor: float = clampf(remap(current_thickness, 0.01, 6.5, 1.0, 0.25), 0.25, 1.0)

	match color_name:
		"red":
			mat.albedo_color = Color(1.1 * brightness_factor, 0.02 * brightness_factor, 0.02 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.45, 0.01, 0.01)
		"blue":
			mat.albedo_color = Color(0.0, 0.40 * brightness_factor, 1.8 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.0, 0.20, 0.85)
		"purple":
			mat.albedo_color = Color(0.85 * brightness_factor, 0.02 * brightness_factor, 1.4 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.35, 0.02, 0.55)
		"dark_purple":
			mat.albedo_color = Color(0.35 * brightness_factor, 0.0, 0.65 * brightness_factor, dynamic_alpha)
			var emission_factor: float = clampf(remap(current_thickness, 0.01, 6.5, 0.60, 0.20), 0.20, 0.60)
			mat.emission = Color(0.35 * emission_factor, 0.0, 0.70 * emission_factor)

	return mat


static func update_glass_material_properties(mat: StandardMaterial3D, color_name: String, current_thickness: float) -> void:
	if mat == null: return
	
	# MATCHED RUNTIME UPDATES
	var dynamic_alpha: float = clampf(remap(current_thickness, 0.01, 6.5, 0.40, 0.95), 0.40, 0.95)
	var brightness_factor: float = clampf(remap(current_thickness, 0.01, 6.5, 1.0, 0.25), 0.25, 1.0)
	
	match color_name:
		"red":
			mat.albedo_color = Color(1.1 * brightness_factor, 0.02 * brightness_factor, 0.02 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.45, 0.01, 0.01)
		"blue":
			mat.albedo_color = Color(0.0, 0.40 * brightness_factor, 1.8 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.0, 0.20, 0.85)
		"purple":
			# 🟢 FIXED: Removed "self" check to clear the compilation crash error instantly!
			mat.albedo_color = Color(0.85 * brightness_factor, 0.02 * brightness_factor, 1.4 * brightness_factor, dynamic_alpha)
			mat.emission = Color(0.35, 0.02, 0.55)
		"dark_purple":
			mat.albedo_color = Color(0.35 * brightness_factor, 0.0, 0.65 * brightness_factor, dynamic_alpha)
			var emission_factor: float = clampf(remap(current_thickness, 0.01, 6.5, 0.60, 0.20), 0.20, 0.60)
			mat.emission = Color(0.35 * emission_factor, 0.0, 0.70 * emission_factor)

static func calculate_thickness(
	color_int: int, 
	active_hp: float, 
	spawn_base_hp: float, 
	min_thick: float, min_hp: float, 
	blue_min_thick: float, blue_min_hp: float, 
	max_thickness_cap: float
) -> float:
	
	if active_hp <= 0.0: return 0.01

	var hp_lost: float = maxf(0.0, spawn_base_hp - active_hp)
	
	if color_int == 0: # Red Block
		var spawn_thickness: float = min_thick + ((spawn_base_hp - min_hp) * 0.01)
		spawn_thickness = clampf(spawn_thickness, min_thick, max_thickness_cap)
		return maxf(0.01, spawn_thickness - (hp_lost * 0.01))
		
	elif color_int == 1: # Blue Block
		var spawn_thickness: float = blue_min_thick + ((spawn_base_hp - blue_min_hp) * 0.01)
		spawn_thickness = clampf(spawn_thickness, blue_min_thick, max_thickness_cap)
		return maxf(0.01, spawn_thickness - (hp_lost * 0.01))
		
	elif color_int == 2: # Purple Block 
		var spawn_thickness: float = spawn_base_hp * 0.01
		spawn_thickness = clampf(spawn_thickness, 0.3, 5.5) 
		return maxf(0.01, spawn_thickness - (hp_lost * 0.01))
		
	elif color_int == 3: # Dark Purple Block
		var spawn_thickness: float = spawn_base_hp * 0.01
		spawn_thickness = clampf(spawn_thickness, 0.6, 6.5) 
		return maxf(0.01, spawn_thickness - (hp_lost * 0.01))

	print("[GEOMETRY ERROR] Unknown color index received: ", color_int)
	return 0.1
