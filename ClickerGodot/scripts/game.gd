extends Node2D
## Lógica principal del clicker.
##
## Economía: clic en la impresora + edificios sin límite (coste x1.15), cada uno con
## su ritmo de pago, hitos x2, 4 mejoras x2 y sinergia con el siguiente edificio.
## Multiplicadores globales: monedas doradas (+2 %), Reputación (+1 %), logros (+1 %)
## y modificadores temporales (frenesí, eventos...).
## Prestigio: "fundar una ciudad nueva" reinicia la ciudad a cambio de Reputación.

const GOLDEN_BONUS_PER_COIN := 0.02
const REPUTATION_BONUS := 0.01
const ACHIEVEMENT_BONUS := 0.01
const PRESTIGE_DIVISOR := 1e5

const FRENZY_MULTIPLIER := 7.0
const FRENZY_TIME := 30.0
const CLICK_FRENZY_MULTIPLIER := 777.0
const CLICK_FRENZY_TIME := 10.0
const LUCKY_SECONDS := 60.0
const LUCKY_MIN := 30.0
const RED_CHANCE := 0.12
const RED_JACKPOT_SECONDS := 600.0
const RED_LOSS := 0.1
const CHAIN_MAX := 7
const CHAIN_CONTINUE_CHANCE := 0.85
const GOLDEN_FIRST_DELAY := Vector2(20, 40)
const GOLDEN_DELAY := Vector2(30, 75)
const GOLDEN_SPAWN_AREAS: Array[Rect2] = [Rect2(400, 225, 500, 380), Rect2(40, 150, 280, 220)]

const EVENT_FIRST_DELAY := Vector2(180, 240)
const EVENT_DELAY := Vector2(180, 360)

const COMBO_STEP := 0.05
const COMBO_WINDOW := 0.6
const COMBO_DECAY_DELAY := 1.0
const COMBO_DECAY_RATE := 1.5

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

const SAVE_VERSION := 2
const AUTOSAVE_TIME := 10.0
const OFFLINE_EFFICIENCY := 0.5
const OFFLINE_EFFICIENCY_UPGRADED := 0.75
const OFFLINE_MAX_SECONDS := 8.0 * 3600.0
const OFFLINE_MIN_SECONDS := 60.0

## Duración de un ciclo día/noche en segundos.
const DAY_LENGTH := 240.0
const DOLLARS_LABEL_POS := Vector2(175, 86)
const VOLUME_BUSES := ["Master", "Music", "SFX"]

const GOLD := Color(1.0, 0.85, 0.3)
const GREEN := Color(0.7, 1.0, 0.6)
const RED := Color(1.0, 0.45, 0.45)

const CoinScene: PackedScene = preload("res://scenes/coin.tscn")
const GoldenCoinScene: PackedScene = preload("res://scenes/golden_coin.tscn")

@export var use_save := true
@export var save_path := "user://save.cfg"

# Ciudad actual (se reinicia al prestigiar).
var dollars := 0.0
var total_earned := 0.0
var ink_level := 0
var boost_level := 0
## {target, factor, time_left, duration, label}. time_left = INF -> dura toda la ciudad.
var modifiers: Array[Dictionary] = []
var payouts: Array[Dictionary] = []

# Permanente.
var lifetime_earned := 0.0
var prestige_points := 0
var chips := 0
var cities := 0
var reputation_upgrades := {}
var achievements := {}
var golden_coins := 0

# Estadísticas.
var clicks_total := 0
var best_ips := 0.0
var time_played := 0.0
var red_clicked := 0
var best_chain := 0
var best_combo := 1.0
var events_resolved := 0

var combo := 1.0
var fx_enabled := true
var day_time := 0.0
var buttons: Array[ShopButton] = []
var rows: Array[BuildingRow] = []
var achievement_list: Array[Dictionary] = GameData.achievements()
var reputation_list: Array[Dictionary] = GameData.reputation_upgrades()
var event_list: Array[Dictionary] = GameData.events()

var _shown_dollars := 0.0
var _golden_timer := 0.0
var _event_timer := 0.0
var _autosave_timer := 0.0
var _achievement_timer := 0.0
var _since_last_click := 99.0
var _resetting := false

