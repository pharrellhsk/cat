class_name RoundManager
extends Node

enum ResultKind { FAIL, NEXT, CLEAR }

signal round_started(stage: int, stage_count: int, target: int, coins: int)
signal earnings_changed(round_earned: int, total_money: int)
signal coins_changed(coins: int, credit_ready: bool)
signal inventory_changed
signal round_settled(kind: int, stage: int, round_earned: int, target: int, total_money: int, gold_reward: int)
signal banner(text: String)

const SETTLE_DELAY := 1.2

var inventory := PlayerInventory.new()
var total_money: int = 0
var round_earned: int = 0
var credit_ready: bool = false
var target: int = 30
var stage: int = 1
var stage_index: int = 0
var stage_count: int = 1
var gold_reward: int = 0
var active: bool = false
var settled: bool = false
var last_result: int = ResultKind.FAIL
var last_inserted_coin: Dictionary = {}
var claw_power: int = 15
var slip_immune_grabs: int = 0

var _settle_token: int = 0


func _ready() -> void:
	inventory.changed.connect(func():
		coins_changed.emit(inventory.coin_count(), credit_ready)
		inventory_changed.emit()
	)


func start_run() -> void:
	GameSettings.reload()
	StageTable.reload()
	DollDefs.reload()
	ShopCatalog.reload()
	inventory.reset()
	stage_index = 0
	total_money = 0
	claw_power = GameSettings.get_int("claw_power", 15)
	slip_immune_grabs = 0
	inventory.add_start_coins(GameSettings.get_int("start_coin", 5))
	_start_current_stage(true)


func start_round() -> void:
	start_run()


func start_next_stage() -> void:
	if last_result != ResultKind.NEXT:
		return
	stage_index += 1
	_start_current_stage(false)


func restart_round() -> void:
	start_run()


func _start_current_stage(_is_new_run: bool) -> void:
	stage_count = maxi(StageTable.count(), 1)
	stage_index = clampi(stage_index, 0, stage_count - 1)
	stage = StageTable.stage_id_at(stage_index)
	target = StageTable.score_at(stage_index)
	gold_reward = 0
	round_earned = 0
	credit_ready = false
	last_inserted_coin = {}
	active = true
	settled = false
	last_result = ResultKind.FAIL
	_settle_token += 1
	round_started.emit(stage, stage_count, target, inventory.coin_count())
	earnings_changed.emit(round_earned, total_money)
	coins_changed.emit(inventory.coin_count(), credit_ready)
	inventory_changed.emit()
	banner.emit("第%d关 / %d  目标 %d" % [stage, stage_count, target])
	if inventory.coin_count() <= 0:
		banner.emit("没有硬币，本关结束")
		_schedule_settle()


func can_insert_coin() -> bool:
	return active and not settled and not credit_ready and inventory.coin_count() > 0


func try_insert_coin() -> bool:
	if not can_insert_coin():
		return false
	last_inserted_coin = inventory.take_coin()
	credit_ready = true
	coins_changed.emit(inventory.coin_count(), credit_ready)
	banner.emit("投币成功，可以下抓")
	return true


func consume_credit() -> void:
	if not credit_ready:
		return
	credit_ready = false
	coins_changed.emit(inventory.coin_count(), credit_ready)


func on_grab_cycle_finished() -> void:
	credit_ready = false
	coins_changed.emit(inventory.coin_count(), credit_ready)
	if inventory.coin_count() <= 0:
		_schedule_settle()


func add_earn(value: int, doll_name: String) -> void:
	if not active or settled:
		return
	round_earned += value
	earnings_changed.emit(round_earned, total_money)
	banner.emit("+%d  %s" % [value, doll_name])


func try_buy(kind: String, index: int) -> String:
	var def: Dictionary = {}
	var price := 0
	match kind:
		"coin":
			def = ShopCatalog.coin_at(index)
			price = ConfigTable.as_int(def.get("coin_price", 0))
		"goods":
			def = ShopCatalog.goods_at(index)
			price = ConfigTable.as_int(def.get("goods_price", 0))
		"doll":
			def = ShopCatalog.doll_at(index)
			price = ConfigTable.as_int(def.get("doll_price", 0))
		_:
			return "未知商品"
	if def.is_empty():
		return "商品不存在"
	if not inventory.spend_gold(price):
		return "金币不足"
	match kind:
		"coin":
			inventory.add_shop_coin(def)
			banner.emit("购买硬币：%s" % def.get("coin_name", "硬币"))
		"goods":
			inventory.add_goods(def)
			banner.emit("购买道具：%s" % def.get("goods_name", "道具"))
		"doll":
			inventory.add_doll(def, DollDefs.id_at(index))
			banner.emit("购买玩偶：%s" % def.get("doll_name", "玩偶"))
	return ""


func prepare_grab() -> bool:
	consume_credit()
	if slip_immune_grabs <= 0:
		use_goods_by_effect(3001)
	var immune := consume_slip_immunity()
	if int(last_inserted_coin.get("coin_effect", 1001)) == 1002:
		_apply_arcade_coin()
	return immune


func use_goods() -> Dictionary:
	return use_goods_by_effect(3001)


func use_goods_by_effect(effect_id: int) -> Dictionary:
	var used := inventory.use_goods_by_effect(effect_id)
	if used.is_empty():
		return {}
	_apply_goods(used)
	return used


func _apply_goods(used: Dictionary) -> void:
	if int(used.get("goods_effect", 0)) == 3001:
		var para: Array = used.get("effect_para", [1])
		var grabs := 1
		if not para.is_empty():
			grabs = maxi(int(para[0]), 1)
		slip_immune_grabs += grabs
		banner.emit("道具生效：钩爪加固 %d 次" % grabs)
	else:
		banner.emit("使用道具：%s" % used.get("goods_name", "道具"))


func consume_slip_immunity() -> bool:
	if slip_immune_grabs <= 0:
		return false
	slip_immune_grabs -= 1
	return true


func _apply_arcade_coin() -> void:
	var para: Array = last_inserted_coin.get("effect_para", [1, 2])
	var count := 1
	var mult := 2
	if para.size() >= 1:
		count = maxi(int(para[0]), 1)
	if para.size() >= 2:
		mult = maxi(int(para[1]), 1)
	banner.emit("电玩币生效：%d 只玩偶分数 × %d" % [count, mult])


func _schedule_settle() -> void:
	_settle_token += 1
	var token := _settle_token
	await get_tree().create_timer(SETTLE_DELAY).timeout
	if token != _settle_token or settled or not active:
		return
	if inventory.coin_count() > 0 or credit_ready:
		return
	_settle()


func _settle() -> void:
	if settled:
		return
	settled = true
	active = false
	credit_ready = false
	var success := round_earned >= target
	gold_reward = 0
	if success:
		total_money += round_earned
		gold_reward = StageTable.coin_at(stage_index)
		inventory.add_gold(gold_reward)
		if stage_index >= stage_count - 1:
			last_result = ResultKind.CLEAR
			banner.emit("全部通关！获得金币 %d" % gold_reward)
		else:
			last_result = ResultKind.NEXT
			banner.emit("达标！获得金币 %d" % gold_reward)
	else:
		last_result = ResultKind.FAIL
		banner.emit("未达标：%d / %d" % [round_earned, target])
	earnings_changed.emit(round_earned, total_money)
	coins_changed.emit(inventory.coin_count(), credit_ready)
	round_settled.emit(last_result, stage, round_earned, target, total_money, gold_reward)
