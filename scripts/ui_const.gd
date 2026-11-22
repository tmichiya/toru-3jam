class_name UIConst
extends RefCounted
## 見た目の共通定数

const FONT: Font = preload("res://fonts/text_font.ttf")
const FONT_SIZE := 12
const SCREEN := Vector2(480, 270)

const TEXT_COLOR := Color("f4f1ea")
const HILITE_COLOR := Color("fff1a0")
const INVALID_COLOR := Color("9a8f8f")
const MOVABLE_COLOR := Color("c8f0ff")


static func text_width(t: String, size: int = FONT_SIZE) -> float:
	return FONT.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_height(size: int = FONT_SIZE) -> float:
	return FONT.get_height(size)