@onready var hud: Hud = $HUD
@onready var menu: GameMenu = $HUD/Menu
@onready var printer: Clickable = $Printer
@onready var effects: Node2D = $Effects
@onready var tray: Node2D = $CoinTray
@onready var golden_root: Node2D = $GoldenCoins


func _ready() -> void:
	hud.apply_theme(UiTheme.create())
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
	hud.menu_pressed.connect(menu.open)
	menu.game = self

	_golden_timer = randf_range(GOLDEN_FIRST_DELAY.x, GOLDEN_FIRST_DELAY.y)
	_event_timer = randf_range(EVENT_FIRST_DELAY.x, EVENT_FIRST_DELAY.y)
	if use_save:
		load_game()
	_shown_dollars = dollars
	_rebuild_tray()
	_refresh()


func _process(delta: float) -> void:
	time_played += delta
	day_time = fmod(day_time + delta, DAY_LENGTH)
	var night := night_amount()
	for row in rows:
		row.set_daylight(night)
	_tick_modifiers(delta)
	_pay_buildings(delta)
	_tick_payouts(delta)
	_tick_combo(delta)

	_golden_timer -= delta
	if _golden_timer <= 0.0:
		_golden_timer = _next_golden_delay()
		spawn_golden_coin("red" if randf() < RED_CHANCE else "gold")

	_event_timer -= delta
	if _event_timer <= 0.0 and not hud.is_event_open():
		_event_timer = randf_range(EVENT_DELAY.x, EVENT_DELAY.y)
		trigger_random_event()

	_achievement_timer += delta
	if _achievement_timer >= 1.0:
		_achievement_timer = 0.0
		best_ips = maxf(best_ips, income_per_second())
		check_achievements()

	if use_save and not _resetting:
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
		if use_save and not _resetting:
			save_game()


# --- Economía -----------------------------------------------------------------

func global_multiplier() -> float:
	return (1.0 + GOLDEN_BONUS_PER_COIN * golden_coins) \
			* (1.0 + REPUTATION_BONUS * prestige_points) \
			* (1.0 + ACHIEVEMENT_BONUS * achievements.size()) \
			* modifier_factor(GameData.TARGET_ALL)


func synergy_factor(index: int) -> float:
	if index + 1 >= buttons.size():
		return 1.0
	return 1.0 + buttons[index].synergy_from_next * buttons[index + 1].count


func building_income(index: int) -> float:
	return buttons[index].income(global_multiplier() * synergy_factor(index) * modifier_factor(index))


func income_per_second() -> float:
	var total := 0.0
	for i in buttons.size():
		total += building_income(i)
	return total


func click_value() -> float:
	var base := pow(2.0, ink_level) * global_multiplier() \
			+ income_per_second() * BOOST_PER_LEVEL * boost_level
	return base * modifier_factor(GameData.TARGET_CLICK) * combo


func ink_cost() -> float:
	return INK_BASE_COST * pow(INK_GROWTH, ink_level)


func boost_cost() -> float:
	return BOOST_BASE_COST * pow(BOOST_GROWTH, boost_level)


func earn(amount: float) -> void:
	dollars += amount
	total_earned += amount
	lifetime_earned += amount


func count_of(index: int) -> int:
	return buttons[index].count


func min_building_count() -> int:
	var result := 1 << 30
	for b in buttons:
		result = mini(result, b.count)
	return result


func max_building_count() -> int:
	var result := 0
	for b in buttons:
		result = maxi(result, b.count)
	return result


func building_upgrades_bought() -> int:
	var total := 0
	for b in buttons:
		total += b.upgrades_bought
	return total


func _pay_buildings(delta: float) -> void:
	for i in buttons.size():
		var button := buttons[i]
		if button.count == 0:
			button.timer = 0.0
			continue
		button.timer += delta
		if button.timer < button.period:
			continue
		button.timer -= button.period
		var amount := building_income(i) * button.period
		if amount <= 0.0:
			continue
		earn(amount)
		if fx_enabled:
			rows[i].pulse()
			_popup(rows[i].position + rows[i].popup_point(), "+" + Fmt.small(amount), GREEN, 15)


