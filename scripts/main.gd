extends Node2D
## 配線だけを行う。各部品は Game の signal を購読し、互いを直接は触らない。
##  - BackgroundLayer: 空の色 (ディザのグラデーション、色の言葉で変わる)
##  - World: 部屋の絵・目印・主人公 (部屋の絵のピクセル座標で配置)
##  - PoemLayer: 画面上方の詩・演出・入力・UI
##  - PostLayer: 画面全体の彩度 (場面が進むほど色づく)
##  - IntroLayer: はじめの文章 (読み終わると消えてゲームが始まる)

const POEM_PATH := "res://data/poem.json"

@onready var game: Game = $Game
@onready var background: PoemBackground = $BackgroundLayer/Background
@onready var props: RoomProps = $World/Props
@onready var player: Player = $World/Player
@onready var poem_view: PoemView = $PoemLayer/Poem
@onready var fx: FxLayer = $PoemLayer/FX
@onready var input_ctrl: InputCtrl = $PoemLayer/Input
@onready var ui: GameUI = $PoemLayer/UI
@onready var saturation: SaturationPost = $PostLayer/Saturation
@onready var sfx: Sfx = $SFX
@onready var intro: Intro = $IntroLayer/Intro


func _ready() -> void:
	game.load_poem(POEM_PATH)
	background.setup(game, poem_view)
	props.setup(game, [$World/RoomBG, $World/Room])
	player.setup(game)
	poem_view.setup(game)
	fx.setup(game, poem_view, player)
	ui.setup(game, player, poem_view)
	input_ctrl.setup(game, poem_view, player)
	saturation.setup(game)
	sfx.setup(game)
	intro.setup(game.poem.get("intro", []))
	# スマホを縦にしているときの案内 (いちばん上に重ねる)
	var notice_layer := CanvasLayer.new()
	notice_layer.layer = 30
	add_child(notice_layer)
	notice_layer.add_child(OrientationNotice.new())
