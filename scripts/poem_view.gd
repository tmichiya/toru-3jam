class_name PoemView
extends Node2D
## GameState から詩の行と単語ノードを配置する (画面上方、部屋の上に重なる)。ロジックは持たない。
## 手に入れた詩はページ (しおり) になり、選んだページだけが見える。
## 新しく手に入れた詩は自動で開き、一文字ずつ現れる。

signal page_changed

const TOP := 20.0
const LINE_H := 18.0
const WORD_GAP := 10.0
const TYPE_DELAY_PER_WORD := 0.2
const TYPE_DELAY_PER_LINE := 0.5
const FIRST_DELAY := 0.3

var game: Game
var page := ""                 # いま開いている詩の id

var _nodes: Dictionary = {}    # uid -> WordNode
var _rects: Dictionary = {}    # uid -> Rect2
var _page_of: Dictionary = {}  # uid -> 詩の id
var _drag_uid := -1
var _drag_offset := Vector2.ZERO


func setup(g: Game) -> void:
	game = g
	g.state_changed.connect(refresh)
	g.fx_requested.connect(_on_fx)
	refresh()


func select_page(pid: String) -> void:
	if pid == page:
		return
	page = pid
	refresh()
	page_changed.emit()


func refresh() -> void:
	var s := game.state
	if not page in s.got():
		page = "" if s.got().is_empty() else s.got()[-1]
		page_changed.emit()
	var alive: Dictionary = {}
	for pid in s.got():
		var lines := s.poem_lines(pid)
		for li in lines.size():
			_layout_line(s, pid, li, lines[li]["words"], alive)

	# 手に入れる前に戻った (Undo) 詩の言葉は消す
	for uid in _nodes.keys():
		if not alive.has(uid):
			_nodes[uid].queue_free()
			_nodes.erase(uid)
			_rects.erase(uid)
			_page_of.erase(uid)


func _layout_line(s: GameState, pid: String, li: int, ws: Array, alive: Dictionary) -> void:
	var y := TOP + li * LINE_H
	var widths: Array = []
	var total := WORD_GAP * maxi(0, ws.size() - 1)
	for w in ws:
		var ww := UIConst.text_width(w["t"])
		widths.append(ww)
		total += ww
	var x := roundf((UIConst.SCREEN.x - total) / 2.0)
	for wi in ws.size():
		var w: Dictionary = ws[wi]
		var uid: int = w["uid"]
		alive[uid] = true
		var rect := Rect2(x, y, widths[wi], UIConst.text_height())
		_rects[uid] = rect
		_page_of[uid] = pid
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
			node.move_to(rect.position)
		node.visible = pid == page or uid == _drag_uid
		node.set_status(_status_of(s, w), delay)
		x += widths[wi] + WORD_GAP


func get_rect(uid: int) -> Rect2:
	return _rects.get(uid, Rect2())


func get_word_node(uid: int) -> WordNode:
	return _nodes.get(uid)


## p の上にある、さわれる単語の uid。なければ -1 (exclude はドラッグ中の言葉など除外するもの)
func uid_at(p: Vector2, exclude: int = -1) -> int:
	if page == "":
		return -1
	for line in game.state.poem_lines(page):
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
	node.visible = true  # 別のページの言葉でも、運んでいる間は見せる
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
		node.visible = _page_of.get(_drag_uid, "") == page
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
		"collect":
			select_page(ev["poem"])
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
