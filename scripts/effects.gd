class_name Effects
extends RefCounted
## 言葉をクリックしたときに状態を変える効果のレジストリ。
## effect id -> Callable(state, arg, uids) -> Array[fx event]
## 見た目だけの演出 (鳥が飛ぶ等) はここではなく WordAnims にある。

var _table: Dictionary = {}


func _init() -> void:
	_table = {
		"color": _color,
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
