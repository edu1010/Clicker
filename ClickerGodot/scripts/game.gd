extends Node2D
## Lógica principal del clicker.
##
## Economía: clic en la impresora + edificios sin límite (coste x1.15), cada uno con
## su ritmo de pago, hitos x2, 4 mejoras x2 y sinergia con el siguiente edificio.
## Multiplicadores globales: monedas doradas (+2 % cada una, máximo +50 %), Reputación (+1 %),
## logros (+1 %) y modificadores temporales (frenesí, eventos...).
## Expansión: fundar otra ciudad cuesta dinero de la ciudad seleccionada (coste global creciente).
## Prestigio: "renovar" reinicia solo la ciudad seleccionada a cambio de Reputación. El objetivo
## se calcula con lo ganado por todo el imperio y cada ciudad cobra la parte proporcional a lo
## que ha ganado desde su última renovación.
## Valores elegidos por simulación: docs/INVESTIGACION_DISENO_INCREMENTALES.md, secciones 21–23.

const GOLDEN_BONUS_PER_COIN := 0.02
## Tope del bonus permanente de las monedas doradas (+50 %): sin él, el tiempo mirando
## multiplicaba los ingresos sin límite (sección 21.1).
const GOLDEN_BONUS_CAP := 0.5
const REPUTATION_BONUS := 0.01
const ACHIEVEMENT_BONUS := 0.01
## Reputación objetivo = floor(∛(ganado por el imperio / PRESTIGE_DIVISOR)).
const PRESTIGE_DIVISOR := 1e7
const PRESTIGE_ROOT := 3.0

## Fundar la ciudad n+1 cuesta FOUND_BASE_COST × FOUND_GROWTH^(n-1) (sección 23.2).
const FOUND_BASE_COST := 250000.0
const FOUND_GROWTH := 8.0

## Modos de compra de edificios: cantidades fijas, hasta el siguiente hito o el máximo pagable.
const BUY_NEXT_MILESTONE := -1
const BUY_MAX := 0
const BUY_MODES: Array[int] = [1, 10, 25, BUY_NEXT_MILESTONE, BUY_MAX]

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

const SAVE_VERSION := 5
const AUTOSAVE_TIME := 10.0
const OFFLINE_EFFICIENCY := 0.5
const OFFLINE_EFFICIENCY_UPGRADED := 0.75
const OFFLINE_MAX_SECONDS := 8.0 * 3600.0
const OFFLINE_MIN_SECONDS := 60.0

## Duración de un ciclo día/noche en segundos.
const DAY_LENGTH := 240.0
const DOLLARS_LABEL_POS := Vector2(175, 86)
## Píxeles que avanza la lista de calles por cada paso de la rueda del ratón.
const ROW_SCROLL_STEP := 60
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
## Ganado por esta ciudad desde su fundación (no se reinicia al renovarla).
var city_lifetime := 0.0
## Valor de city_lifetime en la última renovación: lo ganado después aún no se ha cobrado.
var city_claimed_life := 0.0

# Permanente.
var lifetime_earned := 0.0
var prestige_points := 0
var chips := 0
## Veces que se ha renovado una ciudad (prestigio). No confundir con city_states.size().
var renewals := 0
var buy_mode := 0
var reputation_upgrades := {}
## Árbol del imperio: id de nodo -> rangos comprados. Compartido por todas las ciudades.
var empire_tree := {}
var tree_list: Array[Dictionary] = GameData.empire_tree()
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

# Cada ciudad conserva su economía; el legado sigue siendo compartido.
var city_states: Array[Dictionary] = []
var active_city := 0
var desktop: DesktopMode

var _shown_dollars := 0.0
var _golden_timer := 0.0
var _event_timer := 0.0
var _autosave_timer := 0.0
var _achievement_timer := 0.0
var _since_last_click := 99.0
var _resetting := false
var _last_city_earnings: Array[float] = []

@onready var hud: Hud = $HUD
@onready var menu: GameMenu = $HUD/Menu
@onready var printer: Clickable = $Printer
@onready var effects: Node2D = $Effects
@onready var tray: Node2D = $CoinTray
@onready var golden_root: Node2D = $GoldenCoins
@onready var rows_scroll: ScrollContainer = $RowsScroll
@onready var level_bar: Control = $LevelBar
@onready var level_all_button: Button = $LevelBar/LevelAllButton
@onready var levels_label: Label = $LevelBar/LevelsLabel


