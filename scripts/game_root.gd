extends Node3D

const DOLL_COUNT := 10

@onready var world: Node3D = $World
@onready var claw: Claw = $World/Claw
@onready var round_manager: RoundManager = $RoundManager
@onready var hud: GameHUD = $HUD
@onready var dolls_root: Node3D = $World/Dolls

var _exit: ExitChute
var _rng := RandomNumberGenerator.new()
var _restarting := false
var _hovered_doll: Doll = null


func _ready() -> void:
	InputSetup.ensure_actions()
	get_tree().paused = false
	DisplayServer.window_set_ime_active(false)
	get_viewport().gui_release_focus()

	_rng.randomize()
	_exit = MachineBuilder.build(world)
	_exit.doll_exited.connect(_on_doll_exited)

	claw.drop_parent = dolls_root
	claw.drop_target = Vector2(_exit.position.x, _exit.position.z)
	claw.position = Vector3.ZERO
	claw.grab_started.connect(_on_grab_started)
	claw.grab_finished.connect(_on_grab_finished)

	_wire_ui()
	round_manager.start_round()
	_spawn_dolls()


func _process(_delta: float) -> void:
	if hud.is_settings_open() or hud.is_shop_open():
		if _hovered_doll:
			_set_hovered_doll(null)
		return
	hud.set_claw_state(
		"%s | 输入:%s" % [claw.get_state_label(), claw.last_input_debug],
		claw.grip_force
	)
	hud.set_coin_enabled(round_manager.can_insert_coin() and claw.is_idle())
	_update_doll_hover()


func _unhandled_input(event: InputEvent) -> void:
	if hud.is_settings_open() or hud.is_shop_open():
		return
	if event.is_action_pressed("restart_round"):
		_restart()
		get_viewport().set_input_as_handled()


func _wire_ui() -> void:
	round_manager.round_started.connect(func(stage: int, stage_count: int, target: int, coins: int):
		hud.hide_shop()
		hud.hide_result()
		hud.set_stage_info(stage, stage_count)
		hud.set_target_progress(0, target)
		hud.set_money(round_manager.total_money)
		hud.set_coins(coins, false)
		hud.set_inventory(round_manager.inventory)
		claw.claw_power = round_manager.claw_power
		claw.credit_ready = false
		get_viewport().gui_release_focus()
	)
	round_manager.earnings_changed.connect(func(earned: int, total: int):
		hud.set_target_progress(earned, round_manager.target)
		hud.set_money(total)
	)
	round_manager.coins_changed.connect(func(coins: int, credit_ready: bool):
		hud.set_coins(coins, credit_ready)
		if claw.is_idle():
			claw.credit_ready = credit_ready
	)
	round_manager.inventory_changed.connect(func():
		hud.set_inventory(round_manager.inventory)
	)
	round_manager.banner.connect(hud.show_banner)
	round_manager.round_settled.connect(func(kind: int, stage: int, earned: int, target: int, total: int, gold_reward: int):
		claw.credit_ready = false
		hud.set_coin_enabled(false)
		hud.set_inventory(round_manager.inventory)
		hud.show_result(kind, stage, earned, target, total, gold_reward)
	)
	hud.result_next_pressed.connect(_next_stage)
	hud.result_title_pressed.connect(_return_to_title)
	hud.shop_continue_pressed.connect(_on_shop_continue)
	hud.shop_buy_pressed.connect(_on_shop_buy)
	hud.settings_restart_pressed.connect(_restart)
	hud.settings_title_pressed.connect(_return_to_title)
	hud.grab_button.pressed.connect(func():
		claw.request_grab()
	)
	hud.coin_button.pressed.connect(_on_insert_coin)


func _on_insert_coin() -> void:
	if not claw.is_idle():
		return
	if round_manager.try_insert_coin():
		claw.credit_ready = true
		claw.last_input_debug = "投币"
		get_viewport().gui_release_focus()


func _on_grab_started() -> void:
	claw.slip_immune = round_manager.prepare_grab()
	claw.claw_power = round_manager.claw_power
	_apply_arcade_coin_bonus()


func _on_grab_finished() -> void:
	claw.slip_immune = false
	round_manager.on_grab_cycle_finished()


