class_name CoinKindIcon
extends PanelContainer

signal hovered(title: String, body: String)
signal unhovered

var kind_title := ""
var kind_body := ""

var _count_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.86, 0.68, 0.28)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 0.95, 0.75, 0.7)
	add_theme_stylebox_override("panel", style)
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_count_label.add_theme_font_size_override("font_size", 13)
	_count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_count_label.add_theme_constant_override("shadow_offset_x", 1)
	_count_label.add_theme_constant_override("shadow_offset_y", 1)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)


func _ready() -> void:
	mouse_entered.connect(func():
		hovered.emit(kind_title, kind_body)
	)
	mouse_exited.connect(func():
		unhovered.emit()
	)


func setup(title: String, body: String, count: int, accent: Color) -> void:
	kind_title = title
	kind_body = body
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = accent
	add_theme_stylebox_override("panel", style)
	_count_label.text = "x%d" % count
