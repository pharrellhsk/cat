class_name Claw
extends Node3D

signal grab_started
signal grab_finished
signal released_doll(doll: Doll)

enum State { IDLE, LOWERING, CLOSING, LIFTING, HOLDING, OPENING, COOLDOWN }

const MOVE_SPEED := 1.2
const LOWER_SPEED := 0.8
const RISE_SPEED := 0.6
const CLOSE_TIME := 0.4
const MAX_GRIP := 25.0
const GRIP_DECAY := 0.3
const ROPE_LENGTH := 1.5
const COOLDOWN := 1.0
const X_RANGE := 0.9
const Z_RANGE := 0.5
const TOP_Y := 1.42
## Lowest gripper height above floor so jaws meet doll centers.
const GRIP_TARGET_Y := 0.28

var state: State = State.IDLE
var grip_force: float = 0.0
var held_doll: Doll = null

var _rail_x: float = 0.0
var _rail_z: float = 0.0
var _drop_y: float = 0.0
var _close_t: float = 0.0
var _cooldown_left: float = 0.0
var _move_input: Vector2 = Vector2.ZERO
var _space_was_down: bool = false
var _hold_offset: Vector3 = Vector3.ZERO

var _carriage: Node3D
var _cable: MeshInstance3D
var _gripper: Node3D
var _left_jaw: Node3D
var _right_jaw: Node3D
var _grip_area: Area3D
var drop_parent: Node


func _ready() -> void:
	_build()
	if drop_parent == null:
		drop_parent = get_parent()
	_apply_carriage_transform()
	_update_visuals()


func _physics_process(delta: float) -> void:
	_handle_input()
	_update_movement(delta)
	_update_state(delta)
	_update_visuals()
	_update_grip(delta)
	_sync_held_doll()


func _build() -> void:
	_carriage = Node3D.new()
	_carriage.name = "Carriage"
	add_child(_carriage)

	var rail_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.08, 0.25)
	rail_mesh.mesh = box
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.55, 0.58, 0.62)
	rail_mat.metallic = 0.8
	rail_mat.roughness = 0.35
	rail_mesh.material_override = rail_mat
	_carriage.add_child(rail_mesh)

	_cable = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = 0.1
	_cable.mesh = cyl
	var cable_mat := StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.2, 0.2, 0.22)
	_cable.material_override = cable_mat
	_carriage.add_child(_cable)

	_gripper = Node3D.new()
	_gripper.name = "Gripper"
	_carriage.add_child(_gripper)

	var base_mesh := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(0.16, 0.08, 0.16)
	base_mesh.mesh = base_box
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.72, 0.74, 0.78)
	metal.metallic = 0.9
	metal.roughness = 0.25
	base_mesh.material_override = metal
	_gripper.add_child(base_mesh)

	_left_jaw = _make_jaw(metal, -1)
	_right_jaw = _make_jaw(metal, 1)
	_gripper.add_child(_left_jaw)
	_gripper.add_child(_right_jaw)

	_grip_area = Area3D.new()
	_grip_area.monitoring = true
	_grip_area.monitorable = false
	var area_col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	area_col.shape = sphere
	area_col.position = Vector3(0, -0.12, 0)
	_grip_area.add_child(area_col)
	_gripper.add_child(_grip_area)


func _make_jaw(mat: Material, side: int) -> Node3D:
	var jaw := Node3D.new()
	jaw.position = Vector3(0.06 * side, -0.05, 0)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.18, 0.08)
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = Vector3(0.02 * side, -0.08, 0)
	jaw.add_child(mesh)
	return jaw


func _handle_input() -> void:
	var ui := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	var wasd := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	_move_input = wasd if wasd != Vector2.ZERO else ui

	if Input.is_action_just_pressed("grab") or _space_just_pressed():
		_on_grab_pressed()


func _space_just_pressed() -> bool:
	var down := Input.is_physical_key_pressed(KEY_SPACE)
	var just := down and not _space_was_down
	_space_was_down = down
	return just


func _on_grab_pressed() -> void:
	match state:
		State.IDLE:
			state = State.LOWERING
			grab_started.emit()
		State.HOLDING:
			_begin_open()
		_:
			pass


func _update_movement(delta: float) -> void:
	if state == State.IDLE or state == State.HOLDING:
		_rail_x = clampf(_rail_x + _move_input.x * MOVE_SPEED * delta, -X_RANGE, X_RANGE)
		_rail_z = clampf(_rail_z + _move_input.y * MOVE_SPEED * delta, -Z_RANGE, Z_RANGE)
	_apply_carriage_transform()


func _apply_carriage_transform() -> void:
	_carriage.position = Vector3(_rail_x, TOP_Y, _rail_z)
	_gripper.position = Vector3(0, -_drop_y, 0)


