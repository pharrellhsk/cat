extends SceneTree


func _initialize() -> void:
	var err_msgs: Array[String] = []
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("VALIDATE_FAIL: main.tscn missing")
		quit(1)
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout

	var dolls := scene.get_node_or_null("World/Dolls")
	var claw := scene.get_node_or_null("World/Claw")
	var machine := scene.get_node_or_null("World/Machine")
	var count := 0 if dolls == null else dolls.get_child_count()

	if dolls == null:
		err_msgs.append("Dolls root missing")
	if claw == null:
		err_msgs.append("Claw missing")
	if machine == null:
		err_msgs.append("Machine missing")
	if count < 1:
		err_msgs.append("No dolls spawned")

	if err_msgs.is_empty():
		print("VALIDATE_OK dolls=%d claw_state=%s" % [count, claw.get_state_label()])
		quit(0)
	else:
		push_error("VALIDATE_FAIL: %s" % ", ".join(err_msgs))
		quit(1)
