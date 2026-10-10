class_name ExitChute
extends Area3D

signal doll_exited(doll: Doll, value: int)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false


func _on_body_entered(body: Node3D) -> void:
	var doll := body as Doll
	if doll == null or doll.is_collected or doll.is_held:
		return
	# Small delay so the doll visually falls into the chute.
	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(doll) or doll.is_collected or doll.is_held:
		return
	var value := doll.value
	doll_exited.emit(doll, value)
	doll.mark_collected()
