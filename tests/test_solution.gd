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

	# 1. 泣いている: 涙を逆さにして 笑顔
	_check(game.state.got() == ["p1"], "最初から 詩一 を持っている")
	game.arrive("shelf_left")
	_check(game.state.got() == ["p1"], "まだ開いていない本棚からは手に入らない")
	_check(not game.apply_tool(_uid("逆さ"), _uid("逆さ")), "逆さ そのものは逆さにできない")
	_check(game.apply_tool(_uid("逆さ"), _uid("涙")), "涙 を逆さにする")
	_check(_uid("笑顔") > 0 and _uid("涙") < 0, "涙 が 笑顔 に変わる")
	game.give(_uid("笑顔"))
	_check(game.tell(), "笑顔 で泣きやむ")

	# 2. ベッドへ (途中で左の本棚)
	game.arrive("shelf_left")
	_check("p2" in game.state.got(), "左の本棚で 詩二 を手に入れる")
	game.arrive("bed")
	_check(game.stage_def()["id"] == "sleep", "ベッドで眠る")

	# 3. 寝ている: 詩一の 赤い で 詩二の ずれる が見え、夜 → 朝。詩一の 笑顔 と合わせる
	_check(not game.state.is_present(_w("ずれる")), "赤の前は ずれる が見えない")
	game.click(_uid("赤い"))
	_check(game.apply_tool(_uid("ずれる"), _uid("夜")) and _uid("朝") > 0, "夜 が ずれて 朝 に")
	game.give(_uid("やさしい"))
	game.give(_uid("朝"))
	_check(not game.tell(), "やさしい 朝 では起きない")
	game.give(_uid("朝"))
	game.give(_uid("笑顔"))
	_check(game.tell(), "朝 笑顔 (詩二+詩一) で起きる")

	# 4. 扉: 赤で ずれる を出して なくした → さがした → みつけた、詩二の 緑の で 詩三の 鍵
	game.arrive("shelf_right")
	_check("p3" in game.state.got(), "右の本棚で 詩三 を手に入れる")
	_check(not game.apply_tool(_uid("逆さ"), _uid("なくした")), "なくした は逆さにできない")
	_check(game.apply_tool(_uid("ずれる"), _uid("なくした")) and _uid("さがした") > 0, "なくした が ずれて さがした")
	_check(game.apply_tool(_uid("ずれる"), _uid("さがした")) and _uid("みつけた") > 0, "さがした が ずれて みつけた")
	_check(not game.state.is_present(_w("鍵")), "緑の前は 鍵 が見えない")
	game.click(_uid("緑の"))
	_check(not game.state.is_present(_w("ずれる")), "緑の間は ずれる は見えない")
	game.give(_uid("鍵"))
	game.give(_uid("みつけた"))
	_check(game.tell(), "鍵 みつけた (詩三+詩二の色+詩二の道具) で鍵が見つかる")

	# どの言葉も変えられる (例: 鳥 → 烏 → 島、部屋 ⇄ 外)
	game.click(_uid("赤い"))
	game.apply_tool(_uid("ずれる"), _uid("部屋"))
	_check(_uid("家") > 0, "部屋 が ずれて 家")
	game.undo()
	_check(game.apply_tool(_uid("逆さ"), _uid("部屋")) and _uid("外") > 0, "部屋 を逆さにして 外")
	game.undo()

	# 5. 窓: 作った色でしか見えない言葉で答える
	#    桃色 (白+赤) で きらきらした、水色 (白+青) で 明るい、黒 (白を逆さ) で 過去 → 逆さで 未来
	_check(not game.hint().contains("未来」と"), "窓の詩の前は 窓へ行くヒント")
	game.arrive("window")
	_check("p4" in game.state.got(), "窓で 詩四 を手に入れる")
	_check(game.hint().contains("きらきらした 明るい 未来"), "窓の詩を手に入れたら 答えを言うヒント")
	game.click(_uid("白い"))
	_check(game.state.is_present(_w("鳥")), "白で 詩三の 鳥 も見える")
	_check(not game.state.is_present(_w("きらきらした")), "白では きらきらした は見えない")
	_check(game.tool_result(_uid("白い"), _uid("部屋")) == "", "色は色以外には混ざらない")
	_check(game.apply_tool(_uid("白い"), _uid("赤い")) and _uid("桃色") > 0, "白 を 赤 に重ねて 桃色")
	game.click(_uid("桃色"))
	_check(game.state.is_present(_w("きらきらした")), "桃色で きらきらした が見える")
	game.give(_uid("きらきらした"))
	_check(game.apply_tool(_uid("白い"), _uid("青い")) and _uid("水色") > 0, "白 を 青 に重ねて 水色")
	game.click(_uid("水色"))
	_check(game.state.is_present(_w("明るい")), "水色で 詩二の 明るい が見える")
	game.give(_uid("明るい"))
	_check(game.apply_tool(_uid("逆さ"), _uid("白い")) and _uid("黒い") > 0, "白 を逆さにして 黒")
	game.click(_uid("黒い"))
	_check(game.state.is_present(_w("過去")), "黒で 過去 が見える")
	_check(game.apply_tool(_uid("逆さ"), _uid("過去")) and _uid("未来") > 0, "過去 を逆さにして 未来")
	game.give(_uid("未来"))
	_check(game.tell() and game.state.d["ended"], "きらきらした 明るい 未来 でエンディング")

	game.undo()
	_check(not game.state.d["ended"], "Undo でエンディング前へ")
	game.reset()
	_check(game.state.d["stage"] == 0 and game.state.got() == ["p1"] and _uid("涙") > 0, "Reset で初期状態 (涙 に戻る)")
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