func _apply_arcade_coin_bonus() -> void:
	var coin: Dictionary = round_manager.last_inserted_coin
	if int(coin.get("coin_effect", 1001)) != 1002:
		return
	var para: Array = coin.get("effect_para", [1, 2])
	var count := 1
	var mult := 2
	if para.size() >= 1:
		count = maxi(int(para[0]), 1)
	if para.size() >= 2:
		mult = maxi(int(para[1]), 1)
	var dolls: Array = []
	for child in dolls_root.get_children():
		var doll := child as Doll
		if doll and not doll.is_collected:
			dolls.append(doll)
	dolls.shuffle()
	for i in mini(count, dolls.size()):
		var doll: Doll = dolls[i]
		doll.value *= mult
		if doll.get_child_count() > 0:
			var mesh := doll.get_child(0) as MeshInstance3D
			if mesh and mesh.material_override is StandardMaterial3D:
				var mat := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
				mat.emission_enabled = true
				mat.emission = Color(0.95, 0.82, 0.35)
				mat.emission_energy_multiplier = 1.4
				mesh.material_override = mat


func _spawn_dolls() -> void:
	for child in dolls_root.get_children():
		child.queue_free()

	DollDefs.ensure_loaded()
	var ids: Array[String] = []
	for i in DOLL_COUNT:
		ids.append(DollDefs.random_id(_rng))
	for owned in round_manager.inventory.dolls:
		var copies := 1
		var para: Array = owned.get("effect_para", [1])
		if not para.is_empty():
			copies = maxi(int(para[0]), 1)
		for _n in copies:
			ids.append(str(owned.get("id", "doll_0")))

	for i in ids.size():
		var id: String = ids[i]
		var doll := Doll.new()
		doll.name = "Doll_%d_%s" % [i, id]
		dolls_root.add_child(doll)
		doll.setup(id)
		var x := _rng.randf_range(-0.7, 0.55)
		var z := _rng.randf_range(-0.45, 0.35)
		if x > 0.45 and z > 0.2:
			x = _rng.randf_range(-0.7, 0.3)
			z = _rng.randf_range(-0.45, 0.1)
		doll.position = Vector3(x, 0.4 + i * 0.05, z)
		doll.rotation = Vector3(
			_rng.randf_range(-0.2, 0.2),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-0.2, 0.2)
		)


func _on_doll_exited(doll: Doll, value: int) -> void:
	if _hovered_doll == doll:
		_set_hovered_doll(null)
	round_manager.add_earn(value, doll.display_name)


func _update_doll_hover() -> void:
	var mouse := get_viewport().get_mouse_position()
	if hud.is_pointer_over_ui(mouse):
		_set_hovered_doll(null)
		return
	_set_hovered_doll(_pick_doll_at(mouse))


func _pick_doll_at(mouse: Vector2) -> Doll:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 40.0)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 2
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var doll := hit.get("collider") as Doll
		if doll and not doll.is_collected and not doll.is_held:
			return doll
	var best: Doll = null
	var best_dist := 42.0
	for child in dolls_root.get_children():
		var doll := child as Doll
		if doll == null or doll.is_collected or doll.is_held:
			continue
		if not is_instance_valid(doll):
			continue
		if camera.is_position_behind(doll.global_position):
			continue
		var screen := camera.unproject_position(doll.global_position)
		var dist := screen.distance_to(mouse)
		if dist < best_dist:
			best_dist = dist
			best = doll
	return best


func _set_hovered_doll(doll: Doll) -> void:
	if _hovered_doll == doll:
		if doll == null:
			return
		return
	if _hovered_doll and is_instance_valid(_hovered_doll):
		_hovered_doll.set_hovered(false)
	_hovered_doll = doll
	if _hovered_doll and is_instance_valid(_hovered_doll):
		_hovered_doll.set_hovered(true)
		var info: Dictionary = _hovered_doll.hover_info()
		hud.show_hover_card(str(info.get("title", "")), str(info.get("body", "")), "doll")
	else:
		hud.hide_hover_card("doll")


func _on_shop_buy(kind: String, index: int) -> void:
	var err := round_manager.try_buy(kind, index)
	hud.set_inventory(round_manager.inventory)
	if err != "":
		hud.show_shop_status(err)
	else:
		hud.show_shop_status("购买成功")
		hud.refresh_shop(round_manager.inventory)


func _on_shop_continue() -> void:
	if round_manager.last_result == RoundManager.ResultKind.NEXT:
		_next_stage()
	else:
		_return_to_title()


func _next_stage() -> void:
	if _restarting:
		return
	_restarting = true
	hud.close_settings()
	hud.hide_shop()
	claw.reset_to_center()
	await get_tree().process_frame
	_spawn_dolls()
	round_manager.start_next_stage()
	_restarting = false


func _restart() -> void:
	if _restarting:
		return
	_restarting = true
	hud.close_settings()
	hud.hide_shop()
	claw.reset_to_center()
	await get_tree().process_frame
	round_manager.restart_round()
	_spawn_dolls()
	_restarting = false


func _return_to_title() -> void:
	hud.close_settings()
	hud.hide_shop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
