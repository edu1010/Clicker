class_name GameData
extends RefCounted
## Datos de contenido: logros, mejoras de Reputación y eventos.
## Las condiciones/efectos reciben el nodo del juego (game.gd) como `g`.

## Objetivos de los modificadores: índice de edificio (0..4) o uno de estos.
const TARGET_ALL := -1
const TARGET_CLICK := -2
const COMBO_MAX := 3.0


# --- Logros (cada uno da +1 % de ingresos) -----------------------------------------

static func achievements() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		_ach("click_100", "Clicker", "Click the printer 100 times.", func(g): return g.clicks_total >= 100),
		_ach("click_1000", "Carpal Tunnel", "Click the printer 1,000 times.", func(g): return g.clicks_total >= 1000),
		_ach("click_10000", "Iron Finger", "Click the printer 10,000 times.", func(g): return g.clicks_total >= 10000),
		_ach("earn_1k", "Pocket Money", "Earn 1K $ in total.", func(g): return g.lifetime_earned >= 1e3),
		_ach("earn_1m", "Millionaire", "Earn 1M $ in total.", func(g): return g.lifetime_earned >= 1e6),
		_ach("earn_1b", "Billionaire", "Earn 1B $ in total.", func(g): return g.lifetime_earned >= 1e9),
		_ach("earn_1t", "Trillionaire", "Earn 1T $ in total.", func(g): return g.lifetime_earned >= 1e12),
		_ach("ips_100", "Small Business", "Reach 100 $ per second.", func(g): return g.best_ips >= 100),
		_ach("ips_10k", "Corporation", "Reach 10K $ per second.", func(g): return g.best_ips >= 1e4),
		_ach("ips_1m", "Empire", "Reach 1M $ per second.", func(g): return g.best_ips >= 1e6),
		_ach("all_buildings", "City Planner", "Own at least one of every building.", func(g): return g.min_building_count() >= 1),
		_ach("own_50", "Monopoly", "Own 50 of a single building.", func(g): return g.max_building_count() >= 50),
		_ach("own_100", "Megacity", "Own 100 of a single building.", func(g): return g.max_building_count() >= 100),
		_ach("renovator", "Renovator", "Reach 10 building levels in one city.", func(g): return g.total_levels() >= 10),
		_ach("max_level", "Skyline", "Raise a building to level 10.", func(g): return g.buttons.any(func(b): return b.is_max_level())),
		_ach("golden_1", "Lucky Find", "Catch a golden coin.", func(g): return g.golden_coins >= 1),
		_ach("golden_10", "Treasure Hunter", "Catch 10 golden coins.", func(g): return g.golden_coins >= 10),
		_ach("golden_50", "Midas", "Catch 50 golden coins.", func(g): return g.golden_coins >= 50),
		_ach("daredevil", "Daredevil", "Click a cursed red coin.", func(g): return g.red_clicked >= 1),
		_ach("chain_5", "Chain Reaction", "Reach a golden coin chain of 5.", func(g): return g.best_chain >= 5),
		_ach("combo_max", "Combo Master", "Reach the maximum click combo.", func(g): return g.best_combo >= GameData.COMBO_MAX),
		_ach("decisive", "Decisive", "Resolve 5 city events.", func(g): return g.events_resolved >= 5),
		_ach("prestige_1", "New Beginnings", "Renew a city for reputation.", func(g): return g.renewals >= 1),
		_ach("expand_2", "Founder", "Found a second city.", func(g): return g.city_states.size() >= 2),
		_ach("prestige_25", "Legend", "Have 25 reputation.", func(g): return g.prestige_points >= 25),
		_ach("conglomerate", "Conglomerate", "Buy 10 ranks in the empire tree.", func(g): return g.tree_ranks_bought() >= 10),
	]
	return list


static func _ach(id: String, title: String, desc: String, check: Callable) -> Dictionary:
	return {"id": id, "name": title, "desc": desc, "check": check}


# --- Mejoras de Reputación (se compran con la Reputación sin gastar) ---------------

static func reputation_upgrades() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"id": "head_start", "name": "Head Start", "desc": "Start every city with 5 bars.", "cost": 3},
		{"id": "seed_money", "name": "Seed Money", "desc": "Start every city with 1K $.", "cost": 5},
		{"id": "lucky_charm", "name": "Lucky Charm", "desc": "Golden coins appear 30% more often.", "cost": 8},
		{"id": "night_owl", "name": "Night Owl", "desc": "Offline earnings 75% instead of 50%.", "cost": 12},
		{"id": "golden_age", "name": "Golden Age", "desc": "Golden coin effects last 50% longer.", "cost": 20},
	]
	return list


