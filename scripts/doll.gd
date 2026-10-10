class_name Doll
extends RigidBody3D

signal collected(doll: Doll, value: int)

var def_id: String = "bear"
var display_name: String = "普通熊"
var rarity: String = "C"
var value: int = 15
var doll_weight: int = 5
var radius: float = 0.18
var is_held: bool = false
var is_collected: bool = false

var _mesh: MeshInstance3D
var _collision: CollisionShape3D


func setup(id: String) -> void:
	def_id = id
	var def := DollDefs.get_def(id)
	display_name = def["display_name"]
	rarity = def["rarity"]
	value = int(def["value"])
	radius = float(def["radius"])
	mass = float(def["mass"])
	doll_weight = int(def.get("doll_weight", 5))

	continuous_cd = true
	can_sleep = true
	linear_damp = 0.15
	angular_damp = 0.4

	var mat := PhysicsMaterial.new()
	mat.friction = float(def["friction"])
	mat.bounce = float(def["bounce"])
	physics_material_override = mat

	_build_visual(def["color"] as Color)
	_build_collision()


func _build_visual(color: Color) -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	_mesh.material_override = mat
	add_child(_mesh)

	# Tiny "face" so orientation is readable in recordings.
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


func _build_collision() -> void:
	_collision = CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	_collision.shape = shape
	add_child(_collision)


func mark_collected() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(self, value)
	queue_free()
