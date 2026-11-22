class_name GameUI
extends Control
## 画面の情報 (場面のヒント・伝えるボタン・もどる/やりなおす・エンディング文)。画面下はヒント1行とボタンだけにする。

const MARGIN := 8.0
const MOVE_TELOP_DELAY := 1.0

var game: Game
var player: Player
var view: PoemView

var _hint_label: Label
var _ending_label: Label
var _title_label: Label
var _tell_button: Button
var _telop: Label
var _telop_done := false


func setup(g: Game, p: Player, v: PoemView) -> void:
	game = g
	player = p
	view = v
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _make_label("", Vector2(MARGIN, 254))
	_hint_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
	# 扉を開けるとき、画面上部に大きく出る題 (ドットが崩れないよう 2 倍の大きさ)
	_title_label = _make_label("", Vector2(0, 10))
	_title_label.size = Vector2(UIConst.SCREEN.x, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", UIConst.FONT_SIZE * 2)
	_title_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
	_ending_label = _make_label("", Vector2(0, 44))
	_ending_label.size = Vector2(UIConst.SCREEN.x, 16)
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.add_theme_color_override("font_color", UIConst.TEXT_COLOR)

	var x := UIConst.SCREEN.x - MARGIN
	for def in [["やりなおす", game.reset], ["もどる", game.undo]]:
		var btn := _make_button(def[0], def[1])
		x -= btn.size.x
		btn.position = Vector2(x, 250)
		x -= 6.0
	_tell_button = _make_button("伝える", game.tell)
	_tell_button.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
	# 操作のテロップ (部屋の上、詩のあいだの空いたところ)
	_telop = _make_label("クリックで その位置まで 移動", Vector2(0, 44))
	_telop.size = Vector2(UIConst.SCREEN.x, 16)
	_telop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_telop.visible = false
	p.walked_by_click.connect(_hide_move_telop)

	g.state_changed.connect(_refresh)
	g.fx_requested.connect(_on_fx)
	_refresh()


func _refresh() -> void:
	var h := game.hint()
	if h != _hint_label.text:
		_hint_label.text = h
		_hint_label.visible_ratio = 0.0
		create_tween().tween_property(_hint_label, "visible_ratio", 1.0, 0.05 * h.length())
	_tell_button.disabled = game.state.message().is_empty()
	_tell_button.visible = game.capacity() > 0
	if not game.state.d["ended"]:
		_ending_label.text = ""
		_title_label.text = ""


## 伝えるボタンは吹き出しの右にくっついて動く。歩けるようになったら移動のテロップを出す
func _process(_delta: float) -> void:
	_update_move_telop()
	if _tell_button.visible:
		var r := player.bubble.screen_rect()
		_tell_button.position = Vector2(r.end.x + 2, r.position.y + (r.size.y - _tell_button.size.y) / 2.0).round()


func _on_fx(ev: Dictionary) -> void:
	if ev["kind"] == "ending":
		# 詩が消えていく中、上に大きく題、そのあと下に一文
		_title_label.text = game.poem.get("ending_title", "")
		_title_label.visible_ratio = 0.0
		_ending_label.text = game.poem.get("ending_text", "")
		_ending_label.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_interval(1.5)
		tw.tween_property(_title_label, "visible_ratio", 1.0, 2.5)
		tw.tween_interval(1.0)
		tw.tween_property(_ending_label, "visible_ratio", 1.0, 2.5)


## 主人公が歩けるようになったら (部屋が現れたあと)「クリックでその位置まで移動」と出す。
## 一度クリックで歩いたら消える
func _update_move_telop() -> void:
	if _telop_done or _telop.visible or not player.can_move():
		return
	_telop.visible = true
	_telop.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(MOVE_TELOP_DELAY)
	tw.tween_property(_telop, "modulate:a", 1.0, 0.8)


func _hide_move_telop() -> void:
	if _telop_done:
		return
	_telop_done = true
	create_tween().tween_property(_telop, "modulate:a", 0.0, 0.6)


func _make_label(t: String, p: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.position = p
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UIConst.FONT)
	l.add_theme_font_size_override("font_size", UIConst.FONT_SIZE)
	l.add_theme_color_override("font_color", UIConst.TEXT_COLOR)
	add_child(l)
	return l


func _make_button(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", UIConst.FONT)
	b.add_theme_font_size_override("font_size", UIConst.FONT_SIZE)
	b.add_theme_color_override("font_color", Color(UIConst.TEXT_COLOR, 0.75))
	b.add_theme_color_override("font_hover_color", UIConst.HILITE_COLOR)
	b.add_theme_color_override("font_pressed_color", UIConst.HILITE_COLOR)
	b.add_theme_color_override("font_disabled_color", Color(UIConst.TEXT_COLOR, 0.3))
	b.pressed.connect(cb)
	add_child(b)
	b.size = b.get_combined_minimum_size()
	return b
