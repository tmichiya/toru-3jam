class_name GameUI
extends Control
## 画面の情報 (場面のヒント・伝えるボタン・もどる/やりなおす・エンディング文)。画面下はヒント1行とボタンだけにする。

const MARGIN := 8.0
const MOVE_TELOP_DELAY := 1.0
const INFO_TELOP_TIME := 5.0
const START_TELOP_Y := 44.0
const START_TELOP_Y_FOCUS := 104.0
const START_TELOP_LINE_H := 16.0

var game: Game
var player: Player
var view: PoemView

var _hint_label: Label
var _ending_label: Label
var _title_label: Label
var _tell_button: Button
var _telop: Label
var _telop_done := false
var _info: Label
var _info_shown: Dictionary = {}  # telop_after を出した場面
var _start_telops: Array = []    # 出している場面はじめの案内 {key, stage, until, label}
var _start_done: Dictionary = {}  # 出し終えた案内の key


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
	_info = _make_label("", Vector2(0, 44))
	_info.size = Vector2(UIConst.SCREEN.x, 16)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_color_override("font_color", UIConst.HILITE_COLOR)

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
	_update_info_telop()
	_update_start_telops()
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
	# 案内に書いた操作を一度やってみたら、その案内はもういらない
	_on_start_telop_event(ev["kind"])
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


## 場面の詩を手に入れたとき (hint_after に変わったとき) に、telop_after を少しのあいだ出す
func _update_info_telop() -> void:
	var st := game.stage_def()
	var text: String = st.get("telop_after", "")
	var key := "%d" % game.state.d["stage"]
	if text == "" or _info_shown.has(key) or game.hint() != str(st.get("hint_after", "")):
		return
	_info_shown[key] = true
	_info.text = text
	_info.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(_info, "modulate:a", 1.0, 0.6)
	tw.tween_interval(INFO_TELOP_TIME)
	tw.tween_property(_info, "modulate:a", 0.0, 0.8)


## 場面のはじめに出す telops (例: はじまりの「ことばを クリックすると…」「ことばを ことばに かさねると…」)。
## 1行ずつ、until に書いた出来事 (anim = 言葉をクリック, transform = 言葉を重ねて変える, color = 背景の色が変わる) が
## 起きるまで、または場面が変わるまで出し続ける
func _update_start_telops() -> void:
	var st := game.stage_def()
	var stage_key := "%d" % game.state.d["stage"]
	# 場面が変わったら、前の場面の案内は消す
	for t in _start_telops.duplicate():
		if t["stage"] != stage_key or game.state.d["ended"]:
			_hide_start_telop(t)
	if game.state.d["ended"]:
		return
	var defs: Array = st.get("telops", [])
	# はじまり (詩が上の真ん中にある場面) は、詩と主人公のあいだに出す
	# telops_y があればその高さ (左右の詩とぶつからないところ)
	var y := float(st.get("telops_y", START_TELOP_Y_FOCUS if st.has("focus_poem") else START_TELOP_Y))
	for i in defs.size():
		var key := "%s-%d" % [stage_key, i]
		if _start_done.has(key) or _start_telops.any(func(t): return t["key"] == key):
			continue
		var label := _make_label(str(defs[i].get("text", "")), Vector2(0, y + i * START_TELOP_LINE_H))
		label.size = Vector2(UIConst.SCREEN.x, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", UIConst.HILITE_COLOR)
		label.modulate.a = 0.0
		create_tween().tween_property(label, "modulate:a", 1.0, 0.8)
		_start_telops.append({"key": key, "stage": stage_key, "until": str(defs[i].get("until", "")), "label": label})


## kind の出来事が起きたら、それを待っていた案内を消す
func _on_start_telop_event(kind: String) -> void:
	for t in _start_telops.duplicate():
		if t["until"] == kind:
			_hide_start_telop(t)


func _hide_start_telop(t: Dictionary) -> void:
	_start_telops.erase(t)
	_start_done[t["key"]] = true
	var label: Label = t["label"]
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 0.0, 0.6)
	tw.tween_callback(label.queue_free)


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
