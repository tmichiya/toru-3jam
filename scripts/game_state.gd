class_name GameState
extends RefCounted
## ゲームの純データ。これが唯一の真実で、View はここから描画するだけ。
## d はディープコピーするだけでスナップショットになる (Undo 用)。
##
## 単語は行の配列の中の並び順がそのまま位置。元の場所から動いた単語は、
## 元の場所に「穴」(gap_of = その単語の uid) を残す。

var d: Dictionary = {}


static func from_poem(poem: Dictionary) -> GameState:
	var s := GameState.new()
	var uid := 0
	var lines: Array = []
	for line in poem["lines"]:
		var words: Array = []
		for w in line["words"]:
			uid += 1
			words.append(make_word(uid, w))
		lines.append({
			"id": line["id"],
			"revealed": line.get("revealed", true),
			"words": words,
		})
	s.d = {
		"lines": lines,
		"next_uid": uid + 1,
		"color": "gray",     # 現在の色
		"prev_color": "",    # ひとつ前の色 (グラデーション下側)
		"fired": [],         # 発動済みコンボの番号
		"ended": false,
	}
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
		"gap_of": -1,  # >= 0 なら、その uid の単語が元いた場所の穴
	}


static func make_gap(uid: int, of: Dictionary) -> Dictionary:
	var g := make_word(uid, {"t": of["t"]})
	g["gap_of"] = of["uid"]
	return g


func snapshot() -> Dictionary:
	return d.duplicate(true)


func restore(snap: Dictionary) -> void:
	d = snap.duplicate(true)


func lines() -> Array:
	return d["lines"]


func line_words(li: int) -> Array:
	return d["lines"][li]["words"]


func word(li: int, wi: int) -> Dictionary:
	return d["lines"][li]["words"][wi]


func new_uid() -> int:
	var u: int = d["next_uid"]
	d["next_uid"] = u + 1
	return u


static func is_gap(w: Dictionary) -> bool:
	return int(w["gap_of"]) >= 0


## 穴でなく、いまの色で見えている (= さわれる) か
func is_present(w: Dictionary) -> bool:
	if is_gap(w):
		return false
	return w["visible_in"] == "" or w["visible_in"] == d["color"]


func find_uid(uid: int) -> Vector2i:
	var ls := lines()
	for li in ls.size():
		var ws: Array = ls[li]["words"]
		for wi in ws.size():
			if ws[wi]["uid"] == uid:
				return Vector2i(li, wi)
	return Vector2i(-1, -1)


func word_by_uid(uid: int) -> Dictionary:
	var at := find_uid(uid)
	return {} if at.x < 0 else word(at.x, at.y)


## uid の単語の元の場所の穴。家にいるなら (-1, -1)
func find_gap_of(uid: int) -> Vector2i:
	var ls := lines()
	for li in ls.size():
		var ws: Array = ls[li]["words"]
		for wi in ws.size():
			if int(ws[wi]["gap_of"]) == uid:
				return Vector2i(li, wi)
	return Vector2i(-1, -1)
