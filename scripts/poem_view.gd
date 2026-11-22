class_name PoemView
extends Node2D
## GameState から詩の行と単語ノードを配置する。ロジックは持たない。
## 手に入れた詩は全部、部屋 (丸) の左右に並べて常に見せる (poem.json の poem_layout)。
## focus_poem のある場面 (はじまり) は、その詩だけを上の真ん中に置く。
## 新しく手に入れた詩は一文字ずつ現れる。

const LINE_H := 16.0
const TITLE_H := 13.0
const WORD_GAP := 8.0
const TYPE_DELAY_PER_WORD := 0.2
const TYPE_DELAY_PER_LINE := 0.5
const FIRST_DELAY := 0.3
const TITLE_COLOR := Color(1, 1, 1, 0.45)

var game: Game

var _nodes: Dictionary = {}    # uid -> WordNode
var _rects: Dictionary = {}    # uid -> Rect2
var _titles: Dictionary = {}   # 詩の id -> 題 (一 二 …) を描く位置
var _drag_uid := -1
var _drag_offset := Vector2.ZERO


func setup(g: Game) -> void:
	game = g
	g.state_changed.connect(refresh)
	g.fx_requested.connect(_on_fx)
	refresh()


func refresh() -> void:
	var s := game.state
	var focus: String = game.stage_def().get("focus_poem", "")
	var alive: Dictionary = {}
	_titles.clear()
	for pid in s.got():
		var origin := _origin_of(pid, focus)
		var top := origin.y
		if pid != focus:
			_titles[pid] = Vector2(origin.x, top)
			top += TITLE_H
		var lines := s.poem_lines(pid)
		for li in lines.size():
			_layout_line(s, origin.x, top + li * LINE_H, li, lines[li]["words"], alive)

	# 手に入れる前に戻った (Undo) 詩の言葉は消す
	for uid in _nodes.keys():
		if not alive.has(uid):
			_nodes[uid].queue_free()
			_nodes.erase(uid)
			_rects.erase(uid)
	queue_redraw()


## 詩を置く位置 (x は列の中心, y は上端)
func _origin_of(pid: String, focus: String) -> Vector2:
	var layout: Dictionary = game.poem.get("poem_layout", {})
	var key := "focus" if pid == focus else pid
	var p: Array = layout.get(key, [UIConst.SCREEN.x / 2.0, 20])
	return Vector2(p[0], p[1])


func _layout_line(s: GameState, cx: float, y: float, li: int, ws: Array, alive: Dictionary) -> void:
	var widths: Array = []
	var total := WORD_GAP * maxi(0, ws.size() - 1)
	for w in ws:
		var ww := UIConst.text_width(w["t"])
		widths.append(ww)
		total += ww
	var x := roundf(cx - total / 2.0)
	for wi in ws.size():
		var w: Dictionary = ws[wi]
		var uid: int = w["uid"]
		alive[uid] = true
		var rect := Rect2(x, y, widths[wi], UIConst.text_height())
		_rects[uid] = rect
		var node: WordNode = _nodes.get(uid)
		var delay := 0.0
		if node == null:
			node = WordNode.new()
			add_child(node)
			node.setup(uid, w["t"], rect.position)
			_nodes[uid] = node
			delay = FIRST_DELAY + li * TYPE_DELAY_PER_LINE + wi * TYPE_DELAY_PER_WORD
			node.typewrite(delay)
		if node.text != w["t"]:
			node.queue_text(w["t"])
		if uid != _drag_uid:
			node.move_to(rect.position)  # 場所が変わったら (はじまり → 左上) すーっと動く
		node.set_status(_status_of(s, w), delay)
		x += widths[wi] + WORD_GAP


## 各詩の題 (一 二 三 四)
func _draw() -> void:
	for pid in _titles:
		var p: Vector2 = _titles[pid]
		var t := game.state.poem_title(pid)
		var x := roundf(p.x - UIConst.text_width(t) / 2.0)
		draw_string(UIConst.FONT, Vector2(x, p.y + UIConst.FONT.get_ascent(UIConst.FONT_SIZE)), t,
			HORIZONTAL_ALIGNMENT_LEFT, -1, UIConst.FONT_SIZE, TITLE_COLOR)


func get_rect(uid: int) -> Rect2:
	return _rects.get(uid, Rect2())


func get_word_node(uid: int) -> WordNode:
	return _nodes.get(uid)


## p の上にある、さわれる単語の uid。なければ -1 (exclude はドラッグ中の言葉など除外するもの)
func uid_at(p: Vector2, exclude: int = -1) -> int:
	for pid in game.state.got():
		for line in game.state.poem_lines(pid):
			for w in line["words"]:
				if w["uid"] != exclude and game.state.is_present(w) and get_rect(w["uid"]).grow(3.0).has_point(p):
					return w["uid"]
	return -1


## ドラッグ中の言葉の下で、重ねると意味が変わる言葉をうっすら光らせる
func hover_tool_target(tool_uid: int, p: Vector2) -> void:
	var target := uid_at(p, tool_uid)
	for uid in _nodes:
		if uid != tool_uid:
			_nodes[uid].set_highlight(uid == target and game.tool_result(tool_uid, target) != "")


## ドラッグ開始。from_bubble なら吹き出しから引き抜いた言葉 (カーソル中央に持つ)
func begin_drag(uid: int, p: Vector2, from_bubble: bool) -> void:
	var node := get_word_node(uid)
	if node == null:
		return
	_drag_uid = uid
	if from_bubble:
		_drag_offset = Vector2(roundf(node.width() / 2.0), roundf(UIConst.text_height() / 2.0))
	else:
		_drag_offset = p - get_rect(uid).position
	node.set_dragging(true)
	node.drag_to(p - _drag_offset)


func drag_to(p: Vector2) -> void:
	var node := get_word_node(_drag_uid)
	if node:
		node.drag_to(p - _drag_offset)


func end_drag() -> void:
	var node := get_word_node(_drag_uid)
	if node:
		node.set_dragging(false)
		node.move_to(get_rect(_drag_uid).position)
	for n in _nodes.values():
		n.set_highlight(false)
	_drag_uid = -1


func _status_of(s: GameState, w: Dictionary) -> String:
	if w["in_bubble"]:
		return "lent"
	if not s.can_see(w) and not s.d["ended"]:
		return "hidden"
	return "visible"


func _on_fx(ev: Dictionary) -> void:
	match ev["kind"]:
		"ending":
			# エンディングの文と重ならないよう、詩はそっと消える
			create_tween().tween_property(self, "modulate:a", 0.0, 1.5).set_delay(1.5)
		"undo":
			modulate.a = 1.0
		"transform":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].morph(ev["tool"])
		"full":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].shake()
		"take_back":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].flash()
