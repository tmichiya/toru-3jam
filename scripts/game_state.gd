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
		"got": poem.get("start_poems", []).duplicate(),  # 手に入れた詩の id (手に入れた順)
		"poems": {},         # 詩 id -> { "title", "lines": [{ "id", "words" }] }
		"next_uid": 1,
		"message": [],       # 吹き出しに並んだ言葉の uid (渡した順)
		"color": "gray",     # 現在の色
		"prev_color": "",    # ひとつ前の色 (グラデーション下側)
		"ended": false,
	}
	var lexicon: Dictionary = poem.get("lexicon", {})
	for p in poem["poems"]:
		var lines: Array = []
		for i in p["lines"].size():
			var words: Array = []
			for w in p["lines"][i]:
				var src: Dictionary = w if w is Dictionary else _parse_token(str(w))
				words.append(make_word(s.new_uid(), src, lexicon))
			lines.append({"id": "%s-%d" % [p["id"], i], "words": words})
		s.d["poems"][p["id"]] = {"title": p.get("title", p["id"]), "lines": lines}
	return s


## 詩の中の言葉ひとつ。演出・効果・道具は lexicon (言葉の辞書) から引く
static func make_word(uid: int, src: Dictionary, lexicon: Dictionary) -> Dictionary:
	var w := {
		"uid": uid,
		"visible_in": src.get("visible_in", ""),
		"in_bubble": false,
		"joint": bool(src.get("joint", false)),  # つなぎの言葉 (の・へ・が…): 見えるだけで、さわれない
	}
	set_text(w, src.get("t", ""), lexicon)
	return w


## 言葉を別の言葉に変える (逆さ・ずれる)。見える色などその場所の性質はそのまま
static func set_text(w: Dictionary, t: String, lexicon: Dictionary) -> void:
	var lex: Dictionary = lexicon.get(t, {})
	w["t"] = t
	w["key"] = t
	w["anim"] = lex.get("anim", "")
	w["effect"] = lex.get("effect", "")
	w["arg"] = lex.get("arg", null)
	w["tool"] = lex.get("tool", "")
	# 色の言葉は、別の色の言葉に重ねると混ざる道具にもなる
	if w["tool"] == "" and w["effect"] == "color":
		w["tool"] = "mix"


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
	return not w["joint"] and not w["in_bubble"] and can_see(w) and poem_of(w["uid"]) in got()


## 詩の中の文字列ひとつ。"~の" のように ~ で始まるものは、つなぎの言葉
static func _parse_token(s: String) -> Dictionary:
	if s.begins_with("~"):
		return {"t": s.substr(1), "joint": true}
	return {"t": s}


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
