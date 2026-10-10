extends Node3D

const DOLL_COUNT := 10

@onready var world: Node3D = $World
@onready var claw: Claw = $World/Claw
@onready var round_manager: RoundManager = $RoundManager
@onready var hud: GameHUD = $HUD
@onready var dolls_root: Node3D = $World/Dolls

var _exit: ExitChute
var _rng := RandomNumberGenerator.new()
var _r_was_down := false
var _restarting := false


func _ready() -> void:
	_rng.randomize()
	_exit = MachineBuilder.build(world)
	_exit.doll_exited.connect(_on_doll_exited)

	claw.drop_parent = dolls_root
	claw.position = Vector3.ZERO

	_spawn_dolls()
	_wire_ui()
	round_manager.start_round()


func _process(_delta: float) -> void:
	hud.set_claw_state(claw.get_state_label(), claw.grip_force)

	var r_down := Input.is_physical_key_pressed(KEY_R)
	if r_down and not _r_was_down:
		_restart()
	_r_was_down = r_down


func _wire_ui() -> void:
	round_manager.round_started.connect(func(target: int, _dur: float):
		hud.hide_result()
		hud.set_target_progress(0, target)
		hud.set_money(round_manager.total_money)
	)
	round_manager.earnings_changed.connect(func(earned: int, total: int):
		hud.set_target_progress(earned, round_manager.target)
		hud.set_money(total)
	)
	round_manager.timer_updated.connect(hud.set_timer)
	round_manager.banner.connect(hud.show_banner)
	round_manager.round_settled.connect(func(success: bool, earned: int, target: int, total: int):
		hud.show_result(success, earned, target, total)
	)
	hud.restart_button.pressed.connect(_restart)


func _spawn_dolls() -> void:
	for child in dolls_root.get_children():
		child.queue_free()

	for i in DOLL_COUNT:
		var id: String = DollDefs.SPAWN_POOL[_rng.randi_range(0, DollDefs.SPAWN_POOL.size() - 1)]
		var doll := Doll.new()
		doll.name = "Doll_%d_%s" % [i, id]
		dolls_root.add_child(doll)
		doll.setup(id)

		var x := _rng.randf_range(-0.7, 0.55)
		var z := _rng.randf_range(-0.45, 0.35)
		if x > 0.45 and z > 0.2:
			x = _rng.randf_range(-0.7, 0.3)
			z = _rng.randf_range(-0.45, 0.1)
		doll.position = Vector3(x, 0.4 + i * 0.06, z)
		doll.rotation = Vector3(
			_rng.randf_range(-0.2, 0.2),
			_rng.randf_range(0.0, TAU),
			_rng.randf_range(-0.2, 0.2)
		)


func _on_doll_exited(doll: Doll, value: int) -> void:
	round_manager.add_earn(value, doll.display_name)


func _restart() -> void:
	if _restarting:
		return
	_restarting = true
	claw.reset_to_center()
	await get_tree().process_frame
	_spawn_dolls()
	round_manager.restart_round()
	_restarting = false
