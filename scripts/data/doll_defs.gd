class_name DollDefs
extends RefCounted

## C-tier dolls for the MVP prototype.
const DEFS := {
	"bear": {
		"display_name": "普通熊",
		"rarity": "C",
		"value": 15,
		"mass": 1.0,
		"radius": 0.18,
		"friction": 0.60,
		"bounce": 0.20,
		"color": Color(0.86, 0.62, 0.38),
	},
	"rabbit": {
		"display_name": "兔子",
		"rarity": "C",
		"value": 10,
		"mass": 0.8,
		"radius": 0.15,
		"friction": 0.50,
		"bounce": 0.30,
		"color": Color(0.92, 0.90, 0.88),
	},
	"penguin": {
		"display_name": "企鹅",
		"rarity": "C",
		"value": 25,
		"mass": 1.3,
		"radius": 0.20,
		"friction": 0.70,
		"bounce": 0.10,
		"color": Color(0.18, 0.20, 0.28),
	},
}

const SPAWN_POOL: Array[String] = [
	"bear", "bear", "bear",
	"rabbit", "rabbit", "rabbit",
	"penguin", "penguin",
]


static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["bear"])
