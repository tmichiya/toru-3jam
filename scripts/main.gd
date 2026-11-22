extends Node2D
## 配線だけを行う。各部品は Game の signal を購読し、互いを直接は触らない。

const POEM_PATH := "res://data/poem.json"

@onready var game: Game = $Game
@onready var background: PoemBackground = $Background
@onready var poem_view: PoemView = $Poem
@onready var fx: FxLayer = $FX
@onready var input_ctrl: InputCtrl = $Input
@onready var ui: GameUI = $UI
@onready var sfx: Sfx = $SFX


func _ready() -> void:
	game.load_poem(POEM_PATH)
	background.setup(game, poem_view)
	poem_view.setup(game)
	fx.setup(game, poem_view)
	input_ctrl.setup(game, poem_view)
	ui.setup(game)
	sfx.setup(game)
