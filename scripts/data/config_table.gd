class_name ConfigTable
extends RefCounted


static func load_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_warning("ConfigTable: missing %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("ConfigTable: failed to open %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("ConfigTable: %s is not a JSON array" % path)
		return []
	return parsed


static func as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			if str(value).strip_edges() == "":
				return fallback
			return int(value)
		_:
			return fallback


static func as_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	return str(value)


static func as_int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	match typeof(value):
		TYPE_ARRAY:
			for item in value:
				result.append(as_int(item, 0))
		TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			result.append(as_int(value, 0))
	return result
