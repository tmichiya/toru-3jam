class_name Effects
extends RefCounted
## 状態を変える効果のレジストリ。effect id -> Callable(state, arg, uids) -> Array[fx event]
## 見た目だけの演出 (鳥が飛ぶ等) はここではなく WordAnims にある。

var _table: Dictionary = {}


func _init() -> void:
	_table = {
		"color": _color,
		"reveal": _reveal,
		"ending": _ending,
	}


func apply(id: String, s: GameState, arg, uids: Array) -> Array:
	if not _table.has(id):
		return []
	return _table[id].call(s, arg, uids)


func _color(s: GameState, arg, uids: Array) -> Array:
	var c: String = str(arg)
	if s.d["color"] != c:
		s.d["prev_color"] = s.d["color"]
		s.d["color"] = c
	return [{"kind": "color", "uids": uids, "color": c}]


func _reveal(s: GameState, arg, uids: Array) -> Array:
	for line in s.lines():
		if line["id"] in arg:
			line["revealed"] = true
	return [{"kind": "reveal", "uids": uids}]


func _ending(s: GameState, _arg, uids: Array) -> Array:
	s.d["ended"] = true
	return [{"kind": "ending", "uids": uids}]