# --- Árbol del imperio (se paga con el dinero de todas las ciudades) ---------------
# Cada nodo: rama, nombre, rangos máximos, coste del primer rango, crecimiento por rango,
# efecto por rango (`per`) y nodo previo (`requires`, rango 1). El texto del efecto actual
# es `fmt % (per × rango × scale)`. Costes y efectos elegidos por simulación (sección 26).

const TREE_BRANCHES := ["Commerce", "Fortune", "Hands", "Logistics"]


static func empire_tree() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		_node("trade_network", "Commerce", "Trade Network", "+4% income in every city.", 5, 1e6, 8.0, 0.04, "", "+%d%% income", 100.0),
		_node("supply_chains", "Commerce", "Supply Chains", "Synergies are 10% stronger.", 3, 1e10, 10.0, 0.1, "trade_network", "+%d%% synergy", 100.0),
		_node("franchising", "Commerce", "Franchising", "Building levels cost 10% less.", 3, 1e14, 15.0, 0.1, "supply_chains", "-%d%% level cost", 100.0),
		_node("global_brand", "Commerce", "Global Brand", "+20% income in every city.", 2, 1e17, 20.0, 0.2, "franchising", "+%d%% income", 100.0),
		_node("lucky_streets", "Fortune", "Lucky Streets", "Golden coins appear 4% more often.", 5, 3e6, 8.0, 0.04, "", "+%d%% coins", 100.0),
		_node("midas_odds", "Fortune", "Midas Odds", "+2% chance that a golden coin is a Frenzy.", 5, 3e10, 8.0, 0.02, "lucky_streets", "+%d%% Frenzy chance", 100.0),
		_node("long_party", "Fortune", "Long Party", "Golden coin effects last 10% longer.", 3, 3e14, 15.0, 0.1, "midas_odds", "+%d%% duration", 100.0),
		_node("golden_vault", "Fortune", "Golden Vault", "Golden coin bonus cap +10%.", 3, 3e17, 15.0, 0.1, "long_party", "cap +%d%%", 100.0),
		_node("ergonomics", "Hands", "Ergonomics", "Max click combo +0.25.", 4, 2e6, 8.0, 0.25, "", "combo +%.2f", 1.0),
		_node("printing_press", "Hands", "Printing Press", "Printer clicks x2.", 3, 2e10, 10.0, 1.0, "ergonomics", "clicks x%d", 1.0).merged({"exp": true}),
		_node("lucky_press", "Hands", "Lucky Press", "Each click has a 0.05% chance to drop a golden coin.", 3, 2e14, 15.0, 0.0005, "printing_press", "%.2f%% per click", 100.0),
		_node("open_all_night", "Logistics", "Open All Night", "+10% income while the game is open (not offline).", 2, 5e6, 10.0, 0.1, "", "+%d%% while open", 100.0),
		_node("real_estate", "Logistics", "Real Estate", "Founding a city costs 15% less.", 3, 5e10, 10.0, 0.15, "open_all_night", "-%d%% founding", 100.0),
		_node("heritage", "Logistics", "Heritage", "Renewing a city keeps 1 level on every building.", 2, 5e14, 20.0, 1.0, "real_estate", "keep %d levels", 1.0),
		_node("empire_hq", "Logistics", "Empire HQ", "Each reputation point gives +0.25% more income.", 2, 5e17, 20.0, 0.0025, "heritage", "+%.2f%% per point", 100.0),
	]
	return list


static func _node(id: String, branch: String, title: String, desc: String, max_rank: int, cost: float,
		growth: float, per: float, requires: String, fmt: String, scale: float) -> Dictionary:
	return {"id": id, "branch": branch, "name": title, "desc": desc, "max": max_rank, "cost": cost,
		"growth": growth, "per": per, "requires": requires, "fmt": fmt, "scale": scale}


## Coste del rango `rank + 1` de un nodo.
static func tree_cost(node: Dictionary, rank: int, scale := 1.0) -> float:
	return float(node.cost) * pow(float(node.growth), rank) * scale


## Texto del efecto acumulado con `rank` rangos.
static func tree_effect_text(node: Dictionary, rank: int) -> String:
	var value: float = pow(2.0, rank) if node.get("exp", false) else float(node.per) * rank * float(node.scale)
	return String(node.fmt) % (roundi(value) if String(node.fmt).contains("%d") else value)


# --- Eventos con decisión ---------------------------------------------------------
# Cada evento: título, texto, opciones a/b, condición y efecto de cada opción
# (devuelve el mensaje a mostrar).

