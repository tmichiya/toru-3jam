extends SceneTree
## 想定手順でエンディングまで到達できるかをロジックだけで確かめる。
## godot --headless --path . -s res://tests/test_solution.gd

var game: Game
var failed := false


func _init() -> void:
	game = Game.new()
	root.add_child(game)
	game.load_poem("res://data/poem.json")

	# 1. 泣いている
	_check(game.capacity() == 1, "最初は1語まで")
	_check(game.give(_uid("雨が")), "雨が を渡す")
	_check(not game.give(_uid("ふる")), "上限を超えては渡せない")
	_check(not game.tell(), "雨が では泣きやまない")
	_check(game.state.message().is_empty() and game.state.is_present(_w("雨が")), "伝えた言葉は詩へ戻る")
	game.give(_uid("笑顔を"))
	game.take_back(_uid("笑顔を"))
	_check(game.state.message().is_empty(), "吹き出しから戻せる")
	game.give(_uid("笑顔を"))
	_check(game.tell(), "笑顔 で泣きやむ")
	_check(game.stage_def()["id"] == "sleep" and game.capacity() == 2, "寝る場面へ・2語まで")

	# 2. 寝ている
	game.give(_uid("やさしい"))
	game.give(_uid("声で"))
	_check(game.tell(), "やさしい 声 で起きる")
	_check(game.stage_def()["id"] == "door", "扉の場面へ")

	# 3. 扉
	_check(not game.state.can_see(_w("鍵を")), "金色の前は 鍵 が見えない")
	_check(not game.give(_uid("鍵を")), "見えない言葉は渡せない")
	game.click(_uid("金色の"))
	_check(game.state.d["color"] == "gold", "金色の で背景が金")
	game.give(_uid("鍵を"))
	game.give(_uid("さがして"))
	_check(game.tell(), "鍵 さがして で鍵が見つかる")
	_check(game.stage_def()["id"] == "future" and game.capacity() == 3, "未来の場面へ・3語まで")

	# 4. 未来
	game.give(_uid("明るい"))
	game.give(_uid("きらきらとした"))
	game.give(_uid("未来へ"))
	_check(not game.tell(), "順番がちがうと伝わらない")
	for t in ["きらきらとした", "明るい", "未来へ"]:
		game.give(_uid(t))
	_check(game.tell() and game.state.d["ended"], "エンディング")

	game.undo()
	_check(not game.state.d["ended"], "Undo でエンディング前へ")
	game.reset()
	_check(game.state.d["stage"] == 0 and game.state.d["color"] == "gray", "Reset で初期状態")
	print("FAILED" if failed else "ALL OK")
	quit(1 if failed else 0)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + msg)
	else:
		print("ok  ", msg)


func _w(t: String) -> Dictionary:
	for line in game.state.lines():
		for w in line["words"]:
			if w["t"] == t:
				return w
	return {}


func _uid(t: String) -> int:
	return _w(t)["uid"]