# --- Modificadores temporales y pagos diferidos --------------------------------

func add_modifier(target: int, factor: float, duration: float, label: String) -> void:
	# Un modificador con la misma etiqueta se renueva en vez de acumularse.
	for m in modifiers:
		if m.label == label:
			m.time_left = duration
			m.duration = duration
			m.factor = factor
			return
	modifiers.append({"target": target, "factor": factor, "time_left": duration,
			"duration": duration, "label": label})


func modifier_factor(target: int) -> float:
	var factor := 1.0
	for m in modifiers:
		if m.target == target:
			factor *= m.factor
	return factor


func has_modifier(label: String) -> bool:
	return modifiers.any(func(m: Dictionary) -> bool: return m.label == label)


func schedule_payout(delay: float, amount: float, message: String) -> void:
	payouts.append({"time_left": delay, "amount": amount, "message": message})


func _tick_modifiers(delta: float) -> void:
	for m in modifiers:
		m.time_left -= delta
	modifiers = modifiers.filter(func(m: Dictionary) -> bool: return m.time_left > 0.0)


func _tick_payouts(delta: float) -> void:
	for p in payouts:
		p.time_left -= delta
		if p.time_left <= 0.0:
			earn(p.amount)
			hud.toast(p.message)
	payouts = payouts.filter(func(p: Dictionary) -> bool: return p.time_left > 0.0)


# --- Clic y combo --------------------------------------------------------------

func _tick_combo(delta: float) -> void:
	_since_last_click += delta
	if _since_last_click > COMBO_DECAY_DELAY:
		combo = maxf(1.0, combo - COMBO_DECAY_RATE * delta)


func _on_printer_pressed() -> void:
	var player: AudioStreamPlayer = $Printer/CashSound
	player.pitch_scale = randf_range(0.92, 1.08)
	player.play()
	if _since_last_click < COMBO_WINDOW:
		combo = minf(GameData.COMBO_MAX, combo + COMBO_STEP)
		best_combo = maxf(best_combo, combo)
	_since_last_click = 0.0
	clicks_total += 1
	var value := click_value()
	earn(value)
	if fx_enabled:
		_popup(get_global_mouse_position(), "+" + Fmt.small(value), GOLD, 20)
		Fx.burst(effects, printer.position + Vector2(0, 60), Fx.BILLS, 6, 200.0, 45.0)


# --- Compras -----------------------------------------------------------------------

func _on_shop_button_pressed(button: ShopButton) -> void:
	if not button.is_unlocked(total_earned):
		return
	var price := button.cost()
	if dollars < price:
		_popup(button.position + Vector2(0, 50), "Need %s $" % Fmt.money(price), RED, 14, true)
		return
	var level_before := button.milestone_level()
	dollars -= price
	button.count += 1
	if button.milestone_level() > level_before:
		var row := rows[buttons.find(button)]
		_popup(row.position + Vector2(295, 40), "%s x2!" % button.building_name, GOLD, 24, true)
		_confetti(row.position + Vector2(295, 40))
	_refresh()


func can_buy_building_upgrade(index: int) -> bool:
	var b := buttons[index]
	return b.next_upgrade_ready() and dollars >= b.next_upgrade_cost()


func buy_building_upgrade(index: int) -> void:
	if not can_buy_building_upgrade(index):
		return
	var b := buttons[index]
	dollars -= b.next_upgrade_cost()
	hud.toast("%s bought: %s x2!" % [b.next_upgrade_name(), b.building_name])
	b.upgrades_bought += 1
	_confetti(rows[index].position + Vector2(200, 30))
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


# --- Prestigio ---------------------------------------------------------------------

static func reputation_for(earned: float) -> int:
	return floori(sqrt(maxf(earned, 0.0) / PRESTIGE_DIVISOR))


func pending_reputation() -> int:
	return maxi(0, reputation_for(lifetime_earned) - prestige_points)


## Fracción (0..1) del camino hacia el siguiente punto de Reputación.
func reputation_progress() -> float:
	var level := sqrt(maxf(lifetime_earned, 0.0) / PRESTIGE_DIVISOR)
	return level - floorf(level)


