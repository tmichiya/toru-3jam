class_name PoemView
extends Node2D
## GameState から詩の行と単語ノードを配置する (画面上方)。ロジックは持たない。
## 場面が変わると前の詩はディザで消え、新しい詩が一文字ずつ現れる。

const TOP := 34.0
const LINE_H := 24.0
const WORD_GAP := 10.0
const TYPE_DELAY_PER_WORD := 0.2
const TYPE_DELAY_PER_LINE := 0.5
const FIRST_DELAY := 0.4

var game: Game

var _nodes: Dictionary = {}    # uid -> WordNode
var _rects: Dictionary = {}    # uid -> Rect2
var _drag_uid := -1
var _drag_offset := Vector2.ZERO


func setup(g: Game) -> void:
	game = g
	g.state_changed.connect(refresh)
	g.fx_requested.connect(_on_fx)
	refresh()


func refresh() -> void:
	var s := game.state
	var alive: Dictionary = {}
	var lines := s.lines()
	for li in lines.size():
		var ws: Array = lines[li]["words"]
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
			var node: WordNode = _nodes.get(uid)
			var delay := 0.0
			if node == null:
				node = WordNode.new()
				add_child(node)
				node.setup(uid, w["t"], rect.position)
				_nodes[uid] = node
				delay = FIRST_DELAY + li * TYPE_DELAY_PER_LINE + wi * TYPE_DELAY_PER_WORD
				node.typewrite(delay)
			if uid != _drag_uid:
				node.move_to(rect.position)
			node.set_status(_status_of(s, w), delay)
			x += widths[wi] + WORD_GAP

	# 前の場面の言葉は溶けて消える
	for uid in _nodes.keys():
		if not alive.has(uid):
			var node: WordNode = _nodes[uid]
			node.set_status("gone")
			get_tree().create_timer(0.5).timeout.connect(node.queue_free)
			_nodes.erase(uid)
			_rects.erase(uid)


func get_rect(uid: int) -> Rect2:
	return _rects.get(uid, Rect2())


func get_word_node(uid: int) -> WordNode:
	return _nodes.get(uid)


## p の上にある、さわれる単語の uid。なければ -1
func uid_at(p: Vector2) -> int:
	for line in game.state.lines():
		for w in line["words"]:
			if game.state.is_present(w) and get_rect(w["uid"]).grow(3.0).has_point(p):
				return w["uid"]
	return -1


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
	_drag_uid = -1


func _status_of(s: GameState, w: Dictionary) -> String:
	if w["in_bubble"]:
		return "lent"
	if not s.can_see(w) and not s.d["ended"]:
		return "hidden"
	return "visible"


func _on_fx(ev: Dictionary) -> void:
	match ev["kind"]:
		"full":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].shake()
		"take_back":
			for uid in ev["uids"]:
				if _nodes.has(uid):
					_nodes[uid].flash()
