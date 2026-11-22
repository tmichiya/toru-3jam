class_name Game
extends Node
## ゲームロジック。入力から要求を受け、GameState を変え、signal で知らせる。
## View 側からは state を読むだけにして、変更は必ずここを通す。
##
##  - arrive(spot): 主人公が本棚・窓・ベッドなどに着いた (詩を手に入れる / 場面が進む)
##  - click(uid): その言葉の演出 (+ 色などの効果)
##  - give(uid) / take_back(uid): 主人公の吹き出しに言葉を渡す / 戻す
##  - tell(): 吹き出しの言葉を伝える。場面の答えと合えば次の場面へ

signal state_changed
signal fx_requested(ev: Dictionary)

var poem: Dictionary = {}
var state: GameState
var effects := Effects.new()

var _initial: Dictionary = {}
var _history: Array = []


func load_poem(path: String) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "poem.json が読めません: " + path)
	poem = parsed
	state = GameState.from_poem(poem)
	_initial = state.snapshot()
	_history.clear()
	state_changed.emit()


func stage_def() -> Dictionary:
	return poem["stages"][state.d["stage"]]


func capacity() -> int:
	return 0 if state.d["ended"] else int(stage_def().get("capacity", 1))


func hint() -> String:
	return "" if state.d["ended"] else str(stage_def().get("hint", ""))


func palette_color(id: String, idx: int) -> Color:
	var pal: Dictionary = poem.get("palette", {})
	var pair: Array = pal.get(id, pal.get("gray", ["#888888", "#444444"]))
	return Color(pair[idx])


## これまでの場面で開いた本棚・窓
func unlocked() -> Array:
	var out: Array = []
	for i in state.d["stage"] + 1:
		out.append_array(poem["stages"][i].get("unlock", []))
	return out


## 開いていて、まだ詩を手に入れていない本棚・窓か
func spot_has_poem(spot: String) -> bool:
	var sp: Dictionary = poem["spots"].get(spot, {})
	return sp.has("poem") and spot in unlocked() and not sp["poem"] in state.got()


## 主人公が spot に着いた
func arrive(spot: String) -> void:
	if state.d["ended"]:
		return
	var evs: Array = []
	if spot_has_poem(spot):
		_push()
		var pid: String = poem["spots"][spot]["poem"]
		state.got().append(pid)
		evs.append({"kind": "collect", "uids": [], "poem": pid, "spot": spot})
	if stage_def().get("reach", "") == spot:
		if evs.is_empty():
			_push()
		evs.append({"kind": "told_ok", "uids": [], "stage": stage_def()["id"]})
		evs.append_array(_advance())
	if not evs.is_empty():
		_commit(evs)


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
	_commit(evs)


## 道具の言葉 (逆さ・ずれる) を詩の言葉に重ねたとき、何に変わるか。変わらなければ ""
func tool_result(tool_uid: int, target_uid: int) -> String:
	var tool_w := state.word_by_uid(tool_uid)
	var target := state.word_by_uid(target_uid)
	if tool_w.is_empty() or target.is_empty() or tool_uid == target_uid:
		return ""
	if not state.is_present(tool_w) or not state.is_present(target):
		return ""
	var table: Dictionary = {}
	match tool_w["tool"]:
		"reverse":
			table = poem.get("opposites", {})
		"shift":
			table = poem.get("shifts", {})
	return str(table.get(target["key"], ""))


## 道具の言葉を詩の言葉に重ねて、意味を変える (道具は何度でも使える)
func apply_tool(tool_uid: int, target_uid: int) -> bool:
	var to := tool_result(tool_uid, target_uid)
	if to == "":
		fx_requested.emit({"kind": "full", "uids": [target_uid]})
		return false
	_push()
	var target := state.word_by_uid(target_uid)
	var from: String = target["t"]
	GameState.set_text(target, to, poem.get("lexicon", {}))
	_commit([{"kind": "transform", "uids": [target_uid], "tool": state.word_by_uid(tool_uid)["tool"], "from": from}])
	return true


func can_give(uid: int) -> bool:
	var w := state.word_by_uid(uid)
	return not w.is_empty() and state.is_present(w) and state.message().size() < capacity()


## 吹き出しに言葉を渡す (末尾に並ぶ)
func give(uid: int) -> bool:
	if not can_give(uid):
		fx_requested.emit({"kind": "full", "uids": [uid]})
		return false
	_push()
	state.word_by_uid(uid)["in_bubble"] = true
	state.message().append(uid)
	_commit([{"kind": "give", "uids": [uid]}])
	return true


## 吹き出しから詩へ戻す
func take_back(uid: int) -> void:
	if not uid in state.message():
		return
	_push()
	state.message().erase(uid)
	state.word_by_uid(uid)["in_bubble"] = false
	_commit([{"kind": "take_back", "uids": [uid]}])


## 吹き出しの言葉を伝える。言葉は詩へ戻る。答えと合えば次の場面へ。
func tell() -> bool:
	var msg: Array = state.message().duplicate()
	if msg.is_empty() or state.d["ended"]:
		return false
	var keys: Array = msg.map(func(u): return state.word_by_uid(u)["key"])
	_push()
	for u in msg:
		state.word_by_uid(u)["in_bubble"] = false
	state.message().clear()

	if not keys in stage_def().get("answers", []):
		_commit([{"kind": "told_ng", "uids": msg}])
		return false
	var evs: Array = [{"kind": "told_ok", "uids": msg, "stage": stage_def()["id"]}]
	evs.append_array(_advance())
	_commit(evs)
	return true


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


## 次の場面へ (最後ならエンディング)
func _advance() -> Array:
	# 吹き出しに残っている言葉は詩へ戻す
	for u in state.message():
		state.word_by_uid(u)["in_bubble"] = false
	state.message().clear()
	var next: int = state.d["stage"] + 1
	if next >= poem["stages"].size():
		state.d["ended"] = true
		return [{"kind": "ending", "uids": []}]
	state.d["stage"] = next
	return [{"kind": "stage", "uids": []}]


func _push() -> void:
	_history.append(state.snapshot())


func _commit(evs: Array) -> void:
	state_changed.emit()
	_emit_all(evs)


func _emit_all(evs: Array) -> void:
	for ev in evs:
		fx_requested.emit(ev)
