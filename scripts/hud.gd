class_name GameHUD
extends CanvasLayer

@onready var money_label: Label = %MoneyLabel
@onready var target_label: Label = %TargetLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var timer_label: Label = %TimerLabel
@onready var state_label: Label = %StateLabel
@onready var banner_label: Label = %BannerLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton

var _banner_tween: Tween


func _ready() -> void:
	result_panel.visible = false
	banner_label.text = ""


func set_money(total: int) -> void:
	money_label.text = "总金额  %d" % total


func set_target_progress(earned: int, target: int) -> void:
	target_label.text = "本回合  %d / %d" % [earned, target]
	progress_bar.max_value = float(target)
	progress_bar.value = float(earned)


func set_timer(time_left: float) -> void:
	timer_label.text = "剩余  %.1fs" % time_left
	if time_left <= 5.0:
		timer_label.modulate = Color(1.0, 0.45, 0.35)
	else:
		timer_label.modulate = Color.WHITE


func set_claw_state(text: String, grip: float) -> void:
	if grip > 0.0:
		state_label.text = "%s · 抓力 %.0fN" % [text, grip]
	else:
		state_label.text = text


func show_banner(text: String) -> void:
	banner_label.text = text
	banner_label.modulate.a = 1.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.6)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.6)


func show_result(success: bool, earned: int, target: int, total: int) -> void:
	result_panel.visible = true
	if success:
		result_label.text = "回合结算：达标\n收益 %d / 目标 %d\n总金额 %d" % [earned, target, total]
	else:
		result_label.text = "回合结算：未达标\n收益 %d / 目标 %d\n（原型：收益未入账）\n总金额 %d" % [earned, target, total]


func hide_result() -> void:
	result_panel.visible = false
