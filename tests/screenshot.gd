extends SceneTree
## main.tscn を実行し、途中経過を PNG に保存する (見た目確認用)。
## godot --path . -s res://tests/screenshot.gd -- <出力フォルダ>

var out_dir := "user://"
var game: Game


func _init() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		out_dir = OS.get_cmdline_user_args()[0]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	game = main.get_node("Game")
	await _wait(3.5)
	_save("start")
	game.click(_uid("両手"))
	game.click(_uid("風"))
	await _wait(0.35)
	_save("anim_hands_wind")
	game.click(_uid("青い"))
	await _wait(2.0)
	_save("blue")
	var at := _find("さらなる")
	game.drop(_uid("言葉"), at.x, _uid("さらなる"))
	await _wait(4.0)
	_save("reveal")
	game.click(_uid("鳥"))
	await _wait(0.6)
	_save("anim_bird")
	game.click(_uid("朝"))
	game.click(_uid("川"))
	await _wait(0.6)
	_save("anim_morning_river")
	await _wait(2.0)
	game.click(_uid("金色"))
	at = _find("明るい")
	game.drop(_uid("未来"), at.x, _uid("明るい"))
	game.drop(_uid("きらきら"), at.x, -1)
	await _wait(6.0)
	_save("end")
	quit(0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var path := out_dir + "/shot_" + name + ".png"
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _find(t: String) -> Vector2i:
	var ls := game.state.lines()
	for li in ls.size():
		var ws: Array = ls[li]["words"]
		for wi in ws.size():
			if ws[wi]["t"] == t and not GameState.is_gap(ws[wi]):
				return Vector2i(li, wi)
	return Vector2i(-1, -1)


func _uid(t: String) -> int:
	var at := _find(t)
	return game.state.word(at.x, at.y)["uid"]
