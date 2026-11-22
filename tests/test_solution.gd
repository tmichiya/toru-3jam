extends SceneTree
## 想定手順でエンディングまで到達できるかをロジックだけで確かめる。
## godot --headless --path . -s res://tests/test_solution.gd

var game: Game


func _init() -> void:

	game = Game.new()
	root.add_child(game)
	game.load_poem("res://data/poem.json")

	_check(not game.state.is_present(_w("言葉")), "青の前は 言葉 が見えない")
	game.click(_uid("青い"))
	_check(game.state.d["color"] == "blue", "青い をクリックで背景が青")
	_check(game.state.is_present(_w("言葉")), "言葉 が見える")

	var at := _find("ふく")
	_check(not game.drop(_uid("言葉"), at.x, _uid("ふく")), "つながらない場所には置けない")
	_check(game.state.find_gap_of(_uid("言葉")).x < 0, "置けなければ元の場所のまま")

	at = _find("さらなる")
	_check(game.drop(_uid("言葉"), at.x, _uid("さらなる")), "言葉 を さらなる の後ろへ固定")
	_check(game.state.lines()[3]["revealed"], "新しい行が出現")
	_check(game.hint().contains("未来"), "ヒントが次の目標へ")

	game.click(_uid("金色"))
	_check(game.state.d["color"] == "gold", "金色 をクリックで背景が金")
	at = _find("明るい")
	_check(not game.drop(_uid("未来"), _find("朝").x, _uid("朝")), "未来 は 朝 の後ろには置けない")
	_check(game.drop(_uid("未来"), at.x, _uid("明るい")), "未来 を 明るい の後ろへ")
	_check(not game.state.d["ended"], "まだ終わらない")
	_check(game.drop(_uid("きらきら"), at.x, -1), "きらきら を行頭 (明るい の前) へ")
	_check(game.state.d["ended"], "エンディング")

	game.undo()
	_check(not game.state.d["ended"], "Undo でエンディング前へ")
	game.return_home(_uid("未来"))
	_check(game.state.find_gap_of(_uid("未来")).x < 0, "未来 が元の場所へ戻る")
	game.reset()
	_check(game.state.d["color"] == "gray" and game.state.d["fired"].is_empty(), "Reset で初期状態")
	print("ALL OK")
	quit(0)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		push_error("FAIL: " + msg)
		quit(1)
	else:
		print("ok  ", msg)


func _find(t: String) -> Vector2i:
	var ls := game.state.lines()
	for li in ls.size():
		var ws: Array = ls[li]["words"]
		for wi in ws.size():
			var w: Dictionary = ws[wi]
			if w["t"] == t and not GameState.is_gap(w):
				return Vector2i(li, wi)
	return Vector2i(-1, -1)


func _w(t: String) -> Dictionary:
	var at := _find(t)
	return game.state.word(at.x, at.y)


func _uid(t: String) -> int:
	return _w(t)["uid"]
