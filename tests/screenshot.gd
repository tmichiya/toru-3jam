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
	await _wait(4.0)
	_save("1_cry")
	game.give(_uid("雨が"))
	game.tell()
	await _wait(0.5)
	_save("1_cry_ng")
	game.give(_uid("笑顔を"))
	await _wait(0.3)
	_save("1_cry_give")
	game.tell()
	await _wait(5.0)
	_save("2_sleep")
	game.give(_uid("やさしい"))
	game.give(_uid("声で"))
	game.tell()
	await _wait(14.0)
	_save("3_door")
	game.click(_uid("金色の"))
	await _wait(2.5)
	_save("3_door_gold")
	game.give(_uid("鍵を"))
	game.give(_uid("さがして"))
	game.tell()
	await _wait(5.0)
	_save("4_future")
	for t in ["きらきらとした", "明るい", "未来へ"]:
		game.give(_uid(t))
	await _wait(0.3)
	_save("4_future_give")
	game.tell()
	await _wait(8.0)
	_save("5_end")
	quit(0)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _save(name: String) -> void:
	var path := out_dir + "/shot_" + name + ".png"
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _uid(t: String) -> int:
	for line in game.state.lines():
		for w in line["words"]:
			if w["t"] == t:
				return w["uid"]
	return -1
