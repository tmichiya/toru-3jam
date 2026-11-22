class_name Ground
extends Node2D
## 主人公が歩く一本線と、横スクロールが分かるように並ぶ草や花。

const X_FROM := -240
const X_TO := 1200
const LINE := Color("e8e4dc")
const GRASS := Color("9fd08a")
const FLOWERS := [Color("ff9fb8"), Color("ffd47e"), Color("9fc8ff")]

var _tufts: Array = []  # [x, kind]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var x := X_FROM
	while x < X_TO:
		_tufts.append([x, rng.randi_range(0, 3)])
		x += rng.randi_range(14, 40)


func _draw() -> void:
	var y := UIConst.GROUND_Y
	draw_rect(Rect2(X_FROM, y, X_TO - X_FROM, 1), LINE)
	for t in _tufts:
		var x: int = t[0]
		match t[1]:
			0, 1:
				# 草
				for p in [Vector2(0, -1), Vector2(0, -2), Vector2(-1, -1), Vector2(2, -1), Vector2(2, -2), Vector2(2, -3)]:
					draw_rect(Rect2(Vector2(x, y) + p, Vector2.ONE), GRASS)
			2:
				# 花
				var c: Color = FLOWERS[x % FLOWERS.size()]
				for p in [Vector2(0, -1), Vector2(0, -2), Vector2(0, -3)]:
					draw_rect(Rect2(Vector2(x, y) + p, Vector2.ONE), GRASS)
				for p in [Vector2(0, -5), Vector2(-1, -4), Vector2(1, -4), Vector2(0, -4)]:
					draw_rect(Rect2(Vector2(x, y) + p, Vector2.ONE), c)
			3:
				# 小石
				draw_rect(Rect2(x, y - 1, 2, 1), LINE)