func _update_state(delta: float) -> void:
	match state:
		State.LOWERING:
			var target := minf(ROPE_LENGTH, TOP_Y - GRIP_TARGET_Y)
			_drop_y = minf(_drop_y + LOWER_SPEED * delta, target)
			if _drop_y >= target - 0.001:
				state = State.CLOSING
				_close_t = 0.0
				grip_force = MAX_GRIP
		State.CLOSING:
			_close_t += delta
			if _close_t >= CLOSE_TIME:
				_try_grab()
				state = State.LIFTING
		State.LIFTING:
			_drop_y = maxf(_drop_y - RISE_SPEED * delta, 0.0)
			if _drop_y <= 0.001:
				_drop_y = 0.0
				if held_doll != null:
					state = State.HOLDING
				else:
					_begin_open()
		State.OPENING:
			_close_t += delta
			if _close_t >= CLOSE_TIME * 0.5 and held_doll != null:
				_release_held()
			if _close_t >= CLOSE_TIME:
				_release_held()
				state = State.COOLDOWN
				_cooldown_left = COOLDOWN
				grab_finished.emit()
		State.COOLDOWN:
			_cooldown_left -= delta
			if _cooldown_left <= 0.0:
				state = State.IDLE
		_:
			pass


func _update_visuals() -> void:
	var close_ratio := 0.0
	match state:
		State.CLOSING:
			close_ratio = clampf(_close_t / CLOSE_TIME, 0.0, 1.0)
		State.LIFTING, State.HOLDING:
			close_ratio = 1.0
		State.OPENING:
			close_ratio = 1.0 - clampf(_close_t / CLOSE_TIME, 0.0, 1.0)
		_:
			close_ratio = 0.0

	var angle := lerpf(0.35, -0.55, close_ratio)
	_left_jaw.rotation.z = -angle
	_right_jaw.rotation.z = angle

	var cable_len := maxf(_drop_y, 0.05)
	_cable.scale = Vector3(1, cable_len / 0.1, 1)
	_cable.position = Vector3(0, -cable_len * 0.5, 0)


func _update_grip(delta: float) -> void:
	if held_doll == null:
		return
	if not is_instance_valid(held_doll):
		held_doll = null
		if state == State.HOLDING:
			_begin_open()
		return

	grip_force = maxf(grip_force - GRIP_DECAY * delta, 0.0)
	var needed: float = held_doll.mass * 9.8 * 0.85
	if grip_force < needed and state in [State.LIFTING, State.HOLDING]:
		_release_held()
		if state == State.HOLDING:
			_begin_open()


func _sync_held_doll() -> void:
	if held_doll == null or not is_instance_valid(held_doll):
		return
	if held_doll.get_parent() != _gripper:
		return
	held_doll.position = _hold_offset
	held_doll.linear_velocity = Vector3.ZERO
	held_doll.angular_velocity = Vector3.ZERO


func _try_grab() -> void:
	var best: Doll = null
	var best_dist := 999.0
	for body in _grip_area.get_overlapping_bodies():
		var doll := body as Doll
		if doll == null or doll.is_collected or doll.is_held:
			continue
		var dist := _gripper.global_position.distance_to(doll.global_position)
		if dist < best_dist:
			best_dist = dist
			best = doll

	if best == null:
		return

	var needed: float = best.mass * 9.8 * 0.85
	if grip_force < needed:
		return

	held_doll = best
	held_doll.is_held = true
	held_doll.freeze = true
	_hold_offset = Vector3(0, -0.14 - held_doll.radius * 0.35, 0)

	var global_xf: Transform3D = held_doll.global_transform
	if held_doll.get_parent():
		held_doll.get_parent().remove_child(held_doll)
	_gripper.add_child(held_doll)
	held_doll.global_transform = global_xf
	held_doll.position = _hold_offset
	held_doll.rotation = Vector3.ZERO


func _begin_open() -> void:
	state = State.OPENING
	_close_t = 0.0


func _release_held() -> void:
	if held_doll == null:
		return
	if not is_instance_valid(held_doll):
		held_doll = null
		grip_force = 0.0
		return

	var global_xf: Transform3D = held_doll.global_transform
	var parent_node := drop_parent if drop_parent else get_tree().current_scene
	_gripper.remove_child(held_doll)
	parent_node.add_child(held_doll)
	held_doll.global_transform = global_xf
	held_doll.freeze = false
	held_doll.is_held = false
	held_doll.linear_velocity = Vector3(0, -0.5, 0)
	released_doll.emit(held_doll)
	held_doll = null
	grip_force = 0.0


func reset_to_center() -> void:
	_release_held()
	state = State.IDLE
	_rail_x = 0.0
	_rail_z = 0.0
	_drop_y = 0.0
	_close_t = 0.0
	_cooldown_left = 0.0
	grip_force = 0.0
	_apply_carriage_transform()
	_update_visuals()


func get_state_label() -> String:
	match state:
		State.IDLE: return "就绪"
		State.LOWERING: return "下探"
		State.CLOSING: return "闭合"
		State.LIFTING: return "上升"
		State.HOLDING: return "搬运"
		State.OPENING: return "松开"
		State.COOLDOWN: return "冷却"
	return "?"
