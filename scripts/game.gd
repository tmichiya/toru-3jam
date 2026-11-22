class_name Game
extends Node
## ゲームロジック。入力から要求を受け、GameState を変え、signal で知らせる。
## View 側からは state を読むだけにして、変更は必ずここを通す。
##
##  - click(uid): その言葉の演出 (+ 色などの効果)
##  - drop(uid, line, after_uid): つなげられる場所なら固定、だめなら元の場所へ
##  - つながりの結果コンボが揃えば発動 (行が増える・エンディング)

signal state_changed
signal fx_requested(ev: Dictionary)

var poem: Dictionary = {}
var state: GameState
var effects := Effects.new()

var _links: Dictionary = {}  # "A>B" -> true  (A の直後に B を置ける)
var _initial: Dictionary = {}
var _history: Array = []


func load_poem(path: String) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "poem.json が読めません: " + path)
	poem = parsed
	_build_links()
	state = GameState.from_poem(poem)
	_initial = state.snapshot()
	_history.clear()
	state_changed.emit()


func palette_color(id: String, idx: int) -> Color:
	var pal: Dictionary = poem.get("palette", {})
	var pair: Array = pal.get(id, pal.get("gray", ["#888888", "#444444"]))
	return Color(pair[idx])


func hint() -> String:
	var hints: Array = poem.get("hints", [])
	var i: int = state.d["fired"].size()
	return hints[i] if i < hints.size() else ""


## 言葉をクリック: 意味の演出 + 効果
func click(uid: int) -> void:
	var w := state.word_by_uid(uid)
	if w.is_empty() or not state.is_present(w):
		return
	var evs: Array = [{"kind": "anim", "anim": w["anim"], "uids": [uid]}]
	if w["effect"] == "":
		_emit_all(evs)
		return
	_push()
	evs.append_array(effects.apply(w["effect"], state, w["arg"], [uid]))
	evs.append_array(_check_combos())
	_commit(evs)


## li 行の after_uid の直後 (after_uid = -1 なら行頭) に置けるか
func can_drop(uid: int, li: int, after_uid: int) -> bool:
	var w := state.word_by_uid(uid)
	if w.is_empty() or not state.is_present(w) or state.d["ended"]:
		return false
	if li < 0 or li >= state.lines().size():
		return false
	var nb := _neighbors(li, after_uid, uid)
	var left: Dictionary = nb[0]
	var right: Dictionary = nb[1]
	return (not left.is_empty() and _linked(left["key"], w["key"])) \
		or (not right.is_empty() and _linked(w["key"], right["key"]))


func drop(uid: int, li: int, after_uid: int) -> bool:
	if not can_drop(uid, li, after_uid):
		return_home(uid)
		return false
	_push()
	var w := _detach(uid)
	var ws := state.line_words(li)
	var k := 0
	if after_uid >= 0:
		k = state.find_uid(after_uid).y + 1
	ws.insert(k, w)
	var evs: Array = [{"kind": "snap", "uids": [uid]}]
	evs.append_array(_check_combos())
	_commit(evs)
	return true


## 元の詩の場所へ戻す
func return_home(uid: int) -> void:
	var gap_at := state.find_gap_of(uid)
	if gap_at.x < 0:
		fx_requested.emit({"kind": "return", "uids": [uid]})
		return
	_push()
	var at := state.find_uid(uid)
	var w := state.word(at.x, at.y)
	state.line_words(at.x).remove_at(at.y)
	gap_at = state.find_gap_of(uid)
	state.line_words(gap_at.x)[gap_at.y] = w
	_commit([{"kind": "return", "uids": [uid]}])


func undo() -> void:
	if _history.is_empty():
		return
	state.restore(_history.pop_back())
	_commit([{"kind": "undo", "uids": []}])


func reset() -> void:
	if _history.is_empty():
		return
	state.restore(_initial)
	_history.clear()
	_commit([{"kind": "undo", "uids": []}])


## 今いる場所から取り外す。家にいたなら穴を残す。
func _detach(uid: int) -> Dictionary:
	var at := state.find_uid(uid)
	var ws := state.line_words(at.x)
	var w: Dictionary = ws[at.y]
	if state.find_gap_of(uid).x < 0:
		ws[at.y] = GameState.make_gap(state.new_uid(), w)
	else:
		ws.remove_at(at.y)
	return w


## after_uid の左右でいちばん近い「見えている言葉」(穴・隠れている言葉は飛ばす)
func _neighbors(li: int, after_uid: int, exclude_uid: int) -> Array:
	var ws: Array = state.line_words(li).filter(func(x): return x["uid"] != exclude_uid)
	var k := -1
	for i in ws.size():
		if ws[i]["uid"] == after_uid:
			k = i
	var left: Dictionary = {}
	var right: Dictionary = {}
	for i in range(k, -1, -1):
		if state.is_present(ws[i]):
			left = ws[i]
			break
	for i in range(k + 1, ws.size()):
		if state.is_present(ws[i]):
			right = ws[i]
			break
	return [left, right]


func _check_combos() -> Array:
	var evs: Array = []
	var combos: Array = poem.get("combos", [])
	for ci in combos.size():
		if ci in state.d["fired"]:
			continue
		var seq: Array = combos[ci]["seq"]
		for line in state.lines():
			if not line["revealed"]:
				continue
			var present: Array = line["words"].filter(func(x): return state.is_present(x))
			for start in present.size() - seq.size() + 1:
				var ok := true
				for j in seq.size():
					if present[start + j]["key"] != seq[j]:
						ok = false
						break
				if ok:
					state.d["fired"].append(ci)
					var uids: Array = present.slice(start, start + seq.size()).map(func(x): return x["uid"])
					evs.append_array(effects.apply(combos[ci].get("effect", ""), state,
						combos[ci].get("arg", null), uids))
					break
			if ci in state.d["fired"]:
				break
	return evs


func _build_links() -> void:
	_links.clear()
	for c in poem.get("combos", []):
		var seq: Array = c.get("seq", [])
		for i in seq.size() - 1:
			_links["%s>%s" % [seq[i], seq[i + 1]]] = true
	for pair in poem.get("links", []):
		_links["%s>%s" % [pair[0], pair[1]]] = true


func _linked(a: String, b: String) -> bool:
	return _links.has("%s>%s" % [a, b])


func _push() -> void:
	_history.append(state.snapshot())


func _commit(evs: Array) -> void:
	state_changed.emit()
	_emit_all(evs)


func _emit_all(evs: Array) -> void:
	for ev in evs:
		fx_requested.emit(ev)
