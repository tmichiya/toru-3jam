class_name PoemView
extends Node2D
## GameState から詩の行と単語ノードを配置する。ロジックは持たない。
## 当たり判定・ドロップ先の計算も、見た目の配置を知っているここが答える。

const TOP := 44.0
const LINE_H := 26.0
const WORD_GAP := 10.0
const TYPE_DELAY_PER_WORD := 0.25
const TYPE_DELAY_PER_LINE := 0.6
const DROP_REACH := 18.0  # 行からこれ以上離れたら置けない

var game: Game

var _nodes: Dictionary = {}    # uid -> WordNode
var _rects: Dictionary = {}    # uid -> Rect2
var _line_y: Dictionary = {}   # line index -> y
var _shown_lines: Dictionary = {}  # line id -> true (タイプライタ済み)
var _drag_uid := -1
var _drag_offset := Vector2.ZERO
var _target := {"line": -1, "after": -1, "valid": false}
var _t := 0.0


func setup(g: Game) -> void:
	game = g
	g.state_changed.connect(refresh)
	g.fx_requested.connect(_on_fx)
	refresh()


func refresh() -> void:
	var s := game.state
	var alive: Dictionary = {}
	var row := 0
	var new_rows := 0
	_line_y.clear()
	var lines := s.lines()
	for li in lines.size():
		var line: Dictionary = lines[li]
		if not line["revealed"]:
			_shown_lines.erase(line["id"])
			continue
		var y := TOP + row * LINE_H
		_line_y[li] = y
		var is_new := not _shown_lines.has(line["id"])
		_shown_lines[line["id"]] = true
		var line_delay := new_rows * TYPE_DELAY_PER_LINE
		if is_new:
			new_rows += 1

		var ws: Array = line["words"]
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
			var node: WordNode = _nodes.get(uid)
			var delay := 0.0
			if node == null:
				node = WordNode.new()
				add_child(node)
				node.setup(uid, w["t"], rect.position)
				_nodes[uid] = node
				if is_new:
					delay = line_delay + wi * TYPE_DELAY_PER_WORD
					node.typewrite(delay)
			if uid != _drag_uid:
				node.move_to(rect.position)
			node.set_status(_status_of(s, w), delay)
			x += widths[wi] + WORD_GAP
		row += 1

	for uid in _nodes.keys():
		if not alive.has(uid):
			_nodes[uid].queue_free()
			_nodes.erase(uid)
			_rects.erase(uid)


func get_rect(uid: int) -> Rect2:
	return _rects.get(uid, Rect2())


func get_word_node(uid: int) -> WordNode:
	return _nodes.get(uid)


## p の上にある、さわれる単語の uid。なければ -1
func uid_at(p: Vector2) -> int:
	for li in _line_y.keys():
		for w in game.state.line_words(li):
			if game.state.is_present(w) and get_rect(w["uid"]).grow(3.0).has_point(p):
				return w["uid"]
	return -1


func begin_drag(uid: int, p: Vector2) -> void:
	_drag_uid = uid
	_drag_offset = p - get_rect(uid).position
	var node := get_word_node(uid)
	if node:
		node.set_dragging(true)


func drag_to(p: Vector2) -> void:
	var node := get_word_node(_drag_uid)
	if node:
		node.drag_to(p - _drag_offset)
	_target = _drop_target(p - _drag_offset + Vector2(0, UIConst.text_height() / 2.0))
	queue_redraw()


## ドラッグを終えて、置き先 {line, after, valid} を返す
func end_drag() -> Dictionary:
	var node := get_word_node(_drag_uid)
	if node:
		node.set_dragging(false)
		node.move_to(get_rect(_drag_uid).position)
	var t := _target
	_drag_uid = -1
	_target = {"line": -1, "after": -1, "valid": false}
	queue_redraw()
	return t


func _drop_target(p: Vector2) -> Dictionary:
	var none := {"line": -1, "after": -1, "valid": false}
	var best_li := -1
	var best_d := INF
	for li in _line_y.keys():
		var d := absf(_line_y[li] + UIConst.text_height() / 2.0 - p.y)
		if d < best_d:
			best_d = d
			best_li = li
	if best_li < 0 or best_d > DROP_REACH:
		return none
	# ドラッグ中の単語の中心より左にある最後の要素の直後に置く
	var center_x := p.x + get_rect(_drag_uid).size.x / 2.0
	var after := -1
	for w in game.state.line_words(best_li):
		if w["uid"] != _drag_uid and get_rect(w["uid"]).get_center().x < center_x:
			after = w["uid"]
	return {"line": best_li, "after": after,
		"valid": game.can_drop(_drag_uid, best_li, after)}


func _process(delta: float) -> void:
	_t += delta
	if _drag_uid >= 0:
		queue_redraw()


## ドラッグ中、置ける場所に点滅する縦線を出す
func _draw() -> void:
	if _drag_uid < 0 or not _target["valid"]:
		return
	if int(_t * 6.0) % 2 == 0:
		return
	var li: int = _target["line"]
	var ws: Array = game.state.line_words(li).filter(func(w): return w["uid"] != _drag_uid)
	var x := 0.0
	if _target["after"] < 0:
		x = get_rect(ws[0]["uid"]).position.x - WORD_GAP / 2.0 if not ws.is_empty() else UIConst.SCREEN.x / 2.0
	else:
		x = get_rect(_target["after"]).end.x + WORD_GAP / 2.0
	var y: float = _line_y[li]
	draw_rect(Rect2(roundf(x), y - 1, 1, UIConst.text_height() + 2), UIConst.HILITE_COLOR)


func _status_of(s: GameState, w: Dictionary) -> String:
	if GameState.is_gap(w):
		return "gap"
	# エンディングでは色に関係なく全部見せる
	if not s.is_present(w) and not s.d["ended"]:
		return "hidden"
	return "visible"


func _on_fx(ev: Dictionary) -> void:
	match ev["kind"]:
		"return":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].shake()
		"snap":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].flash()