## Dinero total que hace falta (de por vida) para el siguiente punto de Reputación.
func next_reputation_at() -> float:
	var next := reputation_for(lifetime_earned) + 1
	return next * next * PRESTIGE_DIVISOR


func prestige() -> void:
	var gain := pending_reputation()
	if gain < 1:
		return
	prestige_points += gain
	chips += gain
	cities += 1
	_reset_city()
	hud.toast("New city founded! +%d reputation." % gain)
	for x in [250.0, 480.0, 710.0]:
		_confetti(Vector2(x, 320))
	if use_save:
		save_game()


func has_reputation_upgrade(id: String) -> bool:
	return reputation_upgrades.has(id)


func buy_reputation_upgrade(id: String) -> void:
	for u in reputation_list:
		if u.id == id and not has_reputation_upgrade(id) and chips >= u.cost:
			chips -= u.cost
			reputation_upgrades[id] = true
			hud.toast("%s unlocked!" % u.name)
			if id == "head_start" and buttons[0].count < 5:
				buttons[0].count = 5
			return


func _reset_city() -> void:
	dollars = 1000.0 if has_reputation_upgrade("seed_money") else 0.0
	total_earned = 0.0
	ink_level = 0
	boost_level = 0
	combo = 1.0
	modifiers.clear()
	payouts.clear()
	for row in rows:
		row.reset()
	for b in buttons:
		b.count = 0
		b.upgrades_bought = 0
		b.timer = 0.0
	if has_reputation_upgrade("head_start"):
		buttons[0].count = 5
	for coin in golden_root.get_children():
		coin.queue_free()
	_shown_dollars = dollars
	_refresh()


func hard_reset() -> void:
	_resetting = true
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	get_tree().reload_current_scene()


# --- Logros ------------------------------------------------------------------------

func check_achievements() -> void:
	for a in achievement_list:
		if not achievements.has(a.id) and a.check.call(self):
			achievements[a.id] = true
			hud.toast("Achievement: %s  (+1%% income)" % a.name)
			_play($CoinSound, 1.4)


# --- Eventos -----------------------------------------------------------------------

func trigger_random_event() -> bool:
	var options := event_list.filter(func(e: Dictionary) -> bool: return e.requires.call(self))
	if options.is_empty():
		return false
	var event: Dictionary = options.pick_random()
	hud.show_event(event.title, event.text, event.a, event.b, _resolve_event.bind(event))
	return true


func _resolve_event(choice_a: bool, event: Dictionary) -> void:
	var effect: Callable = event.on_a if choice_a else event.on_b
	events_resolved += 1
	hud.toast(effect.call(self))
	_refresh()


# --- Monedas especiales ----------------------------------------------------------

func _next_golden_delay() -> float:
	var factor := 0.7 if has_reputation_upgrade("lucky_charm") else 1.0
	return randf_range(GOLDEN_DELAY.x, GOLDEN_DELAY.y) * factor


func _effect_duration(seconds: float) -> float:
	return seconds * (1.5 if has_reputation_upgrade("golden_age") else 1.0)


func spawn_golden_coin(kind := "gold", chain := 0) -> GoldenCoin:
	var area: Rect2 = GOLDEN_SPAWN_AREAS.pick_random()
	var coin: GoldenCoin = GoldenCoinScene.instantiate()
	coin.kind = kind
	coin.chain = chain
	coin.position = area.position + Vector2(randf() * area.size.x, randf() * area.size.y)
	coin.collected.connect(_on_golden_collected)
	golden_root.add_child(coin)
	_play($CoinSound, 0.8 if kind == "red" else 1.0 + 0.08 * chain)
	return coin


func _on_golden_collected(coin: GoldenCoin) -> void:
	_play($NewCoinSound)
	if fx_enabled:
		Fx.fly(effects, CoinScene, coin.position, DOLLARS_LABEL_POS)
	if coin.kind == "red":
		_collect_red(coin)
	else:
		golden_coins += 1
		_add_tray_coin(golden_coins - 1)
		if coin.chain > 0:
			_continue_chain(coin.chain, coin.position)
		else:
			_golden_reward(coin.position)
	_refresh()


