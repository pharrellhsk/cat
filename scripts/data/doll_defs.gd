class_name DollDefs
extends RefCounted

const PACKED_PATH := "res://assets/config/packed/doll.json"
const COLORS := [
	Color(0.86, 0.62, 0.38),
	Color(0.92, 0.90, 0.88),
	Color(0.18, 0.20, 0.28),
	Color(0.78, 0.42, 0.72),
	Color(0.42, 0.72, 0.52),
]

static var DEFS := {}
static var SPAWN_POOL: Array[String] = []
static var _loaded: bool = false


static func reload() -> void:
	_loaded = false
	ensure_loaded()


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	DEFS = {}
	SPAWN_POOL.clear()
	var rows := ConfigTable.load_array(PACKED_PATH)
	for i in rows.size():
		var row: Dictionary = rows[i]
		var id := "doll_%d" % i
		var weight := maxi(ConfigTable.as_int(row.get("doll_weight", 5), 5), 1)
		DEFS[id] = {
			"display_name": ConfigTable.as_string(row.get("doll_name", id)),
			"rarity": "C",
			"value": maxi(ConfigTable.as_int(row.get("doll_point", 10), 10), 0),
			"mass": maxf(float(weight) / 10.0, 0.3),
			"radius": clampf(0.12 + float(weight) * 0.006, 0.12, 0.24),
			"friction": 0.60,
			"bounce": 0.18,
			"color": COLORS[i % COLORS.size()],
			"doll_weight": weight,
			"effect": ConfigTable.as_int(row.get("doll_effect", 2000)),
			"effect_para": ConfigTable.as_int_array(row.get("effect_para", [])),
			"description": ConfigTable.as_string(row.get("doll_description", "")),
			"raw": row,
		}
		var copies := 2 if i < 3 else 1
		for _n in copies:
			SPAWN_POOL.append(id)
	if SPAWN_POOL.is_empty():
		SPAWN_POOL.clear()
		SPAWN_POOL.append("doll_0")
		DEFS["doll_0"] = {
			"display_name": "基础玩偶",
			"rarity": "C",
			"value": 15,
			"mass": 0.5,
			"radius": 0.16,
			"friction": 0.6,
			"bounce": 0.2,
			"color": COLORS[0],
			"doll_weight": 5,
			"effect": 2000,
			"effect_para": [1],
			"description": "基础玩偶",
			"raw": {},
		}


static func get_def(id: String) -> Dictionary:
	ensure_loaded()
	return DEFS.get(id, DEFS[DEFS.keys()[0]])


static func id_at(index: int) -> String:
	ensure_loaded()
	return "doll_%d" % index


static func random_id(rng: RandomNumberGenerator) -> String:
	ensure_loaded()
	if SPAWN_POOL.is_empty():
		return "doll_0"
	return SPAWN_POOL[rng.randi_range(0, SPAWN_POOL.size() - 1)]
