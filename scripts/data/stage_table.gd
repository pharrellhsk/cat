class_name StageTable
extends RefCounted

const PACKED_PATH := "res://assets/config/packed/stage.json"
const DEFAULTS := [
	{"name": 1, "score": 30},
]

static var _stages: Array = []
static var _loaded: bool = false


static func reload() -> void:
	_loaded = false
	ensure_loaded()


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_stages = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(PACKED_PATH):
		push_warning("StageTable: packed table missing at %s" % PACKED_PATH)
		return
	var file := FileAccess.open(PACKED_PATH, FileAccess.READ)
	if file == null:
		push_warning("StageTable: failed to open %s" % PACKED_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("StageTable: packed table is not a JSON array")
		return
	var loaded: Array = []
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		loaded.append({
			"name": _as_int(item.get("name", 0)),
			"score": maxi(_as_int(item.get("score", 0)), 0),
			"coin": maxi(_as_int(item.get("coin", 0)), 0),
		})
	loaded.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["name"]) < int(b["name"])
	)
	if not loaded.is_empty():
		_stages = loaded


static func count() -> int:
	ensure_loaded()
	return _stages.size()


static func stage_id_at(index: int) -> int:
	ensure_loaded()
	if _stages.is_empty():
		return 1
	var clamped := clampi(index, 0, _stages.size() - 1)
	return int(_stages[clamped]["name"])


static func score_at(index: int) -> int:
	ensure_loaded()
	if _stages.is_empty():
		return 30
	var clamped := clampi(index, 0, _stages.size() - 1)
	return int(_stages[clamped]["score"])


static func coin_at(index: int) -> int:
	ensure_loaded()
	if _stages.is_empty():
		return 0
	var clamped := clampi(index, 0, _stages.size() - 1)
	return int(_stages[clamped].get("coin", 0))


static func _as_int(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			return int(value)
		_:
			return 0
