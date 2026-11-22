extends SceneTree
## 想定手順でエンディングまで到達できるかを、ロジックと歩く経路だけで確かめる。
## godot --headless --path . -s res://tests/test_solution.gd

var game: Game
var failed := false


func _init() -> void:
	game = Game.new()
	root.add_child(game)
	game.load_poem("res://data/poem.json")
	_test_nav()

	# 1. 泣いている: 赤で 逆さ が見え、涙を逆さにして 笑顔
	_check(game.state.got().is_empty(), "最初は詩を持っていない")
	game.arrive("shelf_left")
	_check(game.state.got().is_empty(), "まだ開いていない本棚からは手に入らない")
	game.arrive("shelf_bottom")
	_check(game.state.got() == ["p1"], "下の本棚で 詩一 を手に入れる")
	_check(not game.apply_tool(_uid("逆さ"), _uid("涙")), "赤の前は 逆さ が見えない")
	game.click(_uid("赤い"))
	_check(not game.apply_tool(_uid("逆さ"), _uid("部屋")), "部屋 は逆さにできない")
	_check(game.apply_tool(_uid("逆さ"), _uid("涙")), "涙 を逆さにする")
	_check(_uid("笑顔") > 0 and _uid("涙") < 0, "涙 が 笑顔 に変わる")
	game.give(_uid("笑顔"))
	_check(game.tell(), "笑顔 で泣きやむ")

	# 2. ベッドへ (途中で左の本棚)
	game.arrive("shelf_left")
	_check("p2" in game.state.got(), "左の本棚で 詩二 を手に入れる")
	game.arrive("bed")
	_check(game.stage_def()["id"] == "sleep", "ベッドで眠る")

	# 3. 寝ている: 青で ずれる が見え、夜 → 朝。詩一の 笑顔 と合わせる
	game.click(_uid("青い"))
	_check(game.apply_tool(_uid("ずれる"), _uid("夜")) and _uid("朝") > 0, "夜 が ずれて 朝 に")
	game.give(_uid("やさしい"))
	game.give(_uid("朝"))
	_check(not game.tell(), "やさしい 朝 では起きない")
	game.give(_uid("朝"))
	game.give(_uid("笑顔"))
	_check(game.tell(), "朝 笑顔 (詩二+詩一) で起きる")

	# 4. 扉: 赤で 逆さ を出して なくした → みつけた、金色で 鍵
	game.arrive("shelf_right")
	_check("p3" in game.state.got(), "右の本棚で 詩三 を手に入れる")
	game.click(_uid("赤い"))
	_check(game.apply_tool(_uid("逆さ"), _uid("なくした")), "なくした を逆さにして みつけた")
	game.click(_uid("金色"))
	_check(not game.state.is_present(_w("逆さ")), "金色の間は 逆さ は見えない")
	game.give(_uid("鍵"))
	game.give(_uid("みつけた"))
	_check(game.tell(), "鍵 みつけた (詩三+詩一の道具) で鍵が見つかる")

	# 5. 窓: 暗い → 明るい (逆さ)、過去 → 今 → 未来 (ずれる 2回)
	game.arrive("window")
	_check("p4" in game.state.got(), "窓で 詩四 を手に入れる")
	game.click(_uid("赤い"))
	game.apply_tool(_uid("逆さ"), _uid("暗い"))
	game.click(_uid("青い"))
	game.apply_tool(_uid("ずれる"), _uid("過去"))
	_check(_uid("今") > 0, "過去 が ずれて 今")
	game.apply_tool(_uid("ずれる"), _uid("今"))
	for t in ["きらきらした", "明るい", "未来"]:
		game.give(_uid(t))
	_check(game.tell() and game.state.d["ended"], "きらきらした 明るい 未来 でエンディング")

	game.undo()
	_check(not game.state.d["ended"], "Undo でエンディング前へ")
	game.reset()
	_check(game.state.d["stage"] == 0 and _uid("涙") > 0, "Reset で初期状態 (涙 に戻る)")
	print("FAILED" if failed else "ALL OK")
	quit(1 if failed else 0)


func _test_nav() -> void:
	var nav := RoomNav.new(game.poem["nav"])
	var path := nav.find_path(Vector2(135, 177), Vector2(88, 100))
	_check(not path.is_empty() and path[path.size() - 1].distance_to(Vector2(88, 105)) < 1.0, "下の床からベッドへ行ける")
	path = nav.find_path(Vector2(88, 105), Vector2(234, 100))
	_check(not path.is_empty() and path[path.size() - 1].distance_to(Vector2(234, 106)) < 1.0, "ベッドから扉へ行ける")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + msg)
	else:
		print("ok  ", msg)


func _w(t: String) -> Dictionary:
	for pid in game.state.d["poems"]:
		for line in game.state.poem_lines(pid):
			for w in line["words"]:
				if w["t"] == t:
					return w
	return {}


func _uid(t: String) -> int:
	var w := _w(t)
	return -1 if w.is_empty() else int(w["uid"])