func _ready() -> void:
	position.y = 48
	hud.offset.y = 48
	hud.apply_theme(UiTheme.create())
	# La moneda dorada (z alto) debe recibir el clic antes que lo que tenga debajo.
	get_viewport().physics_object_picking_sort = true
	get_viewport().physics_object_picking_first_only = true

	for button: ShopButton in $Buttons.get_children():
		buttons.append(button)
		button.pressed.connect(_on_shop_button_pressed.bind(button))
	rows_scroll.theme = UiTheme.create()
	level_bar.theme = rows_scroll.theme
	for row: BuildingRow in $RowsScroll/Rows.get_children():
		row.level_pressed.connect(level_up.bind(rows.size()))
		rows.append(row)
	level_all_button.pressed.connect(level_up_all)
	printer.pressed.connect(_on_printer_pressed)
	hud.ink_pressed.connect(_buy_ink)
	hud.boost_pressed.connect(_buy_boost)
	hud.menu_pressed.connect(menu.open)
	menu.game = self
	desktop = DesktopMode.new()
	desktop.game = self
	add_child(desktop)

	_golden_timer = randf_range(GOLDEN_FIRST_DELAY.x, GOLDEN_FIRST_DELAY.y)
	_event_timer = randf_range(EVENT_FIRST_DELAY.x, EVENT_FIRST_DELAY.y)
	_apply_tree()  # el descuento de ShopButton es estático: no debe sobrevivir a un reinicio
	if use_save:
		load_game()
	if city_states.is_empty():
		city_states.append(_capture_city())
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
	_advance_other_cities(delta)
	_tick_payouts(delta)
	_tick_combo(delta)

	_golden_timer -= delta
	if _golden_timer <= 0.0:
		_golden_timer = _next_golden_delay()
		spawn_golden_coin("red" if randf() < RED_CHANCE else "gold")

	_event_timer -= delta
	if _event_timer <= 0.0 and not hud.is_modal_open():
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

func golden_bonus() -> float:
	return minf(GOLDEN_BONUS_PER_COIN * golden_coins, golden_bonus_cap())


## Tope del bonus de monedas doradas (Golden Vault lo sube).
func golden_bonus_cap() -> float:
	return GOLDEN_BONUS_CAP + tree_effect("golden_vault")


## Ingresos extra por punto de Reputación (Empire HQ lo sube).
func reputation_bonus() -> float:
	return REPUTATION_BONUS + tree_effect("empire_hq")


## Multiplicadores permanentes compartidos por todas las ciudades. `live`: el juego está abierto
## (Open All Night no cuenta para la producción offline).
func permanent_multiplier(live := true) -> float:
	var factor := (1.0 + golden_bonus()) \
			* (1.0 + reputation_bonus() * prestige_points) \
			* (1.0 + ACHIEVEMENT_BONUS * achievements.size()) \
			* (1.0 + tree_effect("trade_network")) \
			* (1.0 + tree_effect("global_brand"))
	if live:
		factor *= 1.0 + tree_effect("open_all_night")
	return factor


func global_multiplier() -> float:
	return permanent_multiplier() * modifier_factor(GameData.TARGET_ALL)


func synergy_factor(index: int) -> float:
	if index + 1 >= buttons.size():
		return 1.0
	return 1.0 + buttons[index].synergy_from_next * buttons[index + 1].count * (1.0 + tree_effect("supply_chains"))


func building_income(index: int) -> float:
	return buttons[index].income(global_multiplier() * synergy_factor(index) * modifier_factor(index))


func income_per_second() -> float:
	var total := 0.0
	for i in buttons.size():
		total += building_income(i)
	return total


## Click Frenzy (TARGET_CLICK) multiplica solo el clic base, no la parte de Golden Touch
## que depende de los $/s: así no se multiplica la producción entera por 777 (sección 22).
func click_value() -> float:
	var base := pow(2.0, ink_level + tree_rank("printing_press")) * global_multiplier() * modifier_factor(GameData.TARGET_CLICK)
	return (base + income_per_second() * BOOST_PER_LEVEL * boost_level) * combo


func ink_cost() -> float:
	return INK_BASE_COST * pow(INK_GROWTH, ink_level)


func boost_cost() -> float:
	return BOOST_BASE_COST * pow(BOOST_GROWTH, boost_level)


func earn(amount: float) -> void:
	dollars += amount
	total_earned += amount
	city_lifetime += amount
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
			if _row_visible(i):
				_popup(_row_point(i, rows[i].popup_point()), "+" + Fmt.small(amount), GREEN, 15)


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
		combo = minf(combo_max(), combo + COMBO_STEP)
		best_combo = maxf(best_combo, combo)
	_since_last_click = 0.0
	clicks_total += 1
	var value := click_value()
	earn(value)
	# Lucky Press: cada clic puede soltar una moneda dorada.
	if randf() < tree_effect("lucky_press"):
		spawn_golden_coin("gold")
	if fx_enabled:
		_popup(to_local(get_global_mouse_position()), "+" + Fmt.small(value), GOLD, 20)
		Fx.burst(effects, printer.position + Vector2(0, 60), Fx.BILLS, 6, 200.0, 45.0)


