class_name Doll
extends RigidBody3D

signal collected(doll: Doll, value: int)

var def_id: String = "bear"
var display_name: String = "普通熊"
var rarity: String = "C"
var value: int = 15
var doll_weight: int = 5
var radius: float = 0.18
var description: String = ""
var is_held: bool = false
var is_collected: bool = false

var _mesh: MeshInstance3D
var _collision: CollisionShape3D
var _base_mat: StandardMaterial3D
var _glow: MeshInstance3D
var _hovering := false


func setup(id: String) -> void:
	def_id = id
	var def := DollDefs.get_def(id)
	display_name = def["display_name"]
	rarity = def["rarity"]
	value = int(def["value"])
	radius = float(def["radius"])
	mass = float(def["mass"])
	doll_weight = int(def.get("doll_weight", 5))
	description = str(def.get("description", ""))

	continuous_cd = true
	can_sleep = true
	linear_damp = 0.15
	angular_damp = 0.4
	collision_layer = 2
	collision_mask = 3
	input_ray_pickable = true

	var phys := PhysicsMaterial.new()
	phys.friction = float(def["friction"])
	phys.bounce = float(def["bounce"])
	physics_material_override = phys

	_build_visual(def["color"] as Color)
	_build_collision()


func _build_visual(color: Color) -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_mesh.mesh = sphere

	_base_mat = StandardMaterial3D.new()
	_base_mat.albedo_color = color
	_base_mat.roughness = 0.85
	_mesh.material_override = _base_mat
	add_child(_mesh)
	_build_glow()

	var eye_l := _make_dot(Color(0.08, 0.08, 0.1), Vector3(-radius * 0.35, radius * 0.25, radius * 0.72))
	var eye_r := _make_dot(Color(0.08, 0.08, 0.1), Vector3(radius * 0.35, radius * 0.25, radius * 0.72))
	add_child(eye_l)
	add_child(eye_r)


func _make_dot(color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius * 0.12
	sm.height = radius * 0.24
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	return mi


func _build_glow() -> void:
	_glow = MeshInstance3D.new()
	_glow.name = "HoverGlow"
	var sphere := SphereMesh.new()
	sphere.radius = radius * 1.08
	sphere.height = radius * 2.16
	_glow.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.albedo_color = Color(1.0, 0.88, 0.38, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.98, 0.86, 0.38)
	mat.emission_energy_multiplier = 2.2
	_glow.material_override = mat
	_glow.visible = false
	add_child(_glow)


func _build_collision() -> void:
	_collision = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	_collision.shape = shape
	add_child(_collision)


func hover_info() -> Dictionary:
	var body := description
	if body == "":
		body = "分数 %d · 重量 %d" % [value, doll_weight]
	else:
		body = "%s\n分数 %d · 重量 %d" % [body, value, doll_weight]
	return {
		"title": display_name,
		"body": body,
	}


func set_hovered(on: bool) -> void:
	if _hovering == on:
		return
	_hovering = on
	if _glow:
		_glow.visible = on


func mark_collected() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(self, value)
	queue_free()
