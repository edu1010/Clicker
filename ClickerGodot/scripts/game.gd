extends Node2D
## Lógica principal del clicker.
##
## - Clic en la impresora: dinero según las mejoras de clic.
## - Edificios sin límite con coste x1.15 por compra; cada tipo paga a su ritmo
##   y duplica su producción en los hitos 10, 25, 50, 100, 150...
## - Monedas doradas aleatorias: premio instantáneo o frenesí x7, y +2 % permanente.
## - Guardado automático y ganancias mientras no juegas (50 %, máx. 8 h).

const GOLDEN_BONUS_PER_COIN := 0.02
const FRENZY_MULTIPLIER := 7.0
const FRENZY_TIME := 30.0
const LUCKY_SECONDS := 60.0
const LUCKY_MIN := 30.0
const GOLDEN_FIRST_DELAY := Vector2(20, 40)
const GOLDEN_DELAY := Vector2(30, 75)
const GOLDEN_SPAWN_AREAS: Array[Rect2] = [Rect2(400, 225, 500, 380), Rect2(40, 150, 280, 240)]

const TRAY_MAX := 27
const TRAY_PER_ROW := 9
const TRAY_ORIGIN := Vector2(40, 490)
const TRAY_SPACING := Vector2(35, 37)

const INK_BASE_COST := 100.0
const INK_GROWTH := 10.0
const BOOST_BASE_COST := 1000.0
const BOOST_GROWTH := 10.0
const BOOST_PER_LEVEL := 0.01
const UPGRADE_REVEAL_FRACTION := 0.5

const AUTOSAVE_TIME := 10.0
const OFFLINE_EFFICIENCY := 0.5
const OFFLINE_MAX_SECONDS := 8.0 * 3600.0
const OFFLINE_MIN_SECONDS := 60.0

const GOLD := Color(1.0, 0.85, 0.3)
const GREEN := Color(0.7, 1.0, 0.6)

const CoinScene: PackedScene = preload("res://scenes/coin.tscn")
const GoldenCoinScene: PackedScene = preload("res://scenes/golden_coin.tscn")

@export var use_save := true
@export var save_path := "user://save.cfg"

var dollars := 0.0
var total_earned := 0.0
var golden_coins := 0
var ink_level := 0
var boost_level := 0
var frenzy_left := 0.0
var fx_enabled := true
var buttons: Array[ShopButton] = []
var rows: Array[BuildingRow] = []

var _shown_dollars := 0.0
var _golden_timer := 0.0
var _autosave_timer := 0.0

@onready var hud: Hud = $HUD
@onready var printer: Clickable = $Printer
@onready var effects: Node2D = $Effects
@onready var tray: Node2D = $CoinTray
@onready var golden_root: Node2D = $GoldenCoins


func _ready() -> void:
	# La moneda dorada (z alto) debe recibir el clic antes que lo que tenga debajo.
	get_viewport().physics_object_picking_sort = true
	get_viewport().physics_object_picking_first_only = true

	for button: ShopButton in $Buttons.get_children():
		buttons.append(button)
		button.pressed.connect(_on_shop_button_pressed.bind(button))
	for row: BuildingRow in $Rows.get_children():
		rows.append(row)
	printer.pressed.connect(_on_printer_pressed)
	hud.ink_pressed.connect(_buy_ink)
	hud.boost_pressed.connect(_buy_boost)
	hud.fx_toggled.connect(func(enabled: bool) -> void: fx_enabled = enabled)

	_golden_timer = randf_range(GOLDEN_FIRST_DELAY.x, GOLDEN_FIRST_DELAY.y)
	if use_save:
		load_game()
	_shown_dollars = dollars
	hud.set_fx(fx_enabled)
	_rebuild_tray()
	_refresh()