func _golden_reward(at: Vector2) -> void:
	var roll := randf()
	if roll < 0.4:
		var amount := maxf(LUCKY_MIN, income_per_second() * LUCKY_SECONDS)
		earn(amount)
		_popup(at, "Lucky! +%s $" % Fmt.money(amount), GOLD, 22, true)
	elif roll < 0.75:
		add_modifier(GameData.TARGET_ALL, FRENZY_MULTIPLIER, _effect_duration(FRENZY_TIME), "Frenzy x7")
		_popup(at, "FRENZY x7!", GOLD, 24, true)
	elif roll < 0.9:
		add_modifier(GameData.TARGET_CLICK, CLICK_FRENZY_MULTIPLIER, _effect_duration(CLICK_FRENZY_TIME), "Click x777")
		_popup(at, "CLICK FRENZY x777!", GOLD, 24, true)
	else:
		_continue_chain(1, at)


func _continue_chain(link: int, at: Vector2) -> void:
	best_chain = maxi(best_chain, link)
	var amount := maxf(10.0 * link, income_per_second() * 15.0 * link)
	earn(amount)
	_popup(at, "Chain x%d! +%s $" % [link, Fmt.money(amount)], GOLD, 22, true)
	if link < CHAIN_MAX and randf() < CHAIN_CONTINUE_CHANCE:
		spawn_golden_coin("gold", link + 1)


func _collect_red(coin: GoldenCoin) -> void:
	red_clicked += 1
	if randf() < 0.5:
		var amount := maxf(100.0, income_per_second() * RED_JACKPOT_SECONDS)
		earn(amount)
		_popup(coin.position, "JACKPOT! +%s $" % Fmt.money(amount), GOLD, 26, true)
	else:
		var loss := dollars * RED_LOSS
		dollars -= loss
		_popup(coin.position, "Cursed! -%s $" % Fmt.money(loss), RED, 24, true)


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
	for i in buttons.size():
		var button := buttons[i]
		button.refresh(dollars, total_earned)
		rows[i].show_building(button, button.is_unlocked(total_earned), building_income(i))

	hud.set_dollars(Fmt.money(_shown_dollars))
	hud.set_rate(income_per_second(), modifier_factor(GameData.TARGET_ALL) > 1.0)
	hud.set_effects(modifiers)
	hud.set_combo(combo)
	hud.set_coins(golden_coins, GOLDEN_BONUS_PER_COIN * golden_coins)
	hud.set_menu_badge(_menu_has_news())
	_refresh_upgrade("ink", "Better Ink", "Click x2", ink_level, ink_cost())
	_refresh_upgrade("boost", "Golden Touch", "Click +1% $/s", boost_level, boost_cost())


func _menu_has_news() -> bool:
	for i in buttons.size():
		if can_buy_building_upgrade(i):
			return true
	# Avisa de prestigio cuando ganarías al menos la mitad de lo que ya tienes.
	if pending_reputation() >= maxi(1, floori(prestige_points / 2.0)):
		return true
	for u in reputation_list:
		if not has_reputation_upgrade(u.id) and chips >= u.cost:
			return true
	return false


func _refresh_upgrade(which: String, upgrade_name: String, effect: String, level: int, price: float) -> void:
	if level == 0 and total_earned < price * UPGRADE_REVEAL_FRACTION:
		hud.set_upgrade(which, "???\n%s $" % Fmt.money(price), false)
	else:
		hud.set_upgrade(which, "%s (Lv %d)\n%s · %s $" % [upgrade_name, level, effect, Fmt.money(price)],
				dollars >= price)


func _popup(at: Vector2, text: String, color: Color, size: int, always := false) -> void:
	if fx_enabled or always:
		FloatingText.spawn(effects, at, text, color, size)


func _confetti(at: Vector2) -> void:
	if fx_enabled:
		Fx.confetti(effects, at)


func _play(player: AudioStreamPlayer, pitch := 1.0) -> void:
	player.pitch_scale = pitch
	player.play()


## 0 = pleno día, 1 = noche cerrada.
func night_amount() -> float:
	return smoothstep(0.25, 0.75, 0.5 - 0.5 * cos(TAU * day_time / DAY_LENGTH))


