extends Node2D
## Lógica principal del clicker (antes Click.script + CreateBuildings/*.script).
##
## - Cada clic en la impresora da 1 dólar.
## - Cada 10 dólares ganados aparece una moneda (máx. 27) que da 1 dólar cada 3 s.
## - Los botones compran bares (10$), fábricas (100$) y hospitales (200$), máx. 5 de cada,
##   que dan 5, 25 y 50 dólares cada 3 s.

const MAX_COINS := 27
const CLICKS_PER_COIN := 10
const COINS_PER_ROW := 9
const COIN_ORIGIN := Vector2(40, 490)
const COIN_SPACING := Vector2(35, 37)
const BUILDING_SPACING := 100.0

const CoinScene: PackedScene = preload("res://scenes/coin.tscn")
const BuildingScene: PackedScene = preload("res://scenes/building.tscn")

var dollars := 0
var coins := 0
var clicks := 0

@onready var hud := $HUD
@onready var printer: Clickable = $Printer
@onready var coins_root: Node2D = $Coins
@onready var buildings_root: Node2D = $Buildings
@onready var new_coin_sound: AudioStreamPlayer = $NewCoinSound


func _ready() -> void:
	printer.pressed.connect(_on_printer_pressed)
	for button: ShopButton in $Buttons.get_children():
		button.pressed.connect(_on_shop_button_pressed.bind(button))
		hud.set_building_count(button.building_name, button.count, button.max_count)
	_refresh_hud()


func add_dollars(amount: int) -> void:
	for i in amount:
		dollars += 1
		clicks += 1
		if clicks >= CLICKS_PER_COIN:
			clicks = 0
			_spawn_coin()
	_refresh_hud()


func _on_printer_pressed() -> void:
	$Printer/CashSound.play()
	add_dollars(1)


func _on_shop_button_pressed(button: ShopButton) -> void:
	if button.count >= button.max_count or dollars < button.cost:
		return
	dollars -= button.cost
	button.count += 1

	var building: Building = BuildingScene.instantiate()
	building.texture = button.building_texture
	building.income = button.income
	building.position = button.row_origin + Vector2(BUILDING_SPACING * (button.count - 1), 0)
	building.produced.connect(add_dollars)
	buildings_root.add_child(building)

	hud.set_building_count(button.building_name, button.count, button.max_count)
	_refresh_hud()


func _spawn_coin() -> void:
	if coins >= MAX_COINS:
		return
	var index := coins
	coins += 1

	var coin: Coin = CoinScene.instantiate()
	var cell := Vector2(index % COINS_PER_ROW, floori(index / float(COINS_PER_ROW)))
	coin.position = COIN_ORIGIN + cell * COIN_SPACING
	coin.produced.connect(add_dollars)
	coins_root.add_child(coin)
	new_coin_sound.play()


func _refresh_hud() -> void:
	hud.set_dollars(dollars)
	hud.set_coins(coins, MAX_COINS)
	hud.set_progress(0.0 if coins >= MAX_COINS else float(clicks) / CLICKS_PER_COIN)