func _process(delta: float) -> void:
	_pay_buildings(delta)

	if frenzy_left > 0.0:
		frenzy_left = maxf(0.0, frenzy_left - delta)

	_golden_timer -= delta
	if _golden_timer <= 0.0:
		_golden_timer = randf_range(GOLDEN_DELAY.x, GOLDEN_DELAY.y)
		spawn_golden_coin()

	if use_save:
		_autosave_timer += delta
		if _autosave_timer >= AUTOSAVE_TIME:
			_autosave_timer = 0.0
			save_game()

	# El contador sube poco a poco; al gastar baja de golpe.
	if fx_enabled and dollars > _shown_dollars:
		_shown_dollars = lerpf(_shown_dollars, dollars, minf(1.0, delta * 12.0))
		if dollars - _shown_dollars < 0.5:
			_shown_dollars = dollars
	else:
		_shown_dollars = dollars

	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if use_save:
			save_game()


# --- Economía -----------------------------------------------------------------

func global_multiplier() -> float:
	var frenzy := FRENZY_MULTIPLIER if frenzy_left > 0.0 else 1.0
	return (1.0 + GOLDEN_BONUS_PER_COIN * golden_coins) * frenzy


func income_per_second() -> float:
	var multiplier := global_multiplier()
	var total := 0.0
	for button in buttons:
		total += button.income(multiplier)
	return total


func click_value() -> float:
	return pow(2.0, ink_level) * global_multiplier() \
			+ income_per_second() * BOOST_PER_LEVEL * boost_level


func ink_cost() -> float:
	return INK_BASE_COST * pow(INK_GROWTH, ink_level)


func boost_cost() -> float:
	return BOOST_BASE_COST * pow(BOOST_GROWTH, boost_level)


func earn(amount: float) -> void:
	dollars += amount
	total_earned += amount


func _pay_buildings(delta: float) -> void:
	var multiplier := global_multiplier()
	for i in buttons.size():
		var button := buttons[i]
		if button.count == 0:
			button.timer = 0.0
			continue
		button.timer += delta
		if button.timer < button.period:
			continue
		button.timer -= button.period
		var amount := button.income(multiplier) * button.period
		earn(amount)
		if fx_enabled:
			rows[i].pulse()
			_popup(rows[i].position + rows[i].popup_point(), "+" + Fmt.small(amount), GREEN, 15)


# --- Acciones del jugador ---------------------------------------------------------

func _on_printer_pressed() -> void:
	$Printer/CashSound.play()
	var value := click_value()
	earn(value)
	if fx_enabled:
		_popup(get_global_mouse_position(), "+" + Fmt.small(value), GOLD, 20)


func _on_shop_button_pressed(button: ShopButton) -> void:
	if not button.is_unlocked(total_earned):
		return
	var price := button.cost()
	if dollars < price:
		_popup(button.position + Vector2(0, 50), "Need %s $" % Fmt.money(price), Color(1, 0.5, 0.5), 14, true)
		return
	var level_before := button.milestone_level()
	dollars -= price
	button.count += 1
	if button.milestone_level() > level_before:
		var row := rows[buttons.find(button)]
		_popup(row.position + Vector2(295, 40), "%s x2!" % button.building_name, GOLD, 24, true)
	_refresh()


func _buy_ink() -> void:
	if dollars < ink_cost():
		return
	dollars -= ink_cost()
	ink_level += 1
	_refresh()


func _buy_boost() -> void:
	if dollars < boost_cost():
		return
	dollars -= boost_cost()
	boost_level += 1
	_refresh()


# --- Monedas doradas --------------------------------------------------------------

func spawn_golden_coin() -> GoldenCoin:
	var area: Rect2 = GOLDEN_SPAWN_AREAS.pick_random()
	var coin: GoldenCoin = GoldenCoinScene.instantiate()
	coin.position = area.position + Vector2(randf() * area.size.x, randf() * area.size.y)
	coin.collected.connect(_on_golden_collected)
	golden_root.add_child(coin)
	$CoinSound.play()
	return coin