func set_volume(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.001)


func get_volume(bus: String) -> float:
	var index := AudioServer.get_bus_index(bus)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func set_fx(enabled: bool) -> void:
	fx_enabled = enabled


func set_scientific(enabled: bool) -> void:
	Fmt.scientific = enabled


# --- Guardado ---------------------------------------------------------------------

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "version", SAVE_VERSION)
	cfg.set_value("game", "saved_at", Time.get_unix_time_from_system())
	cfg.set_value("city", "dollars", dollars)
	cfg.set_value("city", "total_earned", total_earned)
	cfg.set_value("city", "ink_level", ink_level)
	cfg.set_value("city", "boost_level", boost_level)
	var permanent := modifiers.filter(func(m: Dictionary) -> bool: return m.time_left == INF)
	cfg.set_value("city", "modifiers", permanent.map(
			func(m: Dictionary) -> Array: return [m.target, m.factor, m.label]))
	for b in buttons:
		cfg.set_value("buildings", b.name, b.count)
		cfg.set_value("building_upgrades", b.name, b.upgrades_bought)
	for key in ["lifetime_earned", "prestige_points", "chips", "cities", "golden_coins",
			"clicks_total", "best_ips", "time_played", "red_clicked", "best_chain",
			"best_combo", "events_resolved"]:
		cfg.set_value("progress", key, get(key))
	cfg.set_value("progress", "reputation_upgrades", reputation_upgrades.keys())
	cfg.set_value("progress", "achievements", achievements.keys())
	cfg.set_value("settings", "fx_enabled", fx_enabled)
	cfg.set_value("settings", "scientific", Fmt.scientific)
	for bus in VOLUME_BUSES:
		cfg.set_value("volume", bus, get_volume(bus))
	cfg.save(save_path)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	var version: int = cfg.get_value("game", "version", 1)
	var city := "city" if version >= 2 else "game"  # v1 guardaba todo en [game]
	dollars = cfg.get_value(city, "dollars", 0.0)
	total_earned = cfg.get_value(city, "total_earned", 0.0)
	ink_level = cfg.get_value(city, "ink_level", 0)
	boost_level = cfg.get_value(city, "boost_level", 0)
	for m: Array in cfg.get_value("city", "modifiers", []):
		add_modifier(m[0], m[1], INF, m[2])
	for b in buttons:
		b.count = cfg.get_value("buildings", b.name, 0)
		b.upgrades_bought = cfg.get_value("building_upgrades", b.name, 0)
	for key in ["lifetime_earned", "prestige_points", "chips", "cities", "golden_coins",
			"clicks_total", "best_ips", "time_played", "red_clicked", "best_chain",
			"best_combo", "events_resolved"]:
		if cfg.has_section_key("progress", key):
			set(key, cfg.get_value("progress", key))
	if version < 2:
		golden_coins = cfg.get_value("game", "golden_coins", 0)
		lifetime_earned = total_earned
	for id in cfg.get_value("progress", "reputation_upgrades", []):
		reputation_upgrades[id] = true
	for id in cfg.get_value("progress", "achievements", []):
		achievements[id] = true
	fx_enabled = cfg.get_value("settings", "fx_enabled", true)
	Fmt.scientific = cfg.get_value("settings", "scientific", false)
	for bus in VOLUME_BUSES:
		if cfg.has_section_key("volume", bus):
			set_volume(bus, cfg.get_value("volume", bus))

	var saved_at: float = cfg.get_value("game", "saved_at", Time.get_unix_time_from_system())
	var away := clampf(Time.get_unix_time_from_system() - saved_at, 0.0, OFFLINE_MAX_SECONDS)
	if away < OFFLINE_MIN_SECONDS:
		return
	var efficiency := OFFLINE_EFFICIENCY_UPGRADED if has_reputation_upgrade("night_owl") else OFFLINE_EFFICIENCY
	var offline := income_per_second() * away * efficiency
	if offline >= 1.0:
		earn(offline)
		hud.show_welcome("While you were away (%s) your city earned %s $." % [_duration(away), Fmt.money(offline)])


static func _duration(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [floori(minutes / 60.0), minutes % 60]
