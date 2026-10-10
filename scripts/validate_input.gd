extends SceneTree


func _initialize() -> void:
	InputSetup.ensure_actions()
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await create_timer(0.3).timeout

	var claw: Claw = scene.get_node("World/Claw")
	var x0 := claw._rail_x

	var ev_d := InputEventKey.new()
	ev_d.physical_keycode = KEY_D
	ev_d.pressed = true
	Input.parse_input_event(ev_d)
	await create_timer(0.25).timeout
	ev_d.pressed = false
	Input.parse_input_event(ev_d)

	var moved := absf(claw._rail_x - x0) > 0.01
	var st0 := claw.state
	claw.request_grab()
	await create_timer(0.05).timeout
	var grabbed := claw.state == Claw.State.LOWERING or claw.state != st0

	if moved and grabbed:
		print("VALIDATE_INPUT_OK moved_dx=%.3f state=%s" % [claw._rail_x - x0, claw.get_state_label()])
		quit(0)
	else:
		push_error("VALIDATE_INPUT_FAIL moved=%s grabbed=%s dx=%.3f state=%s" % [moved, grabbed, claw._rail_x - x0, claw.get_state_label()])
		quit(1)
