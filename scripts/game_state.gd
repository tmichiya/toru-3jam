class_name GameState
extends RefCounted
## ゲームの純データ。これが唯一の真実で、View はここから描画するだけ。
## d はディープコピーするだけでスナップショットになる (Undo 用)。
##
## 場面 (stage) ごとに詩の行が入れ替わる。主人公に渡した言葉は message に並び、
## 詩の中の元の言葉は in_bubble = true (貸し出し中) になる。

var d: Dictionary = {}


static func from_poem(poem: Dictionary) -> GameState:
	var s := GameState.new()
	s.d = {
		"stage": 0,
		"lines": [],
		"next_uid": 1,
		"message": [],       # 吹き出しに並んだ言葉の uid (渡した順)
		"color": "gray",     # 現在の色
		"prev_color": "",    # ひとつ前の色 (グラデーション下側)
		"ended": false,
	}
	s.load_stage(poem, 0)
	return s


func load_stage(poem: Dictionary, idx: int) -> void:
	d["stage"] = idx
	d["message"] = []
	var lines: Array = []
	var src: Array = poem["stages"][idx]["lines"]
	for i in src.size():
		var words: Array = []
		for w in src[i]:
			words.append(make_word(new_uid(), w))
		lines.append({"id": "%d-%d" % [idx, i], "words": words})
	d["lines"] = lines


static func make_word(uid: int, src: Dictionary) -> Dictionary:
	var t: String = src.get("t", "")
	return {
		"uid": uid,
		"t": t,
		"key": src.get("key", t),
		"anim": src.get("anim", ""),
		"effect": src.get("effect", ""),
		"arg": src.get("arg", null),
		"visible_in": src.get("visible_in", ""),
		"in_bubble": false,
	}


func snapshot() -> Dictionary:
	return d.duplicate(true)


func restore(snap: Dictionary) -> void:
	d = snap.duplicate(true)


func lines() -> Array:
	return d["lines"]


func message() -> Array:
	return d["message"]


func new_uid() -> int:
	var u: int = d["next_uid"]
	d["next_uid"] = u + 1
	return u


## いまの色で見えているか
func can_see(w: Dictionary) -> bool:
	return w["visible_in"] == "" or w["visible_in"] == d["color"]


## 詩の中にあって、さわれる (見えていて、貸し出し中でない) か
func is_present(w: Dictionary) -> bool:
	return not w["in_bubble"] and can_see(w)


func word_by_uid(uid: int) -> Dictionary:
	for line in lines():
		for w in line["words"]:
			if w["uid"] == uid:
				return w
	return {}
