class_name GameUI
extends Control
## 画面端の情報 (目標のヒント・操作説明・操作ボタン・エンディング文)。UI は日本語のまま。

const MARGIN := 8.0

var game: Game

var _hint_label: Label
var _ending_label: Label


func setup(g: Game) -> void:
	game = g
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = _make_label("", Vector2(0, 12))
	_hint_label.size = Vector2(UIConst.SCREEN.x, 16)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
	var help := _make_label("クリック：ことばの ちから ／ ドラッグ：はこぶ", Vector2(MARGIN, 250))
	help.modulate.a = 0.6
	_ending_label = _make_label("", Vector2(0, 214))
	_ending_label.size = Vector2(UIConst.SCREEN.x, 16)
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)

	var x := UIConst.SCREEN.x - MARGIN
	for def in [["やりなおす", game.reset], ["もどる", game.undo]]:
		var btn := _make_button(def[0], def[1])
		x -= btn.size.x
		btn.position = Vector2(x, 248)
		x -= 6.0

	g.state_changed.connect(_refresh)
	g.fx_requested.connect(_on_fx)
	_refresh()


func _refresh() -> void:
	var h := game.hint()
	if h != _hint_label.text:
		_hint_label.text = h
		_hint_label.visible_ratio = 0.0
		create_tween().tween_property(_hint_label, "visible_ratio", 1.0, 0.05 * h.length())
	if not game.state.d["ended"]:
		_ending_label.text = ""


func _on_fx(ev: Dictionary) -> void:
	if ev["kind"] == "ending":
		_ending_label.text = game.poem.get("ending_text", "")
		_ending_label.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_interval(2.5)
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
	b.pressed.connect(cb)
	add_child(b)
	b.size = b.get_combined_minimum_size()
	return b