func _on_golden_collected(coin: GoldenCoin) -> void:
	golden_coins += 1
	$NewCoinSound.play()
	_add_tray_coin(golden_coins - 1)
	if randf() < 0.5:
		var amount := maxf(LUCKY_MIN, income_per_second() * LUCKY_SECONDS)
		earn(amount)
		_popup(coin.position, "Lucky! +%s $" % Fmt.money(amount), GOLD, 22, true)
	else:
		frenzy_left = FRENZY_TIME
		_popup(coin.position, "FRENZY x7!", GOLD, 24, true)
	_refresh()


func _rebuild_tray() -> void:
	for child in tray.get_children():
		child.queue_free()
	for i in mini(golden_coins, TRAY_MAX):
		_add_tray_coin(i)


func _add_tray_coin(index: int) -> void:
	if index >= TRAY_MAX:
		return
	var coin: Node2D = CoinScene.instantiate()
	var cell := Vector2(index % TRAY_PER_ROW, floori(index / float(TRAY_PER_ROW)))
	coin.position = TRAY_ORIGIN + cell * TRAY_SPACING
	tray.add_child(coin)


# --- Interfaz ---------------------------------------------------------------------

func _refresh() -> void:
	var multiplier := global_multiplier()
	for i in buttons.size():
		var button := buttons[i]
		button.refresh(dollars, total_earned)
		rows[i].show_building(button, button.is_unlocked(total_earned), button.income(multiplier))

	hud.set_dollars(Fmt.money(_shown_dollars))
	hud.set_rate(income_per_second(), frenzy_left > 0.0)
	hud.set_frenzy(frenzy_left, FRENZY_TIME)
	hud.set_coins(golden_coins, GOLDEN_BONUS_PER_COIN * golden_coins)
	_refresh_upgrade("ink", "Better Ink", "Click x2", ink_level, ink_cost())
	_refresh_upgrade("boost", "Golden Touch", "Click +1% $/s", boost_level, boost_cost())


func _refresh_upgrade(which: String, upgrade_name: String, effect: String, level: int, price: float) -> void:
	if level == 0 and total_earned < price * UPGRADE_REVEAL_FRACTION:
		hud.set_upgrade(which, "???\n%s $" % Fmt.money(price), false)
	else:
		hud.set_upgrade(which, "%s (Lv %d)\n%s · %s $" % [upgrade_name, level, effect, Fmt.money(price)],
				dollars >= price)


func _popup(at: Vector2, text: String, color: Color, size: int, always := false) -> void:
	if fx_enabled or always:
		FloatingText.spawn(effects, at, text, color, size)


# --- Guardado ---------------------------------------------------------------------

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "version", 1)
	cfg.set_value("game", "dollars", dollars)
	cfg.set_value("game", "total_earned", total_earned)
	cfg.set_value("game", "golden_coins", golden_coins)
	cfg.set_value("game", "ink_level", ink_level)
	cfg.set_value("game", "boost_level", boost_level)
	cfg.set_value("game", "saved_at", Time.get_unix_time_from_system())
	cfg.set_value("settings", "fx_enabled", fx_enabled)
	for button in buttons:
		cfg.set_value("buildings", button.name, button.count)
	cfg.save(save_path)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	dollars = cfg.get_value("game", "dollars", 0.0)
	total_earned = cfg.get_value("game", "total_earned", 0.0)
	golden_coins = cfg.get_value("game", "golden_coins", 0)
	ink_level = cfg.get_value("game", "ink_level", 0)
	boost_level = cfg.get_value("game", "boost_level", 0)
	fx_enabled = cfg.get_value("settings", "fx_enabled", true)
	for button in buttons:
		button.count = cfg.get_value("buildings", button.name, 0)

	var saved_at: float = cfg.get_value("game", "saved_at", Time.get_unix_time_from_system())
	var away := clampf(Time.get_unix_time_from_system() - saved_at, 0.0, OFFLINE_MAX_SECONDS)
	if away < OFFLINE_MIN_SECONDS:
		return
	var offline := income_per_second() * away * OFFLINE_EFFICIENCY
	if offline >= 1.0:
		earn(offline)
		hud.show_welcome("While you were away (%s) your city earned %s $." % [_duration(away), Fmt.money(offline)])


static func _duration(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [floori(minutes / 60.0), minutes % 60]
