class_name GameSettings
extends RefCounted

const PACKED_PATH := "res://assets/config/packed/setting.json"
const DEFAULTS := {
	"round_time": 30,
}

static var _values: Dictionary = {}
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_values = DEFAULTS.duplicate()
	if not FileAccess.file_exists(PACKED_PATH):
		push_warning("GameSettings: packed table missing at %s" % PACKED_PATH)
		return
	var file := FileAccess.open(PACKED_PATH, FileAccess.READ)
	if file == null:
		push_warning("GameSettings: failed to open %s" % PACKED_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameSettings: packed table is not a JSON object")
		return
	for key in parsed:
		_values[str(key)] = parsed[key]


static func get_int(key: String, fallback: int = 0) -> int:
	ensure_loaded()
	var value: Variant = _values.get(key, fallback)
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			return int(value)
		_:
			return fallback


static func get_float(key: String, fallback: float = 0.0) -> float:
	ensure_loaded()
	var value: Variant = _values.get(key, fallback)
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_STRING:
			return float(value)
		_:
			return fallback
