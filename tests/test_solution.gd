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

	# 1. 泣いている
	_check(game.state.got().is_empty(), "最初は詩を持っていない")
	game.arrive("shelf_left")
	_check(game.state.got().is_empty(), "まだ開いていない本棚からは手に入らない")
	game.arrive("shelf_bottom")
	_check(game.state.got() == ["p1"], "下の本棚で 詩一 を手に入れる")
	_check(game.give(_uid("ひとり")), "ひとり を渡す")
	_check(not game.give(_uid("ないている")), "1語までしか渡せない")
	_check(not game.tell(), "ひとり では泣きやまない")
	game.give(_uid("笑顔を"))
	_check(game.tell(), "笑顔 で泣きやむ")
	_check(game.stage_def()["id"] == "sleepy", "ねむそうな場面へ")

	# 2. ベッドへ (途中で左の本棚)
	game.arrive("shelf_left")
	_check("p2" in game.state.got(), "左の本棚で 詩二 を手に入れる")
	game.arrive("bed")
	_check(game.stage_def()["id"] == "sleep", "ベッドで眠る")

	# 3. 寝ている → 過去の詩 (笑顔) も使って起こす
	game.give(_uid("やさしい"))
	game.give(_uid("声"))
	_check(not game.tell(), "やさしい 声 (詩二だけ) では起きない")
	game.give(_uid("やさしい"))
	game.give(_uid("笑顔を"))
	_check(game.tell(), "やさしい 笑顔 で起きる")
	_check(game.stage_def()["id"] == "door", "扉の場面へ")

	# 4. 扉 → 右の本棚
	game.arrive("window")
	_check(not "p4" in game.state.got(), "窓はまだ開いていない")
	game.arrive("shelf_right")
	_check("p3" in game.state.got(), "右の本棚で 詩三 を手に入れる")
	_check(not game.give(_uid("鍵")), "金色の前は 鍵 が見えない")
	game.click(_uid("金色の"))
	game.give(_uid("鍵"))
	game.give(_uid("さがして"))
	_check(game.tell(), "鍵 さがして (詩三+詩一) で鍵を見つける")
	_check(game.stage_def()["id"] == "future", "未来の場面へ")

	# 5. 窓 → 未来
	game.arrive("window")
	_check("p4" in game.state.got(), "窓で 詩四 を手に入れる")
	for t in ["きらきらとした", "明るい", "未来"]:
		game.give(_uid(t))
	_check(game.tell() and game.state.d["ended"], "きらきらとした 明るい 未来 (詩四+二+三) でエンディング")

	game.undo()
	_check(not game.state.d["ended"], "Undo でエンディング前へ")
	game.reset()
	_check(game.state.d["stage"] == 0 and game.state.got().is_empty(), "Reset で初期状態")
	print("FAILED" if failed else "ALL OK")
	quit(1 if failed else 0)


func _test_nav() -> void:
	var nav := RoomNav.new(game.poem["nav"])
	var path := nav.find_path(Vector2(135, 177), Vector2(88, 100))
	_check(not path.is_empty() and path[path.size() - 1].distance_to(Vector2(88, 105)) < 1.0, "下の床からベッドへ行ける")
	_check(Vector2(96, 129) in path or Vector2(82, 129) in path, "ベッドへは左の段を通る")
	path = nav.find_path(Vector2(88, 105), Vector2(234, 100))
	_check(not path.is_empty() and path[path.size() - 1].distance_to(Vector2(234, 106)) < 1.0, "ベッドから扉へ行ける")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + msg)
	else:
		print("ok  ", msg)


func _uid(t: String) -> int:
	for pid in game.state.d["poems"]:
		for line in game.state.poem_lines(pid):
			for w in line["words"]:
				if w["t"] == t:
					return w["uid"]
	return -1
