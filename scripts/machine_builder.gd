class_name MachineBuilder
extends RefCounted

## Internal playable volume: 1.8m (X) x 1.2m (Z) x 1.5m (Y)
const WIDTH := 1.8
const DEPTH := 1.2
const HEIGHT := 1.5
const WALL := 0.06
const EXIT_SIZE := 0.35


static func build(parent: Node3D) -> Area3D:
	var root := Node3D.new()
	root.name = "Machine"
	parent.add_child(root)

	_add_floor(root)
	_add_walls(root)
	_add_frame(root)
	_add_ceiling_rail(root)
	return _add_exit(root)


static func _mat(color: Color, metallic := 0.0, roughness := 0.7, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, with_collision := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)

	if with_collision:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
	return body


static func _add_floor(root: Node3D) -> void:
	var floor_mat := _mat(Color(0.35, 0.55, 0.75), 0.1, 0.55)
	_box(root, Vector3(WIDTH + WALL * 2.0, 0.08, DEPTH + WALL * 2.0), Vector3(0, -0.04, 0), floor_mat)

	# Soft pad inside so dolls rest visibly above collision.
	var pad := _mat(Color(0.45, 0.72, 0.92), 0.0, 0.9)
	_box(root, Vector3(WIDTH - 0.05, 0.02, DEPTH - 0.05), Vector3(0, 0.01, 0), pad, false)


static func _add_walls(root: Node3D) -> void:
	var glass := _mat(Color(0.7, 0.88, 1.0, 0.18), 0.05, 0.05, true)
	var hw := WIDTH * 0.5
	var hd := DEPTH * 0.5
	var hy := HEIGHT * 0.5

	_box(root, Vector3(WIDTH, HEIGHT, WALL), Vector3(0, hy, -hd - WALL * 0.5), glass)
	_box(root, Vector3(WIDTH, HEIGHT, WALL), Vector3(0, hy, hd + WALL * 0.5), glass)
	_box(root, Vector3(WALL, HEIGHT, DEPTH), Vector3(-hw - WALL * 0.5, hy, 0), glass)
	_box(root, Vector3(WALL, HEIGHT, DEPTH), Vector3(hw + WALL * 0.5, hy, 0), glass)


static func _add_frame(root: Node3D) -> void:
	var metal := _mat(Color(0.85, 0.2, 0.28), 0.6, 0.4)
	var hw := WIDTH * 0.5 + WALL
	var hd := DEPTH * 0.5 + WALL
	var posts := [
		Vector3(-hw, HEIGHT * 0.5, -hd),
		Vector3(hw, HEIGHT * 0.5, -hd),
		Vector3(-hw, HEIGHT * 0.5, hd),
		Vector3(hw, HEIGHT * 0.5, hd),
	]
	for p in posts:
		_box(root, Vector3(0.08, HEIGHT + 0.1, 0.08), p, metal)

	# Cabinet base below floor.
	_box(root, Vector3(WIDTH + 0.3, 0.7, DEPTH + 0.3), Vector3(0, -0.43, 0), metal)

	# Prize window / chute fascia at +X +Z corner.
	var fascia := _mat(Color(0.15, 0.16, 0.2), 0.3, 0.5)
	_box(root, Vector3(0.5, 0.55, 0.5), Vector3(hw - 0.15, -0.35, hd - 0.15), fascia)


static func _add_ceiling_rail(root: Node3D) -> void:
	var rail := _mat(Color(0.45, 0.48, 0.52), 0.85, 0.3)
	_box(root, Vector3(WIDTH - 0.1, 0.04, 0.06), Vector3(0, HEIGHT + 0.02, 0), rail, false)
	_box(root, Vector3(0.06, 0.04, DEPTH - 0.1), Vector3(0, HEIGHT + 0.02, 0), rail, false)


static func _add_exit(root: Node3D) -> Area3D:
	var exit := ExitChute.new()
	exit.name = "ExitChute"
	# Front-right corner hole.
	var x := WIDTH * 0.5 - EXIT_SIZE * 0.5 - 0.05
	var z := DEPTH * 0.5 - EXIT_SIZE * 0.5 - 0.05
	exit.position = Vector3(x, 0.08, z)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(EXIT_SIZE, 0.25, EXIT_SIZE)
	col.shape = shape
	exit.add_child(col)

	# Visual hole marker.
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(EXIT_SIZE, 0.02, EXIT_SIZE)
	mi.mesh = mesh
	var mat := _mat(Color(0.05, 0.05, 0.08), 0.0, 0.95)
	mi.material_override = mat
	mi.position = Vector3(0, -0.05, 0)
	exit.add_child(mi)

	# Funnel walls so dolls fall in more reliably.
	var wall_mat := _mat(Color(0.2, 0.22, 0.28), 0.4, 0.5)
	_box(root, Vector3(EXIT_SIZE + 0.08, 0.2, 0.04), Vector3(x, 0.1, z - EXIT_SIZE * 0.5 - 0.02), wall_mat)
	_box(root, Vector3(EXIT_SIZE + 0.08, 0.2, 0.04), Vector3(x, 0.1, z + EXIT_SIZE * 0.5 + 0.02), wall_mat)
	_box(root, Vector3(0.04, 0.2, EXIT_SIZE + 0.08), Vector3(x - EXIT_SIZE * 0.5 - 0.02, 0.1, z), wall_mat)
	_box(root, Vector3(0.04, 0.2, EXIT_SIZE + 0.08), Vector3(x + EXIT_SIZE * 0.5 + 0.02, 0.1, z), wall_mat)

	# Open floor under exit: thin kill volume is enough for MVP collection.
	root.add_child(exit)
	return exit
