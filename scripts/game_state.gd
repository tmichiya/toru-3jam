class_name GameState
extends RefCounted
## ゲームの純データ。これが唯一の真実で、View はここから描画するだけ。
## d はディープコピーするだけでスナップショットになる (Undo 用)。
##
## 詩 (poems) は最初に全部作っておき、本棚で手に入れたもの (got) だけが使える。
## 主人公に渡した言葉は message に並び、元の言葉は in_bubble = true (貸し出し中) になる。

var d: Dictionary = {}


static func from_poem(poem: Dictionary) -> GameState:
	var s := GameState.new()
	s.d = {
		"stage": 0,
		"got": [],           # 手に入れた詩の id (手に入れた順)
		"poems": {},         # 詩 id -> { "title", "lines": [{ "id", "words" }] }
		"next_uid": 1,
		"message": [],       # 吹き出しに並んだ言葉の uid (渡した順)
		"color": "gray",     # 現在の色
		"prev_color": "",    # ひとつ前の色 (グラデーション下側)
		"ended": false,
	}
	for p in poem["poems"]:
		var lines: Array = []
		for i in p["lines"].size():
			var words: Array = []
			for w in p["lines"][i]:
				words.append(make_word(s.new_uid(), w))
			lines.append({"id": "%s-%d" % [p["id"], i], "words": words})
		s.d["poems"][p["id"]] = {"title": p.get("title", p["id"]), "lines": lines}
	return s


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


func got() -> Array:
	return d["got"]


func poem_lines(pid: String) -> Array:
	return d["poems"][pid]["lines"]


func poem_title(pid: String) -> String:
	return d["poems"][pid]["title"]


func message() -> Array:
	return d["message"]


func new_uid() -> int:
	var u: int = d["next_uid"]
	d["next_uid"] = u + 1
	return u


## いまの色で見えているか
func can_see(w: Dictionary) -> bool:
	return w["visible_in"] == "" or w["visible_in"] == d["color"]


## 手に入れた詩の中にあって、さわれる (見えていて、貸し出し中でない) か
func is_present(w: Dictionary) -> bool:
	return not w["in_bubble"] and can_see(w) and poem_of(w["uid"]) in got()


func word_by_uid(uid: int) -> Dictionary:
	for pid in d["poems"]:
		for line in poem_lines(pid):
			for w in line["words"]:
				if w["uid"] == uid:
					return w
	return {}


func poem_of(uid: int) -> String:
	for pid in d["poems"]:
		for line in poem_lines(pid):
			for w in line["words"]:
				if w["uid"] == uid:
					return pid
	return ""
