class_name GameHUD
extends CanvasLayer

signal settings_restart_pressed
signal settings_title_pressed
signal result_next_pressed
signal result_title_pressed
signal shop_buy_pressed(kind: String, index: int)
signal shop_continue_pressed

@onready var money_label: Label = %MoneyLabel
@onready var target_label: Label = %TargetLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var coins_label: Label = %CoinsLabel
@onready var meta_label: Label = %MetaLabel
@onready var state_label: Label = %StateLabel
@onready var banner_label: Label = %BannerLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var grab_button: Button = %GrabButton
@onready var coin_button: Button = %CoinButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_overlay: Control = %SettingsOverlay
@onready var settings_resume_button: Button = %SettingsResumeButton
@onready var settings_restart_button: Button = %SettingsRestartButton
@onready var settings_title_button: Button = %SettingsTitleButton

var _banner_tween: Tween
var _result_kind: int = RoundManager.ResultKind.FAIL
var gold_label: Label
var goods_label: Label
var dolls_label: Label
var shop: ShopOverlay
var coin_icon_row: VBoxContainer
var hover_card: HoverCard
var _hover_source := ""

const HOVER_CARD_SCENE := preload("res://scenes/ui/hover_card.tscn")
const COIN_COLORS := [
	Color(0.86, 0.68, 0.28),
	Color(0.42, 0.72, 0.86),
	Color(0.78, 0.48, 0.72),
	Color(0.52, 0.78, 0.48),
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	result_panel.visible = false
	banner_label.text = ""
	grab_button.text = "下抓"
	_build_inventory_labels()
	_build_shop()
	_build_hover_card()
	_disable_focus_steal()
	restart_button.focus_mode = Control.FOCUS_NONE
	grab_button.focus_mode = Control.FOCUS_NONE
	coin_button.focus_mode = Control.FOCUS_NONE
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_overlay.visible = false
	settings_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_button.pressed.connect(open_settings)
	settings_resume_button.pressed.connect(close_settings)
	settings_restart_button.pressed.connect(func():
		close_settings()
		settings_restart_pressed.emit()
	)
	settings_title_button.pressed.connect(func():
		close_settings()
		settings_title_pressed.emit()
	)
	restart_button.pressed.connect(_on_result_pressed)


func _input(event: InputEvent) -> void:
	if is_shop_open():
		return
	if not _is_escape(event):
		return
	toggle_settings()
	get_viewport().set_input_as_handled()


func _is_escape(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE
	return false


func is_settings_open() -> bool:
	return settings_overlay.visible


func is_shop_open() -> bool:
	return shop != null and shop.visible


func toggle_settings() -> void:
	if settings_overlay.visible:
		close_settings()
	else:
		open_settings()


func open_settings() -> void:
	if is_shop_open():
		return
	settings_overlay.visible = true
	get_tree().paused = true
	settings_resume_button.grab_focus()


func close_settings() -> void:
	settings_overlay.visible = false
	if not is_shop_open():
		get_tree().paused = false
	settings_resume_button.release_focus()
	get_viewport().gui_release_focus()


func _disable_focus_steal() -> void:
	# Keep keyboard events going to the game, not HUD controls.
	var root := $Root as Control
	_set_tree_mouse_ignore(root)
	progress_bar.focus_mode = Control.FOCUS_NONE
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_tree_mouse_ignore(node: Node) -> void:
	if node is Control:
		var c := node as Control
		var interactive := c == grab_button or c == restart_button or c == result_panel or c == coin_button \
				or c == settings_button or c == settings_overlay or settings_overlay.is_ancestor_of(c) \
				or (shop != null and (c == shop or shop.is_ancestor_of(c))) \
				or (coin_icon_row != null and (c == coin_icon_row or coin_icon_row.is_ancestor_of(c))) \
				or (hover_card != null and c == hover_card)
		if not interactive:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_set_tree_mouse_ignore(child)


func set_money(total: int) -> void:
	money_label.text = "分数  %d" % total


func set_target_progress(earned: int, target: int) -> void:
	target_label.text = "本关  %d / %d" % [earned, target]
	progress_bar.max_value = maxf(float(target), 1.0)
	progress_bar.value = float(earned)


func set_stage_info(stage: int, stage_count: int) -> void:
	meta_label.text = "第%d关 / %d" % [stage, stage_count]


func set_coins(coins: int, credited: bool) -> void:
	coins_label.text = "硬币  %d" % coins
	if coins <= 0:
		coins_label.modulate = Color(1.0, 0.45, 0.35)
	else:
		coins_label.modulate = Color.WHITE
	if credited:
		coin_button.text = "已投币"
	else:
		coin_button.text = "投币"


func set_coin_enabled(enabled: bool) -> void:
	coin_button.disabled = not enabled


func set_claw_state(text: String, grip: float) -> void:
	if grip > 0.0:
		state_label.text = "%s · 力量 %.0f" % [text, grip]
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


func set_inventory(inventory: PlayerInventory) -> void:
	if gold_label:
		gold_label.text = "金币  %d" % inventory.gold
	if goods_label:
		goods_label.text = "道具  %s" % inventory.goods_summary()
	if dolls_label:
		dolls_label.text = "玩偶  %s" % inventory.dolls_summary()
	_refresh_coin_icons(inventory)
	if is_shop_open():
		shop.refresh(inventory)


func show_result(kind: int, stage: int, earned: int, target: int, total: int, gold_reward: int = 0) -> void:
	_result_kind = kind
	result_panel.visible = true
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_button.focus_mode = Control.FOCUS_ALL
	match kind:
		RoundManager.ResultKind.NEXT:
			result_label.text = "第%d关达标\n得分 %d / 目标 %d\n累计分数 %d\n本关获得金币 %d" % [stage, earned, target, total, gold_reward]
			restart_button.text = "确定"
		RoundManager.ResultKind.CLEAR:
			result_label.text = "全部通关\n第%d关得分 %d / 目标 %d\n累计分数 %d\n本关获得金币 %d" % [stage, earned, target, total, gold_reward]
			restart_button.text = "确定"
		_:
			result_label.text = "游戏失败\n第%d关得分 %d / 目标 %d\n未达目标，无法进入下一关\n累计分数 %d" % [stage, earned, target, total]
			restart_button.text = "返回主菜单"


func _on_result_pressed() -> void:
	if _result_kind == RoundManager.ResultKind.FAIL:
		result_title_pressed.emit()
		return
	hide_result()
	show_shop(_result_kind == RoundManager.ResultKind.NEXT)


func hide_result() -> void:
	result_panel.visible = false
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.release_focus()


func show_shop(continue_is_next: bool) -> void:
	if shop == null:
		return
	close_settings()
	shop.open(continue_is_next, shop_inventory())
	get_tree().paused = true


func hide_shop() -> void:
	if shop:
		shop.close()
	get_tree().paused = false
	get_viewport().gui_release_focus()


func refresh_shop(inventory: PlayerInventory) -> void:
	if shop:
		shop.refresh(inventory)
		shop.rebuild_list()


func show_shop_status(text: String) -> void:
	if shop:
		shop.set_status(text)


func shop_inventory() -> PlayerInventory:
	var parent := get_parent()
	if parent and parent.has_node("RoundManager"):
		return parent.get_node("RoundManager").inventory
	return PlayerInventory.new()


func _build_inventory_labels() -> void:
	var right: VBoxContainer = meta_label.get_parent()
	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gold_label.add_theme_font_size_override("font_size", 16)
	gold_label.text = "金币  0"
	right.add_child(gold_label)
	goods_label = Label.new()
	goods_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goods_label.add_theme_font_size_override("font_size", 12)
	goods_label.modulate = Color(0.8, 0.85, 0.9)
	goods_label.text = "道具  无"
	right.add_child(goods_label)
	dolls_label = Label.new()
	dolls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dolls_label.add_theme_font_size_override("font_size", 12)
	dolls_label.modulate = Color(0.8, 0.85, 0.9)
	dolls_label.text = "玩偶  无"
	right.add_child(dolls_label)
	_build_coin_icon_column()


func _build_coin_icon_column() -> void:
	coin_icon_row = VBoxContainer.new()
	coin_icon_row.name = "CoinKindColumn"
	coin_icon_row.alignment = BoxContainer.ALIGNMENT_END
	coin_icon_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_icon_row.add_theme_constant_override("separation", 6)
	coin_icon_row.mouse_filter = Control.MOUSE_FILTER_STOP
	var parent := coins_label.get_parent()
	parent.add_child(coin_icon_row)
	parent.move_child(coin_icon_row, coins_label.get_index() + 1)


func _build_hover_card() -> void:
	hover_card = HOVER_CARD_SCENE.instantiate() as HoverCard
	add_child(hover_card)


func _refresh_coin_icons(inventory: PlayerInventory) -> void:
	if coin_icon_row == null:
		return
	for child in coin_icon_row.get_children():
		child.queue_free()
	var kinds: Array = inventory.coin_kinds()
	for i in kinds.size():
		var kind: Dictionary = kinds[i]
		var icon := CoinKindIcon.new()
		var title := str(kind.get("coin_name", "硬币"))
		var body := str(kind.get("coin_description", ""))
		if body == "":
			body = "用于投币下抓"
		icon.setup(title, body, int(kind.get("count", 1)), COIN_COLORS[i % COIN_COLORS.size()])
		icon.hovered.connect(func(title: String, body: String):
			show_hover_card(title, body, "coin")
		)
		icon.unhovered.connect(func():
			hide_hover_card("coin")
		)
		coin_icon_row.add_child(icon)


func show_hover_card(title: String, body: String, source: String = "ui") -> void:
	_hover_source = source
	if hover_card:
		hover_card.show_info(title, body)


func hide_hover_card(source: String = "") -> void:
	if source != "" and _hover_source != source:
		return
	_hover_source = ""
	if hover_card:
		hover_card.hide_card()


func is_pointer_over_ui(pos: Vector2) -> bool:
	if coin_icon_row and coin_icon_row.get_global_rect().has_point(pos):
		return true
	if result_panel.visible and result_panel.get_global_rect().has_point(pos):
		return true
	return false


func _build_shop() -> void:
	shop = ShopOverlay.new()
	$Root.add_child(shop)
	shop.buy_pressed.connect(func(kind: String, index: int):
		shop_buy_pressed.emit(kind, index)
	)
	shop.continue_pressed.connect(func():
		hide_shop()
		shop_continue_pressed.emit()
	)
