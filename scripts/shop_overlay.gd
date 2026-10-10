class_name ShopOverlay
extends ColorRect

signal buy_pressed(kind: String, index: int)
signal continue_pressed

var gold_label: Label
var inv_label: Label
var status_label: Label
var continue_button: Button
var list: VBoxContainer
var tab := "coin"


func _init() -> void:
	name = "ShopOverlay"
	visible = false
	z_index = 80
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.02, 0.04, 0.72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 520)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "商店"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)

	gold_label = Label.new()
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 18)
	column.add_child(gold_label)

	inv_label = Label.new()
	inv_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inv_label.add_theme_font_size_override("font_size", 14)
	column.add_child(inv_label)

	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	_add_tab(tabs, "硬币", "coin")
	_add_tab(tabs, "道具", "goods")
	_add_tab(tabs, "玩偶", "doll")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 280)
	column.add_child(scroll)

	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.modulate = Color(1.0, 0.72, 0.45)
	column.add_child(status_label)

	continue_button = Button.new()
	continue_button.custom_minimum_size = Vector2(220, 44)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.text = "进入下一关"
	continue_button.pressed.connect(func():
		continue_pressed.emit()
	)
	column.add_child(continue_button)


func _add_tab(parent: HBoxContainer, title: String, kind: String) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(120, 36)
	button.pressed.connect(func():
		tab = kind
		rebuild_list()
	)
	parent.add_child(button)


func open(continue_is_next: bool, inventory: PlayerInventory) -> void:
	continue_button.text = "进入下一关" if continue_is_next else "返回主菜单"
	status_label.text = ""
	tab = "coin"
	visible = true
	refresh(inventory)
	rebuild_list()


func close() -> void:
	visible = false


func refresh(inventory: PlayerInventory) -> void:
	gold_label.text = "金币  %d" % inventory.gold
	inv_label.text = "硬币栏 %d    道具 %s    玩偶 %s" % [
		inventory.coin_count(),
		inventory.goods_summary(),
		inventory.dolls_summary(),
	]


func set_status(text: String) -> void:
	status_label.text = text


func rebuild_list() -> void:
	ShopCatalog.ensure_loaded()
	for child in list.get_children():
		child.queue_free()
	var items: Array = ShopCatalog.coins
	if tab == "goods":
		items = ShopCatalog.goods
	elif tab == "doll":
		items = ShopCatalog.dolls
	for i in items.size():
		list.add_child(_make_item(tab, i, items[i]))


func _make_item(kind: String, index: int, def: Dictionary) -> Control:
	var row := PanelContainer.new()
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	row.add_child(box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(info)

	var name_label := Label.new()
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.8, 0.84, 0.9)
	var extra := Label.new()
	extra.modulate = Color(0.93, 0.78, 0.48)
	match kind:
		"coin":
			name_label.text = str(def.get("coin_name", "硬币"))
			desc.text = str(def.get("coin_description", ""))
			extra.text = "价格 %d 金币" % ConfigTable.as_int(def.get("coin_price", 0))
		"goods":
			name_label.text = str(def.get("goods_name", "道具"))
			desc.text = str(def.get("goods_description", ""))
			extra.text = "价格 %d 金币 · 使用次数 %d" % [
				ConfigTable.as_int(def.get("goods_price", 0)),
				ConfigTable.as_int(def.get("goods_limit", 1)),
			]
		_:
			name_label.text = str(def.get("doll_name", "玩偶"))
			desc.text = str(def.get("doll_description", ""))
			extra.text = "价格 %d 金币 · 分数 %d · 重量 %d" % [
				ConfigTable.as_int(def.get("doll_price", 0)),
				ConfigTable.as_int(def.get("doll_point", 0)),
				ConfigTable.as_int(def.get("doll_weight", 0)),
			]
	info.add_child(name_label)
	info.add_child(desc)
	info.add_child(extra)

	var buy := Button.new()
	buy.text = "购买"
	buy.custom_minimum_size = Vector2(88, 36)
	buy.pressed.connect(func():
		buy_pressed.emit(kind, index)
	)
	box.add_child(buy)
	return row