## Combo máximo del clic (Ergonomics lo sube).
func combo_max() -> float:
	return GameData.COMBO_MAX + tree_effect("ergonomics")


# --- Compras -----------------------------------------------------------------------

func buy_mode_label() -> String:
	match BUY_MODES[buy_mode]:
		BUY_NEXT_MILESTONE:
			return "Buy to x2"
		BUY_MAX:
			return "Buy max"
		var fixed:
			return "Buy x%d" % fixed


func cycle_buy_mode() -> void:
	buy_mode = (buy_mode + 1) % BUY_MODES.size()
	_refresh()


## Unidades que compraría ahora un clic en ese botón según el modo elegido.
func purchase_quantity(button: ShopButton) -> int:
	match BUY_MODES[buy_mode]:
		BUY_NEXT_MILESTONE:
			return button.next_milestone() - button.count
		BUY_MAX:
			return maxi(1, button.affordable_count(dollars))
		var fixed:
			return fixed


## $/s totales que se ganarían comprando `quantity` unidades: recalcula toda la economía,
## así incluye hitos y la sinergia que el edificio da al anterior.
func purchase_gain(index: int, quantity: int, income_before := -1.0) -> float:
	var before := income_before if income_before >= 0.0 else income_per_second()
	buttons[index].count += quantity
	var after := income_per_second()
	buttons[index].count -= quantity
	return after - before


func _on_shop_button_pressed(button: ShopButton) -> void:
	if not button.is_unlocked(total_earned):
		return
	var quantity := purchase_quantity(button)
	var price := button.cost_of(quantity)
	if dollars < price:
		_popup(button.position + Vector2(0, 50), "Need %s $ more" % Fmt.money(price - dollars), RED, 14, true)
		return
	var level_before := button.milestone_level()
	dollars = maxf(0.0, dollars - price)
	button.count += quantity
	if button.milestone_level() > level_before:
		var index := buttons.find(button)
		var factor := 1 << (button.milestone_level() - level_before)
		_scroll_to_row(index)
		_popup(_row_point(index, Vector2(295, 40)), "%s x%d!" % [button.building_name, factor], GOLD, 24, true)
		_confetti(_row_point(index, Vector2(295, 40)))
	_refresh()


# --- Niveles de edificio -----------------------------------------------------------

func can_level_up(index: int) -> bool:
	var b := buttons[index]
	return b.level_ready() and dollars >= b.next_level_cost()


func level_up(index: int) -> bool:
	if not can_level_up(index):
		return false
	var b := buttons[index]
	dollars -= b.next_level_cost()
	b.level += 1
	hud.toast("%s reached level %d: income x2!" % [b.building_name, b.level])
	_confetti(_row_point(index, Vector2(200, 30)))
	_refresh()
	return true


## Edificios que ahora mismo cumplen los requisitos de su siguiente nivel.
func levels_ready() -> Array[int]:
	var ready: Array[int] = []
	for i in buttons.size():
		if buttons[i].is_unlocked(total_earned) and buttons[i].level_ready():
			ready.append(i)
	return ready


## Coste de subir un nivel a todos los edificios que pueden subir.
func level_all_cost() -> float:
	var total := 0.0
	for i in levels_ready():
		total += buttons[i].next_level_cost()
	return total


## Sube un nivel a todos los que pueden, solo si alcanza para todos (sin compras parciales).
func level_up_all() -> bool:
	var ready := levels_ready()
	var price := level_all_cost()
	if ready.is_empty() or dollars < price:
		return false
	dollars -= price
	for i in ready:
		buttons[i].level += 1
	hud.toast("%d buildings levelled up: income x2 each!" % ready.size())
	for x in [250.0, 480.0, 710.0]:
		_confetti(Vector2(x, 400))
	_refresh()
	return true


func total_levels() -> int:
	var total := 0
	for b in buttons:
		total += b.level
	return total


## Pasa un punto local de la calle `index` a coordenadas de los efectos (tiene en cuenta el scroll).
func _row_point(index: int, local: Vector2) -> Vector2:
	return effects.get_global_transform().affine_inverse() * (rows[index].get_global_transform() * local)


