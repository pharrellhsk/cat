class_name RoundManager
extends Node

signal round_started(target: int, duration: float)
signal earnings_changed(round_earned: int, total_money: int)
signal timer_updated(time_left: float)
signal round_settled(success: bool, round_earned: int, target: int, total_money: int)
signal banner(text: String)

const ROUND_DURATION := 30.0
## Game 1 Round 1 target from GDD.
const ROUND_TARGET := 30

var total_money: int = 0
var round_earned: int = 0
var time_left: float = ROUND_DURATION
var target: int = ROUND_TARGET
var active: bool = false
var settled: bool = false


func start_round() -> void:
	round_earned = 0
	time_left = ROUND_DURATION
	target = ROUND_TARGET
	active = true
	settled = false
	round_started.emit(target, ROUND_DURATION)
	earnings_changed.emit(round_earned, total_money)
	timer_updated.emit(time_left)
	banner.emit("第1局 · 第1回合  目标 %d" % target)


func _process(delta: float) -> void:
	if not active or settled:
		return
	time_left = maxf(time_left - delta, 0.0)
	timer_updated.emit(time_left)
	if time_left <= 0.0:
		_settle()


func add_earn(value: int, doll_name: String) -> void:
	if not active or settled:
		return
	round_earned += value
	earnings_changed.emit(round_earned, total_money)
	banner.emit("+%d  %s" % [value, doll_name])


func _settle() -> void:
	if settled:
		return
	settled = true
	active = false
	var success := round_earned >= target
	if success:
		total_money += round_earned
	earnings_changed.emit(round_earned, total_money)
	round_settled.emit(success, round_earned, target, total_money)
	if success:
		banner.emit("达标！本回合 +%d → 总金额 %d" % [round_earned, total_money])
	else:
		banner.emit("未达标：%d / %d" % [round_earned, target])


func restart_round() -> void:
	start_round()
