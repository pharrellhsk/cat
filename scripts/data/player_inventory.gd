class_name PlayerInventory
extends RefCounted

signal changed

var gold: int = 0
var coins: Array = []
var goods: Array = []
var dolls: Array = []


func reset() -> void:
	gold = 0
	coins.clear()
	goods.clear()
	dolls.clear()
	changed.emit()


func add_gold(amount: int) -> void:
	gold += maxi(amount, 0)
	changed.emit()


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	changed.emit()
	return true


func add_start_coins(count: int) -> void:
	for _i in maxi(count, 0):
		coins.append({
			"coin_name": "普通游戏币",
			"coin_effect": 1001,
			"effect_para": [],
		})
	changed.emit()


func add_shop_coin(def: Dictionary) -> void:
	coins.append({
		"coin_name": ConfigTable.as_string(def.get("coin_name", "硬币")),
		"coin_effect": ConfigTable.as_int(def.get("coin_effect", 1001)),
		"effect_para": ConfigTable.as_int_array(def.get("effect_para", [])),
	})
	changed.emit()


func coin_count() -> int:
	return coins.size()


func take_coin() -> Dictionary:
	if coins.is_empty():
		return {}
	var item: Dictionary = coins.pop_front()
	changed.emit()
	return item


func add_goods(def: Dictionary) -> void:
	goods.append({
		"goods_name": ConfigTable.as_string(def.get("goods_name", "道具")),
		"goods_effect": ConfigTable.as_int(def.get("goods_effect", 0)),
		"effect_para": ConfigTable.as_int_array(def.get("effect_para", [])),
		"uses": maxi(ConfigTable.as_int(def.get("goods_limit", 1)), 1),
	})
	changed.emit()


func use_first_goods() -> Dictionary:
	return use_goods_at(0)


func use_goods_at(index: int) -> Dictionary:
	if index < 0 or index >= goods.size():
		return {}
	var item: Dictionary = goods[index]
	item["uses"] = maxi(int(item.get("uses", 1)) - 1, 0)
	if int(item["uses"]) <= 0:
		goods.remove_at(index)
	else:
		goods[index] = item
	changed.emit()
	return item


func use_goods_by_effect(effect_id: int) -> Dictionary:
	for i in goods.size():
		if int(goods[i].get("goods_effect", 0)) == effect_id:
			return use_goods_at(i)
	return {}


func goods_summary() -> String:
	if goods.is_empty():
		return "无"
	var names: Array[String] = []
	for item in goods:
		names.append("%s(%d)" % [item.get("goods_name", "道具"), int(item.get("uses", 0))])
	return "、".join(names)


func add_doll(def: Dictionary, id: String) -> void:
	dolls.append({
		"id": id,
		"doll_name": ConfigTable.as_string(def.get("doll_name", id)),
		"effect": ConfigTable.as_int(def.get("doll_effect", 2000)),
		"effect_para": ConfigTable.as_int_array(def.get("effect_para", [])),
	})
	changed.emit()


func dolls_summary() -> String:
	if dolls.is_empty():
		return "无"
	var names: Array[String] = []
	for item in dolls:
		names.append(str(item.get("doll_name", "玩偶")))
	return "、".join(names)
