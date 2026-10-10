class_name HoverCard
extends PanelContainer

const OFFSET := Vector2(18, 18)
const MIN_WIDTH := 160.0
const MAX_WIDTH := 280.0
const PAD_X := 24.0
const PAD_Y := 16.0
const GAP := 4.0

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var card_column: VBoxContainer = $CardColumn


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 120
	set_process(false)
	set_as_top_level(true)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func show_info(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	_fit_to_text()
	visible = true
	set_process(true)
	_follow_mouse()


func hide_card() -> void:
	visible = false
	set_process(false)


func _process(_delta: float) -> void:
	if visible:
		_follow_mouse()


func _fit_to_text() -> void:
	var title_font := title_label.get_theme_font("font")
	var body_font := body_label.get_theme_font("font")
	if title_font == null:
		title_font = ThemeDB.fallback_font
	if body_font == null:
		body_font = ThemeDB.fallback_font
	var title_size := title_label.get_theme_font_size("font_size")
	var body_size := body_label.get_theme_font_size("font_size")
	var title_w := title_font.get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var body_w := 0.0
	for line in body_label.text.split("\n"):
		body_w = maxf(body_w, body_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x)
	var width := clampf(maxf(title_w, body_w) + PAD_X, MIN_WIDTH, MAX_WIDTH)
	title_label.custom_minimum_size = Vector2(width - PAD_X, 0)
	body_label.custom_minimum_size = Vector2(width - PAD_X, 0)
	custom_minimum_size = Vector2(width, 0)
	size = Vector2.ZERO
	reset_size()
	var height := title_label.get_minimum_size().y + body_label.get_minimum_size().y + GAP + PAD_Y
	custom_minimum_size = Vector2(width, height)
	size = Vector2(width, height)


func _follow_mouse() -> void:
	var pos := get_viewport().get_mouse_position() + OFFSET
	var card_size := size
	var view := get_viewport_rect().size
	pos.x = clampf(pos.x, 8.0, maxf(8.0, view.x - card_size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, view.y - card_size.y - 8.0))
	global_position = pos