static func events() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{
			"id": "tax", "title": "Tax inspection",
			"text": "The tax office wants to check your books.",
			"a": "Pay 10% of your cash", "b": "Risk it (50%: lose 30%)",
			"requires": func(g): return g.dollars >= 100.0,
			"on_a": func(g): return GameData._pay_fraction(g, 0.1, "You paid %s $ in taxes."),
			"on_b": func(g): return GameData._tax_risk(g),
		},
		{
			"id": "strike", "title": "Factory strike",
			"text": "Factory workers demand better pay.",
			"a": "Raise wages (factories -10% this city)", "b": "Wait it out (factories stop 60 s)",
			"requires": func(g): return g.count_of(1) > 0,
			"on_a": func(g): return GameData._modifier(g, 1, 0.9, INF, "Higher wages", "Workers are happy again."),
			"on_b": func(g): return GameData._modifier(g, 1, 0.0, 60.0, "Strike", "Factories are on strike for 60 s."),
		},
		{
			"id": "festival", "title": "City festival",
			"text": "The neighbours want to throw a big street festival.",
			"a": "Sponsor it: pay 3 min of income, bars x3 for 2 min", "b": "Skip it",
			"requires": func(g): return g.count_of(0) > 0,
			"on_a": func(g): return GameData._festival(g),
			"on_b": func(_g): return "Maybe next year.",
		},
		{
			"id": "investor", "title": "Mysterious investor",
			"text": "A stranger in a nice suit offers to double your money.",
			"a": "Invest 25% of your cash (75% chance x2 in 2 min)", "b": "Decline",
			"requires": func(g): return g.dollars >= 1000.0,
			"on_a": func(g): return GameData._invest(g),
			"on_b": func(_g): return "You keep your money in your pocket.",
		},
		{
			"id": "tourists", "title": "Tourist bus",
			"text": "A bus full of tourists just arrived in town!",
			"a": "Big party: all income x2 for 60 s", "b": "Sell souvenirs: +2 min of income now",
			"requires": func(g): return g.income_per_second() > 0.0,
			"on_a": func(g): return GameData._modifier(g, GameData.TARGET_ALL, 2.0, 60.0, "Party", "Party time! Income x2 for 60 s."),
			"on_b": func(g): return GameData._earn_seconds(g, 120.0, "Souvenirs sold: +%s $."),
		},
		{
			"id": "blackout", "title": "Power outage",
			"text": "The power grid is failing all over the city.",
			"a": "Buy generators (pay 1 min of income)", "b": "Wait (all income x0.5 for 45 s)",
			"requires": func(g): return g.income_per_second() > 0.0,
			"on_a": func(g): return GameData._pay_seconds(g, 60.0, "Generators bought for %s $."),
			"on_b": func(g): return GameData._modifier(g, GameData.TARGET_ALL, 0.5, 45.0, "Blackout", "Half power for 45 s."),
		},
	]
	return list


static func _pay_fraction(g, fraction: float, message: String) -> String:
	var amount: float = g.dollars * fraction
	g.dollars -= amount
	return message % Fmt.money(amount)


static func _tax_risk(g) -> String:
	if randf() < 0.5:
		return "They found nothing. Lucky you!"
	return _pay_fraction(g, 0.3, "Fined %s $!")


static func _modifier(g, target: int, factor: float, duration: float, label: String, message: String) -> String:
	g.add_modifier(target, factor, duration, label)
	return message


static func _festival(g) -> String:
	var price: float = g.income_per_second() * 180.0
	if g.dollars < price:
		return "You couldn't afford the festival."
	g.dollars -= price
	g.add_modifier(0, 3.0, 120.0, "Festival")
	return "Festival! Bars x3 for 2 min."


static func _invest(g) -> String:
	var amount: float = g.dollars * 0.25
	g.dollars -= amount
	var won := randf() < 0.75
	g.schedule_payout(120.0, amount * 2.0 if won else 0.0,
			"The investor returned %s $!" % Fmt.money(amount * 2.0) if won else "The investor vanished with your money...")
	return "Invested %s $. Results in 2 minutes." % Fmt.money(amount)


static func _earn_seconds(g, seconds: float, message: String) -> String:
	var amount: float = g.income_per_second() * seconds
	g.earn(amount)
	return message % Fmt.money(amount)


static func _pay_seconds(g, seconds: float, message: String) -> String:
	var amount: float = minf(g.dollars, g.income_per_second() * seconds)
	g.dollars -= amount
	return message % Fmt.money(amount)
