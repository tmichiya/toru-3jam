class_name GameUI
extends Control
## 画面の情報 (詩のしおり・場面のヒント・伝えるボタン・もどる/やりなおす・エンディング文)。

const MARGIN := 8.0
const TAB_Y := 2.0

var game: Game
var player: Player
var view: PoemView

var _hint_label: Label
var _ending_label: Label
var _tell_button: Button
var _tabs: Dictionary = {}  # 詩の id -> Button


func setup(g: Game, p: Player, v: PoemView) -> void:
	game = g
	player = p
	view = v
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _make_label("", Vector2(MARGIN, 254))
	_hint_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
	var help := _make_label("「逆さ」「ずれる」は ことばに かさねる", Vector2(MARGIN, 240))
	help.modulate.a = 0.55
	_ending_label = _make_label("", Vector2(0, 60))
	_ending_label.size = Vector2(UIConst.SCREEN.x, 16)
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)

	var x := UIConst.SCREEN.x - MARGIN
	for def in [["やりなおす", game.reset], ["もどる", game.undo]]:
		var btn := _make_button(def[0], def[1])
		x -= btn.size.x
		btn.position = Vector2(x, 250)
		x -= 6.0
	_tell_button = _make_button("伝える", game.tell)
	_tell_button.add_theme_color_override("font_color", UIConst.HILITE_COLOR)

	g.state_changed.connect(_refresh)
	g.fx_requested.connect(_on_fx)
	v.page_changed.connect(_refresh_tabs)
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
	_refresh_tabs()


## 手に入れた詩のしおり。左上に「一 二 三 四」と並び、開いているものが光る
func _refresh_tabs() -> void:
	var got := game.state.got()
	for pid in _tabs.keys():
		if not pid in got:
			_tabs[pid].queue_free()
			_tabs.erase(pid)
	var x := MARGIN
	for pid in got:
		var b: Button = _tabs.get(pid)
		if b == null:
			b = _make_button(game.state.poem_title(pid), view.select_page.bind(pid))
			_tabs[pid] = b
		b.position = Vector2(x, TAB_Y)
		var on: bool = pid == view.page
		b.add_theme_color_override("font_color", UIConst.HILITE_COLOR if on else Color(UIConst.TEXT_COLOR, 0.5))
		x += b.size.x + 2.0


## 画面座標 p にあるしおりの詩 id。なければ ""
func tab_at(p: Vector2) -> String:
	for pid in _tabs:
		if (_tabs[pid] as Button).get_global_rect().grow(2.0).has_point(p):
			return pid
	return ""


## 伝えるボタンは吹き出しの右にくっついて動く
func _process(_delta: float) -> void:
	if _tell_button.visible:
		var r := player.bubble.screen_rect()
		_tell_button.position = Vector2(r.end.x + 2, r.position.y + (r.size.y - _tell_button.size.y) / 2.0).round()


func _on_fx(ev: Dictionary) -> void:
	if ev["kind"] == "ending":
		_ending_label.text = game.poem.get("ending_text", "")
		_ending_label.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_interval(3.5)
		tw.tween_property(_ending_label, "visible_ratio", 1.0, 3.0)


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
