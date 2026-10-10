class_name ShopCatalog
extends RefCounted

const COIN_PATH := "res://assets/config/packed/coin.json"
const GOODS_PATH := "res://assets/config/packed/goods.json"
const DOLL_PATH := "res://assets/config/packed/doll.json"

static var coins: Array = []
static var goods: Array = []
static var dolls: Array = []
static var _loaded: bool = false


static func reload() -> void:
	_loaded = false
	ensure_loaded()


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	coins = ConfigTable.load_array(COIN_PATH)
	goods = ConfigTable.load_array(GOODS_PATH)
	dolls = ConfigTable.load_array(DOLL_PATH)


static func coin_at(index: int) -> Dictionary:
	ensure_loaded()
	if index < 0 or index >= coins.size():
		return {}
	return coins[index]


static func goods_at(index: int) -> Dictionary:
	ensure_loaded()
	if index < 0 or index >= goods.size():
		return {}
	return goods[index]


static func doll_at(index: int) -> Dictionary:
	ensure_loaded()
	if index < 0 or index >= dolls.size():
		return {}
	return dolls[index]


static func coin_by_name(coin_name: String) -> Dictionary:
	ensure_loaded()
	for item in coins:
		if str(item.get("coin_name", "")) == coin_name:
			return item
	return {}