func _row_visible(index: int) -> bool:
	return rows_scroll.get_global_rect().intersects(rows[index].get_global_rect())


func _scroll_to_row(index: int) -> void:
	if not _row_visible(index):
		rows_scroll.ensure_control_visible(rows[index])


func _unhandled_input(event: InputEvent) -> void:
	# La lista ignora el ratón para no tapar las monedas doradas; la rueda se gestiona aquí.
	if event is InputEventMouseButton and event.pressed \
			and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] \
			and rows_scroll.get_global_rect().has_point(get_global_mouse_position()):
		rows_scroll.scroll_vertical += ROW_SCROLL_STEP * (-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		get_viewport().set_input_as_handled()


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

static func reputation_level(earned: float) -> float:
	return pow(maxf(earned, 0.0) / PRESTIGE_DIVISOR, 1.0 / PRESTIGE_ROOT)


static func reputation_for(earned: float) -> int:
	return floori(reputation_level(earned) + 1e-9)


## Lo ganado por todas las ciudades desde su fundación (no baja al renovar).
func empire_lifetime() -> float:
	var total := city_lifetime
	for i in city_states.size():
		if i != active_city:
			total += float(city_states[i].get("lifetime", 0.0))
	return total


## Lo ganado por todas las ciudades desde su última renovación.
func empire_unclaimed() -> float:
	var total := city_unclaimed()
	for i in city_states.size():
		if i != active_city:
			var state := city_states[i]
			var life := float(state.get("lifetime", 0.0))
			total += maxf(0.0, life - float(state.get("claimed_life", life)))
	return total


func city_unclaimed() -> float:
	return maxf(0.0, city_lifetime - city_claimed_life)


## Reputación del imperio aún sin cobrar.
func empire_pending_reputation() -> int:
	return maxi(0, reputation_for(empire_lifetime()) - prestige_points)


## Reputación que daría renovar la ciudad seleccionada: su parte del pendiente del imperio,
## proporcional a lo que ha ganado desde su última renovación. Una ciudad vacía no cobra nada
## y fundar ciudades no crea raíces nuevas.
func pending_reputation() -> int:
	var unclaimed := empire_unclaimed()
	if unclaimed <= 0.0:
		return 0
	return floori(empire_pending_reputation() * city_unclaimed() / unclaimed + 1e-9)


## Parte (0..1) del pendiente que corresponde a la ciudad seleccionada.
func city_share() -> float:
	var unclaimed := empire_unclaimed()
	return city_unclaimed() / unclaimed if unclaimed > 0.0 else 0.0


## Fracción (0..1) del camino hacia el siguiente punto de Reputación del imperio.
func reputation_progress() -> float:
	var level := reputation_level(empire_lifetime())
	return level - floorf(level)


## Ganancias del imperio necesarias para el siguiente punto de Reputación.
func next_reputation_at() -> float:
	var next := maxi(reputation_for(empire_lifetime()), prestige_points) + 1
	return pow(next, PRESTIGE_ROOT) * PRESTIGE_DIVISOR


## Aumento real de producción que darían `gain` puntos (+1 % directo cada uno).
func reputation_speedup(gain: int) -> float:
	return (1.0 + reputation_bonus() * (prestige_points + gain)) / (1.0 + reputation_bonus() * prestige_points) - 1.0


func prestige() -> void:
	var gain := pending_reputation()
	if gain < 1:
		return
	prestige_points += gain
	chips += gain
	city_claimed_life = city_lifetime
	renewals += 1
	_reset_city(tree_rank("heritage"))
	hud.toast("City %d renewed! +%d reputation." % [active_city + 1, gain])
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


# --- Árbol del imperio -------------------------------------------------------------
# Se paga con el dinero de todas las ciudades: cada una aporta en proporción a lo que tiene,
# así ninguna se queda a cero y el reparto no depende de la ciudad seleccionada.

func tree_node(id: String) -> Dictionary:
	for node in tree_list:
		if node.id == id:
			return node
	return {}


func tree_rank(id: String) -> int:
	return int(empire_tree.get(id, 0))


## Efecto acumulado de un nodo: efecto por rango × rangos comprados.
func tree_effect(id: String) -> float:
	var rank := tree_rank(id)
	if rank == 0:
		return 0.0
	return float(tree_node(id).per) * rank


func tree_cost(id: String) -> float:
	return GameData.tree_cost(tree_node(id), tree_rank(id))


func tree_maxed(id: String) -> bool:
	return tree_rank(id) >= int(tree_node(id).max)


## El nodo previo tiene al menos un rango.
func tree_unlocked(id: String) -> bool:
	var requires: String = tree_node(id).requires
	return requires == "" or tree_rank(requires) >= 1


func can_buy_tree(id: String) -> bool:
	return tree_unlocked(id) and not tree_maxed(id) and empire_cash() >= tree_cost(id)


## Dinero de todas las ciudades juntas.
func empire_cash() -> float:
	var total := dollars
	for i in city_states.size():
		if i != active_city:
			total += float(city_states[i].get("dollars", 0.0))
	return total


func buy_tree(id: String) -> bool:
	if not can_buy_tree(id):
		return false
	var cash := empire_cash()
	var keep := 1.0 - tree_cost(id) / cash
	dollars = maxf(0.0, dollars * keep)
	for i in city_states.size():
		if i != active_city:
			city_states[i].dollars = maxf(0.0, float(city_states[i].get("dollars", 0.0)) * keep)
	_shown_dollars = minf(_shown_dollars, dollars)
	empire_tree[id] = tree_rank(id) + 1
	_apply_tree()
	hud.toast("%s rank %d!  %s" % [tree_node(id).name, tree_rank(id), GameData.tree_effect_text(tree_node(id), tree_rank(id))])
	_confetti(Vector2(480, 320))
	_refresh()
	return true


func tree_ranks_bought() -> int:
	var total := 0
	for id in empire_tree:
		total += int(empire_tree[id])
	return total


func tree_ranks_total() -> int:
	var total := 0
	for node in tree_list:
		total += int(node.max)
	return total


## Aplica los efectos del árbol que viven fuera de game.gd.
func _apply_tree() -> void:
	ShopButton.level_discount = 1.0 - tree_effect("franchising")


func _tree_has_news() -> bool:
	for node in tree_list:
		if can_buy_tree(node.id):
			return true
	return false


## keep_levels: niveles que conserva cada edificio (Heritage al renovar; 0 al fundar).
func _reset_city(keep_levels := 0) -> void:
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
		b.level = mini(b.level, keep_levels)
		b.timer = 0.0
	if has_reputation_upgrade("head_start"):
		buttons[0].count = 5
	for coin in golden_root.get_children():
		coin.queue_free()
	_shown_dollars = dollars
	_refresh()


func hard_reset() -> void:
	_resetting = true
	desktop.set_enabled(false)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	get_tree().reload_current_scene()


# --- Varias ciudades ------------------------------------------------------------

func city_title() -> String:
	return "City %d / %d" % [active_city + 1, city_states.size()]


func can_change_city() -> bool:
	return not menu.visible and not hud.is_modal_open()


## Precio de la siguiente ciudad. Depende solo de cuántas existen en todo el imperio,
## así es igual desde cualquier ciudad y navegar no lo abarata.
func found_cost(existing := -1) -> float:
	var n := city_states.size() if existing < 0 else existing
	return roundf(FOUND_BASE_COST * pow(FOUND_GROWTH, maxi(n, 1) - 1) * (1.0 - tree_effect("real_estate")))


## Abre la ficha de fundación: coste, ciudad que paga, saldo resultante y qué se obtiene.
## Solo el botón de esa ficha cobra y funda.
func request_found_city() -> void:
	if not can_change_city():
		return
	var price := found_cost()
	var number := city_states.size() + 1
	var lines: PackedStringArray = []
	lines.append("Cost: %s $, paid by City %d." % [Fmt.money(price), active_city + 1])
	if dollars >= price:
		lines.append("Cash in City %d: %s $  →  %s $ after founding." % [active_city + 1, Fmt.money(dollars), Fmt.money(dollars - price)])
	else:
		lines.append("You need %s $ more in City %d." % [Fmt.money(price - dollars), active_city + 1])
	var start: PackedStringArray = []
	if has_reputation_upgrade("head_start"):
		start.append("5 bars")
	if has_reputation_upgrade("seed_money"):
		start.append("1K $")
	lines.append("City %d gets its own economy%s; its earnings add to your empire's reputation. Your other cities keep producing." % [
			number, " (starts with %s)" % " and ".join(start) if not start.is_empty() else ""])
	lines.append("The following city will cost %s $." % Fmt.money(found_cost(number)))
	hud.confirm("Found City %d?" % number, "\n".join(lines), "Found for %s $" % Fmt.money(price),
			dollars >= price, found_city)


## Cobra y funda en un solo paso: sin cobros parciales ni ciudades gratis.
func found_city() -> bool:
	if menu.visible or hud.is_event_open():
		return false
	var price := found_cost()
	if dollars < price:
		hud.toast("You need %s $ more to found a new city." % Fmt.money(price - dollars))
		return false
	dollars -= price
	city_states[active_city] = _capture_city()
	active_city = city_states.size()
	_reset_city()
	city_lifetime = 0.0
	city_claimed_life = 0.0
	_golden_timer = randf_range(GOLDEN_FIRST_DELAY.x, GOLDEN_FIRST_DELAY.y)
	_event_timer = randf_range(EVENT_FIRST_DELAY.x, EVENT_FIRST_DELAY.y)
	city_states.append(_capture_city())
	_clear_city_effects()
	hud.toast("City %d founded for %s $. Your other cities keep producing." % [active_city + 1, Fmt.money(price)])
	for x in [250.0, 480.0, 710.0]:
		_confetti(Vector2(x, 320))
	if use_save:
		save_game()
	return true


func change_city(direction: int) -> void:
	if city_states.size() < 2 or not can_change_city():
		return
	city_states[active_city] = _capture_city()
	active_city = posmod(active_city + direction, city_states.size())
	_restore_city(city_states[active_city])
	_clear_city_effects()
	if use_save:
		save_game()


func _clear_city_effects() -> void:
	for root in [golden_root, effects]:
		for child in root.get_children():
			child.queue_free()
	for row in rows:
		row.reset()
	combo = 1.0
	_since_last_click = 99.0
	_shown_dollars = dollars
	_refresh()


func _capture_city() -> Dictionary:
	var buildings: Array = []
	for b in buttons:
		buildings.append({"count": b.count, "level": b.level, "timer": b.timer})
	return {"dollars": dollars, "total_earned": total_earned, "ink_level": ink_level,
		"lifetime": city_lifetime, "claimed_life": city_claimed_life, "boost_level": boost_level, "modifiers": modifiers.duplicate(true),
		"payouts": payouts.duplicate(true), "buildings": buildings,
		"golden_timer": _golden_timer, "event_timer": _event_timer, "day_time": day_time}


func _restore_city(state: Dictionary) -> void:
	dollars = state.get("dollars", 0.0)
	total_earned = state.get("total_earned", 0.0)
	city_lifetime = state.get("lifetime", total_earned)
	city_claimed_life = state.get("claimed_life", city_lifetime)
	ink_level = state.get("ink_level", 0)
	boost_level = state.get("boost_level", 0)
	modifiers.assign(state.get("modifiers", []))
	payouts.assign(state.get("payouts", []))
	_golden_timer = state.get("golden_timer", GOLDEN_FIRST_DELAY.x)
	_event_timer = state.get("event_timer", EVENT_FIRST_DELAY.x)
	day_time = state.get("day_time", 0.0)
	var buildings: Array = state.get("buildings", [])
	for i in buttons.size():
		var data: Dictionary = buildings[i] if i < buildings.size() else {}
		buttons[i].count = data.get("count", 0)
		buttons[i].level = data.get("level", data.get("upgrades", 0))  # "upgrades": las 4 mejoras antiguas
		buttons[i].timer = data.get("timer", 0.0)


func _city_income(state: Dictionary, seconds := 0.0, live := true) -> float:
	# Integra la caducidad de los bonus también cuando la ciudad no está en pantalla.
	var duration := maxf(seconds, 0.0)
	var cutoffs: Array[float] = [0.0, duration]
	for m: Dictionary in state.get("modifiers", []):
		if m.time_left > 0.0 and m.time_left < duration:
			cutoffs.append(float(m.time_left))
	cutoffs.sort()
	var total := 0.0
	var global_factor := permanent_multiplier(live)
	var synergy_boost := 1.0 + tree_effect("supply_chains")
	for segment in range(1, cutoffs.size()):
		var at := cutoffs[segment - 1]
		var rate := 0.0
		var buildings: Array = state.get("buildings", [])
		for i in mini(buildings.size(), buttons.size()):
			var b := buttons[i]
			var data: Dictionary = buildings[i]
			var synergy := 1.0
			if i + 1 < buildings.size():
				synergy += b.synergy_from_next * buildings[i + 1].count * synergy_boost
			var factor := 1.0
			for m: Dictionary in state.get("modifiers", []):
				if m.time_left > at and m.target in [GameData.TARGET_ALL, i]:
					factor *= m.factor
			rate += b.income_per_second * data.count * pow(2.0, b.milestone_level(data.count) + int(data.get("level", data.get("upgrades", 0)))) * synergy * factor
		total += rate * global_factor * (cutoffs[segment] - at)
	return total


func _advance_other_cities(seconds: float, efficiency := 1.0, live := true) -> float:
	var earned := 0.0
	_last_city_earnings.resize(city_states.size())
	_last_city_earnings.fill(0.0)
	for i in city_states.size():
		if i == active_city:
			continue
		var state := city_states[i]
		var amount := _city_income(state, seconds, live) * efficiency
		for payout: Dictionary in state.get("payouts", []):
			payout.time_left -= seconds
			if payout.time_left <= 0.0:
				amount += payout.amount
		state.payouts = state.get("payouts", []).filter(func(p: Dictionary) -> bool: return p.time_left > 0.0)
		for m: Dictionary in state.get("modifiers", []):
			m.time_left -= seconds
		state.modifiers = state.get("modifiers", []).filter(func(m: Dictionary) -> bool: return m.time_left > 0.0)
		state.dollars += amount
		state.total_earned += amount
		state.lifetime = float(state.get("lifetime", state.total_earned - amount)) + amount
		_last_city_earnings[i] = amount
		state.day_time = fmod(float(state.get("day_time", 0.0)) + seconds, DAY_LENGTH)
		earned += amount
	lifetime_earned += earned
	return earned


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
	return randf_range(GOLDEN_DELAY.x, GOLDEN_DELAY.y) * factor / (1.0 + tree_effect("lucky_streets"))


func _effect_duration(seconds: float) -> float:
	return seconds * (1.5 if has_reputation_upgrade("golden_age") else 1.0) * (1.0 + tree_effect("long_party"))


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
	# Midas Odds pasa probabilidad de Lucky (40 %) a Frenzy (35 %).
	if roll < 0.4 - tree_effect("midas_odds"):
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
	var income := income_per_second()
	for i in buttons.size():
		var button := buttons[i]
		var quantity := purchase_quantity(button)
		button.refresh(dollars, total_earned, quantity, purchase_gain(i, quantity, income))
		rows[i].show_building(button, button.is_unlocked(total_earned), building_income(i), dollars)

	hud.set_dollars(Fmt.money(_shown_dollars))
	hud.set_rate(income, modifier_factor(GameData.TARGET_ALL) > 1.0)
	hud.set_effects(modifiers)
	hud.set_combo(combo)
	hud.set_coins(golden_coins, golden_bonus(), golden_bonus() >= golden_bonus_cap())
	hud.set_menu_badge(_menu_has_news())
	_refresh_upgrade("ink", "Better Ink", "Click x2", ink_level, ink_cost())
	_refresh_upgrade("boost", "Golden Touch", "Click +1% $/s", boost_level, boost_cost())
	_refresh_levels()


func _menu_has_news() -> bool:
	if _tree_has_news():
		return true
	for i in buttons.size():
		if can_level_up(i):
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
	city_states[active_city] = _capture_city()
	cfg.set_value("world", "active_city", active_city)
	cfg.set_value("world", "cities", city_states)
	desktop.save_settings(cfg)
	cfg.set_value("city", "dollars", dollars)
	cfg.set_value("city", "total_earned", total_earned)
	cfg.set_value("city", "ink_level", ink_level)
	cfg.set_value("city", "boost_level", boost_level)
	var permanent := modifiers.filter(func(m: Dictionary) -> bool: return m.time_left == INF)
	cfg.set_value("city", "modifiers", permanent.map(
			func(m: Dictionary) -> Array: return [m.target, m.factor, m.label]))
	for b in buttons:
		cfg.set_value("buildings", b.name, b.count)
		cfg.set_value("building_upgrades", b.name, b.level)
	for key in ["lifetime_earned", "prestige_points", "chips", "renewals", "golden_coins",
			"clicks_total", "best_ips", "time_played", "red_clicked", "best_chain",
			"best_combo", "events_resolved"]:
		cfg.set_value("progress", key, get(key))
	cfg.set_value("progress", "reputation_upgrades", reputation_upgrades.keys())
	cfg.set_value("progress", "empire_tree", empire_tree)
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
		b.level = cfg.get_value("building_upgrades", b.name, 0)
	for key in ["lifetime_earned", "prestige_points", "chips", "renewals", "golden_coins",
			"clicks_total", "best_ips", "time_played", "red_clicked", "best_chain",
			"best_combo", "events_resolved"]:
		if cfg.has_section_key("progress", key):
			set(key, cfg.get_value("progress", key))
	if version < 4:
		# Antes se llamaba "cities" aunque contaba prestigios.
		renewals = cfg.get_value("progress", "cities", 0)
	if version < 2:
		golden_coins = cfg.get_value("game", "golden_coins", 0)
		lifetime_earned = total_earned
	for id in cfg.get_value("progress", "reputation_upgrades", []):
		reputation_upgrades[id] = true
	var saved_tree: Dictionary = cfg.get_value("progress", "empire_tree", {})
	for id in saved_tree:
		if not tree_node(id).is_empty():
			empire_tree[id] = clampi(int(saved_tree[id]), 0, int(tree_node(id).max))
	_apply_tree()
	for id in cfg.get_value("progress", "achievements", []):
		achievements[id] = true
	fx_enabled = cfg.get_value("settings", "fx_enabled", true)
	Fmt.scientific = cfg.get_value("settings", "scientific", false)
	for bus in VOLUME_BUSES:
		if cfg.has_section_key("volume", bus):
			set_volume(bus, cfg.get_value("volume", bus))

	if version >= 3:
		city_states.assign(cfg.get_value("world", "cities", []))
		if not city_states.is_empty():
			active_city = clampi(int(cfg.get_value("world", "active_city", 0)), 0, city_states.size() - 1)
			_restore_city(city_states[active_city])
	if version < 5:
		_migrate_reputation_tracks(version)
	desktop.restore_settings(cfg)

	var saved_at: float = cfg.get_value("game", "saved_at", Time.get_unix_time_from_system())
	var real_away := maxf(0.0, Time.get_unix_time_from_system() - saved_at)
	var away := minf(real_away, OFFLINE_MAX_SECONDS)
	if away < OFFLINE_MIN_SECONDS:
		return
	var efficiency := OFFLINE_EFFICIENCY_UPGRADED if has_reputation_upgrade("night_owl") else OFFLINE_EFFICIENCY
	# Las ciudades guardadas cobran los bonus solo durante su tiempo restante.
	var offline := _city_income(_capture_city(), away, false) * efficiency
	for m in modifiers:
		m.time_left -= away
	modifiers = modifiers.filter(func(m: Dictionary) -> bool: return m.time_left > 0.0)
	for payout in payouts:
		payout.time_left -= away
		if payout.time_left <= 0.0:
			offline += payout.amount
	payouts = payouts.filter(func(p: Dictionary) -> bool: return p.time_left > 0.0)
	var other_offline := _advance_other_cities(away, efficiency, false)
	if offline > 0.0:
		earn(offline)
	if offline + other_offline >= 1.0:
		var lines: PackedStringArray = []
		lines.append("While you were away (%s) your cities earned %s $." % [_duration(real_away), Fmt.money(offline + other_offline)])
		if city_states.size() > 1:
			var parts: PackedStringArray = []
			for i in city_states.size():
				var amount := offline if i == active_city else _last_city_earnings[i]
				parts.append("City %d: %s $" % [i + 1, Fmt.money(amount)])
			lines.append("  ·  ".join(parts))
		var rule := "Offline production counts at %d%%, up to %d h." % [roundi(efficiency * 100.0), roundi(OFFLINE_MAX_SECONDS / 3600.0)]
		if real_away > OFFLINE_MAX_SECONDS:
			rule += " Only the first %d h were counted." % roundi(OFFLINE_MAX_SECONDS / 3600.0)
		lines.append(rule)
		hud.show_welcome("\n".join(lines))


## Partidas v4 o anteriores, que usaban otra fórmula de Reputación.
## - v3 o anterior no guardaba lo ganado por ciudad: la seleccionada recibe lo que no se puede
##   atribuir a las demás.
## - Todo lo ganado hasta ahora se marca como ya cobrado: se conservan los puntos (sin deudas)
##   pero no se regalan puntos nuevos al cambiar de fórmula.
func _migrate_reputation_tracks(version: int) -> void:
	if version < 4:
		var others := 0.0
		for i in city_states.size():
			if i != active_city:
				var state := city_states[i]
				state.lifetime = float(state.get("total_earned", 0.0))
				others += state.lifetime
		city_lifetime = maxf(total_earned, lifetime_earned - others)
	for state in city_states:
		state.claimed_life = float(state.get("lifetime", state.get("total_earned", 0.0)))
		state.erase("claimed")
	city_claimed_life = city_lifetime
	if not city_states.is_empty():
		city_states[active_city] = _capture_city()


static func _duration(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [floori(minutes / 60.0), minutes % 60]


func _refresh_levels() -> void:
	var ready := levels_ready()
	var price := level_all_cost()
	levels_label.text = "Levels %d / %d" % [total_levels(), buttons.size() * ShopButton.MAX_LEVEL]
	if ready.is_empty():
		level_all_button.text = "Level up all  ·  nothing ready"
	else:
		level_all_button.text = "Level up all (%d)  ·  %s $" % [ready.size(), Fmt.money(price)]
	level_all_button.disabled = ready.is_empty() or dollars < price
