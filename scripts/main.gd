extends Node2D
## 配線だけを行う。各部品は Game の signal を購読し、互いを直接は触らない。
##  - BackgroundLayer: 空 (ディザのグラデーション、色の言葉で色が変わる)
##  - World: 地面・扉・主人公・カメラ (横スクロール)
##  - PoemLayer: 画面上方の詩・演出・入力・UI (スクロールしない)
##  - PostLayer: 画面全体の彩度 (場面が進むほど色づく)

const POEM_PATH := "res://data/poem.json"

@onready var game: Game = $Game
@onready var background: PoemBackground = $BackgroundLayer/Background
@onready var ground: Ground = $World/Ground
@onready var door: Door = $World/Door
@onready var player: Player = $World/Player
@onready var camera: WorldCamera = $World/Camera
@onready var poem_view: PoemView = $PoemLayer/Poem
@onready var fx: FxLayer = $PoemLayer/FX
@onready var input_ctrl: InputCtrl = $PoemLayer/Input
@onready var ui: GameUI = $PoemLayer/UI
@onready var saturation: SaturationPost = $PostLayer/Saturation
@onready var sfx: Sfx = $SFX


func _ready() -> void:
	game.load_poem(POEM_PATH)
	background.setup(game, poem_view)
	door.setup(game)
	player.setup(game)
	camera.setup(player)
	poem_view.setup(game)
	fx.setup(game, poem_view, player)
	input_ctrl.setup(game, poem_view, player)
	ui.setup(game, player)
	saturation.setup(game)
	sfx.setup(game)
