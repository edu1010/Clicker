extends SceneTree
## Simulador de balance de MoneyClicker (secciones 5.4 y 7.4 de
## docs/INVESTIGACION_DISENO_INCREMENTALES.md).
##
## Uso: godot --headless --path ClickerGodot --script res://tools/balance_sim.gd
## Escribe el informe en docs/SIMULACION_BALANCE.md.
##
## Modelo en tiempo continuo por eventos: entre dos decisiones los ingresos son constantes,
## así que se salta directamente al momento en que algo se puede pagar. Reutiliza los datos
## de main.tscn y las constantes de game.gd / shop_button.gd: costes x1.15, hitos, mejoras,
## sinergias, clic con combo, Ink / Golden Touch, Reputación por ciudad, coste de fundación,
## mejoras de Reputación y producción offline. Las monedas especiales entran como valor
## esperado. No modela eventos ni logros (ambos suman ingresos: estimación conservadora).

const Game := preload("res://scripts/game.gd")
const OUT_PATH := "res://docs/SIMULACION_BALANCE.md"
const PRESTIGE_OUT_PATH := "res://docs/SIMULACION_PRESTIGIO.md"

## Alternativas de prestigio (sección 21.2 de la investigación).
const PRESTIGE_OPTIONS := [
	{"name": "Original: √(ganado/100K), +1 %/punto", "prest_div": 1e5, "prest_root": 2.0, "rep_model": "linear", "rep_bonus": 0.01, "rep_scope": "city"},
	{"name": "√(ganado/10M), +1 %/punto", "prest_div": 1e7, "prest_root": 2.0, "rep_model": "linear", "rep_bonus": 0.01, "rep_scope": "city"},
	{"name": "√(ganado/1B), +1 %/punto", "prest_div": 1e9, "prest_root": 2.0, "rep_model": "linear", "rep_bonus": 0.01, "rep_scope": "city"},
	{"name": "∛(ganado/100K), +1 %/punto", "prest_div": 1e5, "prest_root": 3.0, "rep_model": "linear", "rep_bonus": 0.01, "rep_scope": "city"},
	{"name": "∛(ganado/10M), +1 %/punto", "prest_div": 1e7, "prest_root": 3.0, "rep_model": "linear", "rep_bonus": 0.01, "rep_scope": "city"},
	{"name": "√(ganado/100K), +10 %·√reputación", "prest_div": 1e5, "prest_root": 2.0, "rep_model": "sqrt", "rep_bonus": 0.1},
]
## Monedas corregidas: +0,5 % permanente por moneda y Click Frenzy sin Golden Touch.
const COIN_FIX := {"coin_bonus": 0.005, "frenzy_boost": false, "coin_cap": -1.0}
## Monedas del juego antes de la sección 23: +2 % sin tope y Click Frenzy con Golden Touch.
const OLD_COINS := {"coin_bonus": 0.02, "frenzy_boost": true, "coin_cap": -1.0}
## Las suites comparativas se ejecutaron con el factor de fundación anterior (×5).
const SUITE_FOUND_GROWTH := 5.0

const EMPIRE_OUT_PATH := "res://docs/SIMULACION_IMPERIO.md"
const TREE_OUT_PATH := "res://docs/SIMULACION_ARBOL.md"
## Escalas de coste del árbol que compara la suite (1 = costes de GameData.empire_tree()).
const TREE_SCALES: Array[float] = [0.1, 0.3, 1.0, 3.0, 10.0]
## Valor que el bot atribuye a los nodos del árbol sin efecto directo en $/s
## (fracción del valor del imperio por rango).
## Cada cuántos segundos de juego reevalúa el bot el árbol cuando no está ahorrando.
const TREE_CHECK := 60.0
const TREE_UTILITY := {"franchising": 0.05, "real_estate": 0.03, "heritage": 0.1}
## Variantes de producción con el juego cerrado: eficiencia y horas reconocidas.
const OFFLINE_VARIANTS := [
	{"name": "Sin offline", "offline_eff": 0.0, "offline_cap": 0.0},
	{"name": "25 %, 4 h", "offline_eff": 0.25, "offline_cap": 4.0 * 3600.0},
	{"name": "25 %, 8 h", "offline_eff": 0.25, "offline_cap": 8.0 * 3600.0},
	{"name": "50 %, 8 h (actual)", "offline_eff": 0.5, "offline_cap": 8.0 * 3600.0},
	{"name": "100 %, 8 h", "offline_eff": 1.0, "offline_cap": 8.0 * 3600.0},
	{"name": "100 %, sin límite", "offline_eff": 1.0, "offline_cap": 1e9},
]
## Fórmula recomendada por la suite de prestigio (sección 22).
const CUBE_10M := {"prest_div": 1e7, "prest_root": 3.0, "rep_model": "linear", "rep_bonus": 0.01}
const COIN_VARIANTS := [
	{"name": "+0,5 %/moneda sin tope", "coin_bonus": 0.005, "frenzy_boost": false, "coin_cap": -1.0},
	{"name": "+2 %/moneda, tope +50 %", "coin_bonus": 0.02, "coin_cap": 0.5, "frenzy_boost": false},
	{"name": "sin bonus permanente", "coin_bonus": 0.0, "frenzy_boost": false, "coin_cap": -1.0},
]
const H := 3600.0
const HORIZON := 72.0 * H
const SNAPSHOTS: Array[float] = [1.0 * H, 4.0 * H, 12.0 * H, 24.0 * H, 72.0 * H]
const MAX_PRESENT_STEP := 60.0
const MIN_STEP := 0.001
const NEVER := -1.0

## Perfiles de jugador. every <= 0: siempre presente. closed: el juego se cierra al irse
## (producción offline del juego); si no, sigue abierto como widget al 100 %.
const PROFILES := {
	"Activo": {"cps": 2.0, "every": 0.0, "len": 0.0, "closed": false,
		"desc": "presente siempre, 2 clics/s (cota superior de juego activo)"},
	"Espaciado": {"cps": 2.0, "every": 1800.0, "len": 60.0, "closed": false,
		"desc": "widget abierto; mira 1 min cada 30 min y hace 2 clics/s mientras mira"},
	"Sesiones": {"cps": 2.0, "every": 43200.0, "len": 3600.0, "closed": true,
		"desc": "dos sesiones de 1 h al día; cierra el juego entre sesiones"},
	"Sesiones+widget": {"cps": 2.0, "every": 43200.0, "len": 3600.0, "closed": false,
		"desc": "mismas sesiones, pero deja el juego abierto como widget entre ellas"},
}

var base_cost: Array[float] = []
var base_income: Array[float] = []
var synergy: Array[float] = []
var names: Array[String] = []
var rep_upgrades: Array[Dictionary] = []
var chain_seconds := 0.0
var chain_links := 0.0

# Estado de la simulación en curso.
var p: Dictionary
var prof: Dictionary
var t := 0.0
var cities: Array[Dictionary] = []
var rep := 0
var chips := 0
var golden := 0.0
var owned := {}
var coin_progress := 0.0
var focus := 0
var present := false
var m: Dictionary
## Árbol del imperio: rangos comprados y coste del rango para el que se ahorra (-1: ninguno).
var tree_nodes: Array[Dictionary] = []
var tree := {}
var tree_goal := -1.0
var tree_check_at := 0.0


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	for b in scene.get_node("Buttons").get_children():
		base_cost.append(b.base_cost)
		base_income.append(b.income_per_second)
		synergy.append(b.synergy_from_next)
		names.append(b.title)
	scene.free()
	rep_upgrades = GameData.reputation_upgrades()
	tree_nodes = GameData.empire_tree()
	for link in range(1, Game.CHAIN_MAX + 1):
		var chance := pow(Game.CHAIN_CONTINUE_CHANCE, link - 1)
		chain_seconds += 15.0 * link * chance
		chain_links += chance

	var started := Time.get_ticks_msec()
	# Sondeo rápido: -- --probe=Perfil[,renew][,found] ejecuta un solo escenario.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe="):
			var parts := arg.trim_prefix("--probe=").split(",")
			var overrides := {"renew": "renew" in parts, "found_save": 600.0 if "found" in parts else 0.0}
			for part in parts:
				if part.begins_with("lb="):
					overrides.level_base = part.trim_prefix("lb=").to_float()
				elif part.begins_with("lg="):
					overrides.level_growth = part.trim_prefix("lg=").to_float()
				elif part.begins_with("ts="):
					overrides.tree_scale = part.trim_prefix("ts=").to_float()
				elif part.begins_with("off="):
					overrides.tree_off = part.trim_prefix("off=").split("+")
				elif part == "notree":
					overrides.tree = false
			var r := run(_params(parts[0], overrides))
			print("%s: %.1f s, pasos %d, ciudades %d, rep %d, ganado %s, compras %s" % [arg, (Time.get_ticks_msec() - started) / 1000.0,
					r.steps, cities.size(), r.rep, _m(r.earned), _purchases(r)])
			for s in r.snap.size():
				print("  %s: niveles (mejor ciudad) %d, árbol %d/%d, $/s %s" % [_t(SNAPSHOTS[s]), r.snap[s].levels,
						r.snap[s].tree, _tree_total(), _m(r.snap[s].ips)])
			print("  árbol: primera compra %s, completo %s, orden %s" % [_t(r.t_tree_first), _t(r.t_tree_full), ", ".join(r.tree_order)])
			quit()
			return
	# -- --suite=prestige: compara fórmulas de prestigio y monedas alternativas.
	# -- --suite=empire: métrica de imperio, tope de monedas y matriz de fundación.
	var args := OS.get_cmdline_user_args()
	var path := OUT_PATH
	var report := ""
	if "--suite=prestige" in args:
		path = PRESTIGE_OUT_PATH
		report = _prestige_report()
	elif "--suite=empire" in args:
		path = EMPIRE_OUT_PATH
		report = _empire_report()
	elif "--suite=tree" in args:
		path = TREE_OUT_PATH
		report = _tree_report()
	else:
		report = _report()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(report)
	file.close()
	print(report)
	print("Simulación completada en %.1f s -> %s" % [(Time.get_ticks_msec() - started) / 1000.0, path])
	quit()


# --- Escenarios e informe ---------------------------------------------------------

func _params(profile: String, overrides := {}) -> Dictionary:
	var params := {"profile": profile, "coins": true, "found_base": Game.FOUND_BASE_COST,
		"found_growth": Game.FOUND_GROWTH, "found_save": 0.0, "renew": false,
		# Prestigio: reputación = floor((ganado / divisor)^(1/root)); bonus lineal o √reputación.
		"prest_div": Game.PRESTIGE_DIVISOR, "prest_root": Game.PRESTIGE_ROOT, "rep_model": "linear",
		"rep_bonus": Game.REPUTATION_BONUS,
		# Monedas: bonus permanente por moneda y si Click Frenzy escala con Golden Touch.
		"coin_bonus": Game.GOLDEN_BONUS_PER_COIN, "frenzy_boost": false, "coin_cap": Game.GOLDEN_BONUS_CAP,
		# Ámbito de la Reputación: "city" (raíz por ciudad) o "empire" (raíz del imperio repartida).
		"rep_scope": "empire",
		# Niveles de edificio: coste = base × level_base × level_growth^nivel.
		"level_base": ShopButton.LEVEL_COST_BASE, "level_growth": ShopButton.LEVEL_COST_GROWTH,
		# Árbol del imperio: se ahorra para el mejor rango cuando su puntuación es menor que
		# tree_patience × la de la mejor compra de las ciudades; costes × tree_scale.
		"tree": true, "tree_patience": 1.0, "tree_scale": 1.0, "tree_off": [],
		# Producción con el juego cerrado.
		"offline_eff": Game.OFFLINE_EFFICIENCY, "offline_cap": Game.OFFLINE_MAX_SECONDS}
	params.merge(overrides, true)
	return params


func _report() -> String:
	var out: PackedStringArray = []
	out.append("# Simulación de balance — MoneyClicker\n")
	out.append("Generado por `tools/balance_sim.gd` el %s. No editar a mano: volver a ejecutar el simulador.\n" % Time.get_date_string_from_system())
	out.append("## Supuestos\n")
	out.append("- Economía leída de `main.tscn`, `game.gd` y `shop_button.gd`; horizonte de %d h de reloj." % roundi(HORIZON / H))
	for name in PROFILES:
		out.append("- **%s:** %s." % [name, PROFILES[name].desc])
	out.append("- Compra: entre todas las opciones (1 edificio, edificios hasta el siguiente hito, mejora de edificio, Better Ink, Golden Touch) elige la de menor `espera + precio / aumento de $/s`, recalculando toda la ciudad (hitos y sinergias).")
	out.append("- Los clics y las monedas se hacen en la ciudad más nueva mientras produce menos del 10 % de la mejor; después, en la mejor.")
	out.append("- Monedas especiales como valor esperado (Lucky, Frenzy, Click Frenzy, cadenas, rojas) cuando el jugador está presente. Sin eventos ni logros.")
	out.append("- Fundar: la ciudad que más produce ahorra cuando el precio cabe en `X` segundos de su producción, y funda al poder pagarlo.")
	out.append("- Renovar: la ciudad con más reputación pendiente se renueva cuando duplica la reputación total (`pendiente >= max(1, reputación)`). Las mejoras de Reputación se compran en cuanto se pueden pagar.\n")

	# 1. Ritmo de una sola ciudad.
	out.append("## 1. Ritmo de una ciudad (sin fundar ni renovar)\n")
	out.append("| Perfil | 1.ª Fábrica | 1.er Hospital | 1.er Banco | 1.er Casino | $/s 1 h | $/s 4 h | $/s 24 h | $/s 72 h |")
	out.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
	var base_runs := {}
	for name in PROFILES:
		var r := run(_params(name))
		base_runs[name] = r
		out.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % [name, _t(r.first[1]), _t(r.first[2]),
				_t(r.first[3]), _t(r.first[4]), _m(r.snap[0].ips), _m(r.snap[1].ips), _m(r.snap[3].ips), _m(r.snap[4].ips)])
	out.append("\n**Origen del dinero y estrategia dominante (72 h):**\n")
	out.append("| Perfil | Edificios | Clics | Monedas | Offline | Compras de edificio que son el más caro desbloqueado | $/s 24 h sin monedas | Efecto de las monedas a 24 h |")
	out.append("|---|---:|---:|---:|---:|---:|---:|---:|")
	for name in PROFILES:
		var r: Dictionary = base_runs[name]
		var no_coins := run(_params(name, {"coins": false}))
		out.append("| %s | %s | %s | %s | %s | %s | %s | x%.1f |" % [name, _pct(r.build / r.earned), _pct(r.click / r.earned),
				_pct(r.coin / r.earned), _pct(r.offline / r.earned), _pct(float(r.latest_buys) / maxi(1, r.building_buys)),
				_m(no_coins.snap[3].ips), r.snap[3].ips / maxf(no_coins.snap[3].ips, 1e-9)])
	out.append("\nLas compras se reparten así en el perfil Activo: %s.\n" % _purchases(base_runs["Activo"]))

	# 2. Fundación.
	out.append("## 2. Coste de fundar ciudades\n")
	out.append("Comparación con no fundar nunca (mismo perfil, renovando). «Ganado» = dinero total generado en 72 h. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.\n")
	for name in ["Activo", "Espaciado"]:
		var never := run(_params(name, {"renew": true}))
		out.append("### Perfil %s\n" % name)
		out.append("Sin fundar: ganado 72 h %s $, reputación %d, $/s final %s.\n" % [_m(never.earned), never.rep, _m(never.snap[4].ips)])
		out.append("| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |")
		out.append("|---:|---:|---|---:|---:|---:|---:|---:|---:|")
		for save_s in [600.0, 3600.0]:
			for base in [1e5, 2.5e5, 1e6]:
				for growth in [3.0, 5.0, 8.0]:
					var r := run(_params(name, {"renew": true, "found_base": base, "found_growth": growth, "found_save": save_s}))
					out.append("| %s | %d | %s | %s | %d | %d | %+.0f %% | %d | %s |" % [_m(base), growth, _t(save_s), _t(r.t_second_city),
							r.snap[3].cities, r.snap[4].cities, (r.earned / never.earned - 1.0) * 100.0, r.rep, _t(_median(r.found_paybacks))])
		out.append("")

	# 3. Renovación.
	out.append("## 3. Renovar (prestigio)\n")
	out.append("Con el precio actual de fundación (%s × %d) y ahorro si cabe en 10 min. «Recuperación» = mediana del tiempo que tarda la ciudad renovada en volver a producir lo que producía antes.\n" % [_m(Game.FOUND_BASE_COST), roundi(Game.FOUND_GROWTH)])
	out.append("| Perfil | Renovar | 1.ª renovación | Renovaciones | Reputación 72 h | Ciudades 72 h | Ganado 72 h | $/s 72 h | Recuperación |")
	out.append("|---|---|---:|---:|---:|---:|---:|---:|---:|")
	for name in PROFILES:
		for renew in [false, true]:
			var r := run(_params(name, {"renew": renew, "found_save": 600.0}))
			out.append("| %s | %s | %s | %d | %d | %d | %s | %s | %s |" % [name, "sí" if renew else "no", _t(r.t_first_renew),
					r.renewals, r.rep, r.snap[4].cities, _m(r.earned), _m(r.snap[4].ips), _t(_median(r.recoveries))])
	out.append("")
	return "\n".join(out)


func _prestige_report() -> String:
	var out: PackedStringArray = []
	out.append("# Simulación de alternativas de prestigio — MoneyClicker\n")
	out.append("Generado por `tools/balance_sim.gd -- --suite=prestige` el %s. Mismos bots y supuestos que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md): renovar cuando la reputación pendiente duplica la total, fundar con el precio actual (%s × %d) cuando cabe en 10 min de producción, horizonte de 72 h.\n" % [
			Time.get_date_string_from_system(), _m(Game.FOUND_BASE_COST), roundi(SUITE_FOUND_GROWTH)])
	out.append("- **Renovar ×:** dinero ganado en 72 h renovando frente a no renovar nunca (ambos fundando).")
	out.append("- **Fundar:** dinero ganado en 72 h fundando frente a no fundar (ambos renovando).")
	out.append("- **Recuperación:** mediana del tiempo que tarda una ciudad renovada en volver a producir lo de antes.")
	out.append("- **Monedas corregidas:** +0,5 % permanente por moneda (en vez de +2 %) y Click Frenzy calculado sin Golden Touch.\n")
	var ratios: PackedStringArray = []
	for coin_variant in [OLD_COINS, COIN_FIX]:
		var fixed: bool = coin_variant == COIN_FIX
		out.append("## %s\n" % ("Monedas corregidas" if fixed else "Monedas originales (+2 % sin tope)"))
		var no_renew := {}
		for name in ["Activo", "Espaciado"]:
			var base := _params(name, {"found_save": 600.0, "found_growth": SUITE_FOUND_GROWTH})
			base.merge(coin_variant, true)
			no_renew[name] = run(base)
			out.append("Sin renovar, %s: ganado %s $, %d ciudades, $/s final %s." % [name, _m(no_renew[name].earned),
					no_renew[name].snap[4].cities, _m(no_renew[name].snap[4].ips)])
		out.append("\n| Fórmula | Perfil | 1.ª renovación | Renovaciones | Recuperación | Reputación 72 h | Ganado 72 h | Renovar × | Fundar | Ciudades 72 h |")
		out.append("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|")
		for option: Dictionary in PRESTIGE_OPTIONS:
			var earned := {}
			for name in ["Activo", "Espaciado"]:
				var params := _params(name, {"renew": true, "found_save": 600.0, "found_growth": SUITE_FOUND_GROWTH})
				params.merge(option, true)
				params.merge(coin_variant, true)
				var r := run(params)
				var no_found_params := params.duplicate()
				no_found_params.found_save = 0.0
				var no_found := run(no_found_params)
				earned[name] = r.earned
				out.append("| %s | %s | %s | %d | %s | %s | %s $ | ×%s | %+.0f %% | %d |" % [option.name, name, _t(r.t_first_renew),
						r.renewals, _t(_median(r.recoveries)), _m(r.rep), _m(r.earned), _ratio(r.earned / no_renew[name].earned),
						(r.earned / no_found.earned - 1.0) * 100.0, r.snap[4].cities])
			ratios.append("| %s | %s | ×%s |" % [option.name, "corregidas" if fixed else "originales", _ratio(earned["Activo"] / earned["Espaciado"])])
		out.append("")
	out.append("## Ventaja del juego activo\n")
	out.append("Dinero ganado en 72 h por el perfil Activo dividido entre el del perfil Espaciado (ambos renovando y fundando).\n")
	out.append("| Fórmula | Monedas | Activo / Espaciado |")
	out.append("|---|---|---:|")
	out.append_array(ratios)
	out.append("")
	return "\n".join(out)


func _empire_report() -> String:
	var out: PackedStringArray = []
	out.append("# Simulación de Reputación de imperio y tope de monedas — MoneyClicker\n")
	out.append("Generado por `tools/balance_sim.gd -- --suite=empire` el %s. Mismos bots que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md); prestigio ∛(ganado/10M) con +1 %% por punto (candidato de la sección 22); Click Frenzy sin Golden Touch; horizonte de 72 h.\n" % Time.get_date_string_from_system())
	out.append("- **Ciudad:** cada ciudad tiene su propia raíz (como el juego ahora).")
	out.append("- **Imperio:** la raíz se calcula sobre lo ganado por todas las ciudades; al renovar una ciudad se cobra la parte pendiente proporcional a lo que ganó desde su última renovación.")
	out.append("- **Renovar ×:** ganado renovando frente a no renovar (ambos fundando). **Fundar:** ganado fundando frente a no fundar (ambos renovando).\n")
	out.append("## 1. Ámbito de la Reputación y monedas\n")
	out.append("Precio de fundación actual (%s × %d), ahorrando cuando cabe en 10 min de producción.\n" % [_m(Game.FOUND_BASE_COST), roundi(SUITE_FOUND_GROWTH)])
	out.append("| Ámbito | Monedas | Perfil | 1.ª renovación | Renovaciones | Recuperación | Reputación 72 h | Ganado 72 h | Renovar × | Fundar | Ciudades 72 h |")
	out.append("|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|")
	var ratios: PackedStringArray = []
	for coins: Dictionary in COIN_VARIANTS:
		var no_renew := {}
		for name in ["Activo", "Espaciado"]:
			var base := _params(name, {"found_save": 600.0, "found_growth": SUITE_FOUND_GROWTH})
			base.merge(coins, true)
			base.erase("name")
			no_renew[name] = run(base)
		for scope in ["city", "empire"]:
			var earned := {}
			for name in ["Activo", "Espaciado"]:
				var params := _params(name, {"renew": true, "found_save": 600.0, "found_growth": SUITE_FOUND_GROWTH, "rep_scope": scope})
				params.merge(CUBE_10M, true)
				params.merge(coins, true)
				params.erase("name")
				var r := run(params)
				var no_found_params := params.duplicate()
				no_found_params.found_save = 0.0
				var no_found := run(no_found_params)
				earned[name] = r.earned
				out.append("| %s | %s | %s | %s | %d | %s | %s | %s $ | ×%s | %+.0f %% | %d |" % [_scope(scope), coins.name, name,
						_t(r.t_first_renew), r.renewals, _t(_median(r.recoveries)), _m(r.rep), _m(r.earned),
						_ratio(r.earned / no_renew[name].earned), (r.earned / no_found.earned - 1.0) * 100.0, r.snap[4].cities])
			ratios.append("| %s | %s | ×%s |" % [_scope(scope), coins.name, _ratio(earned["Activo"] / earned["Espaciado"])])
	out.append("\n**Ventaja del juego activo** (ganado por Activo ÷ ganado por Espaciado, ambos renovando y fundando):\n")
	out.append("| Ámbito | Monedas | Activo / Espaciado |")
	out.append("|---|---|---:|")
	out.append_array(ratios)

	var chosen: Dictionary = COIN_VARIANTS[1]
	out.append("\n## 2. Precio de fundación con Reputación de imperio\n")
	out.append("Monedas: %s. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.\n" % chosen.name)
	for name in ["Activo", "Espaciado"]:
		var never := _params(name, {"renew": true, "rep_scope": "empire"})
		never.merge(CUBE_10M, true)
		never.merge(chosen, true)
		never.erase("name")
		var never_run := run(never)
		out.append("### Perfil %s\n" % name)
		out.append("Sin fundar: ganado 72 h %s $, reputación %s.\n" % [_m(never_run.earned), _m(never_run.rep)])
		out.append("| Base | Factor | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Fundar vs no fundar | Reputación 72 h | Recupera |")
		out.append("|---:|---:|---:|---:|---:|---:|---:|---:|")
		for base in [1e5, 2.5e5, 1e6]:
			for growth in [3.0, 5.0, 8.0]:
				var params := never.duplicate()
				params.merge({"found_base": base, "found_growth": growth, "found_save": 600.0}, true)
				var r := run(params)
				out.append("| %s | %d | %s | %d | %d | %+.0f %% | %s | %s |" % [_m(base), growth, _t(r.t_second_city),
						r.snap[3].cities, r.snap[4].cities, (r.earned / never_run.earned - 1.0) * 100.0, _m(r.rep), _t(_median(r.found_paybacks))])
		out.append("")
	return "\n".join(out)


func _tree_report() -> String:
	var out: PackedStringArray = []
	out.append("# Simulación del árbol del imperio y de la producción offline — MoneyClicker\n")
	out.append("Generado por `tools/balance_sim.gd -- --suite=tree` el %s. Mismos bots que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md), renovando y fundando (ahorro si cabe en 10 min), horizonte de 72 h.\n" % Time.get_date_string_from_system())
	out.append("- El bot compara cada rango del árbol con las compras de las ciudades usando la misma puntuación (`espera + coste / aumento de $/s`, con el aumento medido en todo el imperio, incluidos clics y monedas); ahorra para el árbol cuando su mejor rango puntúa mejor que la mejor compra de cualquier ciudad. Franchising, Real Estate y Heritage, que no suben los $/s directamente, cuentan como +5 %, +3 % y +10 % por rango. Mientras ahorra, ninguna ciudad compra otra cosa. Paga con el dinero de todas las ciudades, en proporción a lo que tiene cada una.")
	out.append("- El árbol tiene %d rangos en %d nodos. «Escala» multiplica todos los costes de `GameData.empire_tree()` (1 = valores del juego)." % [_tree_total(), tree_nodes.size()])
	out.append("- «Ganado vs sin árbol» compara el dinero total de 72 h con el mismo perfil sin árbol.\n")

	out.append("## 1. Escala de costes\n")
	out.append("| Escala | Perfil | 1.ª compra | Rangos 1 h | 4 h | 24 h | 72 h | Árbol completo | Gastado en el árbol | Ganado vs sin árbol |")
	out.append("|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|")
	var profiles := ["Activo", "Espaciado", "Sesiones"]
	var without := {}
	for name in profiles:
		without[name] = run(_params(name, {"renew": true, "found_save": 600.0, "tree": false}))
	for scale in TREE_SCALES:
		for name in profiles:
			var r := run(_params(name, {"renew": true, "found_save": 600.0, "tree_scale": scale}))
			out.append("| %s | %s | %s | %d | %d | %d | %d | %s | %s $ (%s) | %+.0f %% |" % [_ratio(scale), name, _t(r.t_tree_first),
					r.snap[0].tree, r.snap[1].tree, r.snap[3].tree, r.snap[4].tree, _t(r.t_tree_full),
					_m(r.tree_spent), _pct(r.tree_spent / r.earned), (r.earned / without[name].earned - 1.0) * 100.0])

	out.append("\n## 2. Ritmo con los costes del juego (escala 1)\n")
	out.append("Momento en que se compra el primer y el último rango de cada nodo (— = no llega en 72 h).\n")
	var detail := {}
	for name in ["Activo", "Espaciado"]:
		detail[name] = run(_params(name, {"renew": true, "found_save": 600.0}))
	out.append("| Rama | Nodo | Rangos | Coste del 1.er rango | Activo: primero / último | Espaciado: primero / último |")
	out.append("|---|---|---:|---:|---:|---:|")
	for node in tree_nodes:
		var cells: PackedStringArray = []
		for name in ["Activo", "Espaciado"]:
			var first := NEVER
			var last := NEVER
			var count := 0
			for entry: String in detail[name].tree_order:
				var parts := entry.split("@")
				if parts[0] == node.id:
					count += 1
					if count == 1:
						first = _parse_time(parts[1])
					if count == int(node.max):
						last = _parse_time(parts[1])
			cells.append("%s / %s" % [_t(first), _t(last)])
		out.append("| %s | %s | %d | %s $ | %s | %s |" % [node.branch, node.name, node.max, _m(node.cost), cells[0], cells[1]])
	var slow := run(_params("Activo", {"renew": true, "found_save": 600.0, "tree_patience": 3.0}))
	out.append("\nSi el bot Activo prioriza el árbol (lo compra aunque puntúe hasta 3 veces peor que la mejor compra de una ciudad): %d rangos a las 24 h, %d a las 72 h, ganado %+.0f %% frente a sin árbol.\n" % [
			slow.snap[3].tree, slow.snap[4].tree, (slow.earned / without["Activo"].earned - 1.0) * 100.0])

	out.append("## 3. Producción con el juego cerrado\n")
	out.append("Perfil Sesiones (dos sesiones de 1 h al día) cerrando el juego entre sesiones con distintas reglas offline, frente a dejarlo abierto como widget (100 %, monedas solo durante las sesiones). «Cerrar / widget» = ganado cerrando ÷ ganado con widget.\n")
	var widget := run(_params("Sesiones+widget", {"renew": true, "found_save": 600.0}))
	out.append("Widget abierto: ganado 72 h %s $, $/s final %s, %d rangos del árbol.\n" % [_m(widget.earned), _m(widget.snap[4].ips), widget.snap[4].tree])
	out.append("| Regla offline | Ganado 72 h | Cerrar / widget | Parte offline | $/s 72 h | Rangos del árbol 72 h | Ciudades 72 h |")
	out.append("|---|---:|---:|---:|---:|---:|---:|")
	for variant: Dictionary in OFFLINE_VARIANTS:
		var params := _params("Sesiones", {"renew": true, "found_save": 600.0})
		params.merge(variant, true)
		params.erase("name")
		var r := run(params)
		out.append("| %s | %s $ | %s | %s | %s | %d | %d |" % [variant.name, _m(r.earned), _pct(r.earned / widget.earned),
				_pct(r.offline / r.earned), _m(r.snap[4].ips), r.snap[4].tree, r.snap[4].cities])
	out.append("")
	return "\n".join(out)


func _parse_time(text: String) -> float:
	if text.ends_with(" h"):
		return text.trim_suffix(" h").to_float() * H
	if text.ends_with(" min"):
		return text.trim_suffix(" min").to_float() * 60.0
	return text.trim_suffix(" s").to_float()


func _scope(scope: String) -> String:
	return "Imperio" if scope == "empire" else "Ciudad"


func _ratio(value: float) -> String:
	return "%.1f" % value if value < 1000.0 else _m(value)


# --- Simulación --------------------------------------------------------------------

func run(params: Dictionary) -> Dictionary:
	p = params
	prof = PROFILES[p.profile]
	t = 0.0
	rep = 0
	chips = 0
	golden = 0.0
	owned = {}
	coin_progress = 0.0
	focus = 0
	tree = {}
	tree_check_at = 0.0
	tree_goal = -1.0
	cities.clear()
	cities.append(_new_city())
	m = {"earned": 0.0, "build": 0.0, "click": 0.0, "coin": 0.0, "offline": 0.0,
		"first": [NEVER, NEVER, NEVER, NEVER, NEVER], "purchases": {}, "building_buys": 0,
		"latest_buys": 0, "t_second_city": NEVER, "t_first_renew": NEVER, "renewals": 0,
		"steps": 0, "foundings": [], "found_paybacks": [], "watch": [], "recoveries": [], "snap": [], "rep": 0,
		"t_tree_first": NEVER, "t_tree_full": NEVER, "tree_order": [], "tree_spent": 0.0}
	var next_snap := 0
	while t < HORIZON - 1e-6:
		present = _is_present(t)
		if present:
			_decide()
		var dt := minf(_next_boundary(t), SNAPSHOTS[next_snap]) - t
		if present:
			dt = minf(dt, MAX_PRESENT_STEP)
			var cash := 0.0
			var total_rate := 0.0
			for c in cities:
				var rate := _rate(c)
				cash += c.dollars
				total_rate += rate
				if c.target > c.dollars and rate > 0.0:
					dt = minf(dt, (c.target - c.dollars) / rate)
			if tree_goal > cash and total_rate > 0.0:
				dt = minf(dt, (tree_goal - cash) / total_rate)
		dt = maxf(dt, MIN_STEP)
		_advance(dt)
		m.steps += 1
		t += dt
		_track()
		while next_snap < SNAPSHOTS.size() and t >= SNAPSHOTS[next_snap] - 1e-6:
			var total_ips := 0.0
			for c in cities:
				total_ips += _ips(c.counts, c.upg)
			var best_levels := 0
			for c in cities:
				best_levels = maxi(best_levels, Array(c.upg).reduce(func(a, b): return a + b, 0))
			m.snap.append({"ips": total_ips, "cities": cities.size(), "levels": best_levels, "tree": _tree_bought()})
			next_snap += 1
		if next_snap >= SNAPSHOTS.size():
			break
	m.rep = rep
	return m


func _new_city() -> Dictionary:
	var c := {"counts": PackedInt32Array([0, 0, 0, 0, 0]), "upg": PackedInt32Array([0, 0, 0, 0, 0]),
		"dollars": 0.0, "total": 0.0, "lifetime": 0.0, "claimed": 0, "ink": 0, "boost": 0,
		"target": -1.0, "saving": false, "claimed_life": 0.0}
	_apply_start_bonus(c)
	return c


func _apply_start_bonus(c: Dictionary) -> void:
	c.dollars = 1000.0 if owned.has("seed_money") else 0.0
	if owned.has("head_start"):
		c.counts[0] = 5


func _is_present(time: float) -> bool:
	return prof.every <= 0.0 or fmod(time, prof.every) < prof.len


func _next_boundary(time: float) -> float:
	if prof.every <= 0.0:
		return INF
	var phase := fmod(time, prof.every)
	var start := time - phase
	if phase < prof.len:
		return start + prof.len
	if prof.closed and phase < prof.len + p.offline_cap:
		return minf(start + prof.len + p.offline_cap, start + prof.every)
	return start + prof.every


## Eficiencia de la producción automática ahora mismo (offline del juego si está cerrado).
## Night Owl suma lo mismo que en el juego (75 % frente a 50 %).
func _efficiency() -> float:
	if present or not prof.closed:
		return 1.0
	var away: float = fmod(t, prof.every) - prof.len
	if away >= p.offline_cap or p.offline_eff <= 0.0:
		return 0.0
	var bonus := Game.OFFLINE_EFFICIENCY_UPGRADED - Game.OFFLINE_EFFICIENCY if owned.has("night_owl") else 0.0
	return minf(1.0, p.offline_eff + bonus)


# --- Árbol del imperio -------------------------------------------------------------

func _tr(id: String) -> int:
	return tree.get(id, 0)


## Efecto acumulado de un nodo (per × rango).
func _tree_effect(id: String) -> float:
	for node in tree_nodes:
		if node.id == id:
			return float(node.per) * _tr(id)
	return 0.0


func _tree_bought() -> int:
	var total := 0
	for id in tree:
		total += tree[id]
	return total


func _tree_total() -> int:
	var total := 0
	for node in tree_nodes:
		total += int(node.max)
	return total


## $/s esperados del imperio con el jugador presente: edificios, clics y monedas de la ciudad mirada.
func _empire_value() -> float:
	var total := 0.0
	for c in cities:
		total += _value(c.counts, c.upg, c.ink, c.boost, _clicking(c))
	if p.coins:
		total += _coins_per_second() * _coin_ev(cities[focus])
	return total


## Rango del árbol con mejor `espera + coste / aumento de $/s`, comparable con las compras de
## las ciudades. Los nodos sin efecto directo en $/s cuentan como TREE_UTILITY × valor del imperio.
func _best_tree_rank(cash: float, empire_rate: float) -> Dictionary:
	var best := {}
	var before := _empire_value()
	for node in tree_nodes:
		var rank := _tr(node.id)
		if rank >= int(node.max) or (node.requires != "" and _tr(node.requires) < 1) or node.id in p.tree_off:
			continue
		var cost := GameData.tree_cost(node, rank, p.tree_scale)
		var gain := 0.0
		if TREE_UTILITY.has(node.id):
			gain = before * TREE_UTILITY[node.id]
		else:
			tree[node.id] = rank + 1
			gain = _empire_value() - before
			tree[node.id] = rank
		if gain <= 0.0:
			continue
		var wait := maxf(0.0, cost - cash) / empire_rate if empire_rate > 0.0 else INF
		var score := wait + cost / gain
		if best.is_empty() or score < best.score:
			best = {"id": node.id, "cost": cost, "score": score}
	return best


## Paga con el dinero de todas las ciudades, en proporción a lo que tiene cada una (como el juego).
## El bot ahorra para el árbol solo si su mejor rango rinde más que la mejor compra de cualquier ciudad.
func _consider_tree() -> bool:
	if not p.tree:
		return false
	# Mientras ahorra solo comprueba si ya llega; si no, reevalúa como mucho cada TREE_CHECK s.
	if tree_goal > 0.0:
		var saved := 0.0
		for c in cities:
			saved += c.dollars
		if saved < tree_goal:
			return false
	elif t < tree_check_at:
		return false
	tree_goal = -1.0
	tree_check_at = t + TREE_CHECK
	var bought := false
	for guard in 100:
		var cash := 0.0
		var empire_rate := 0.0
		for c in cities:
			cash += c.dollars
			empire_rate += _rate(c)
		var next := _best_tree_rank(cash, empire_rate)
		if next.is_empty():
			return bought
		var city_score := INF
		for c in cities:
			var option := _best_purchase(c)
			if not option.is_empty():
				city_score = minf(city_score, option.score)
		if next.score > city_score * p.tree_patience:
			return bought
		if cash < next.cost:
			tree_goal = next.cost
			return bought
		var fraction: float = next.cost / cash
		for c in cities:
			c.dollars -= c.dollars * fraction
		tree[next.id] = _tr(next.id) + 1
		m.tree_spent += next.cost
		m.tree_order.append("%s@%s" % [next.id, _t(t)])
		if m.t_tree_first == NEVER:
			m.t_tree_first = t
		if _tree_bought() == _tree_total():
			m.t_tree_full = t
		bought = true
	return bought


# --- Economía (misma fórmula que game.gd) -----------------------------------------

func _milestone_level(amount: int) -> int:
	var level := 0
	for threshold in ShopButton.MILESTONES:
		if amount >= threshold:
			level += 1
	if amount >= 100:
		level += floori(amount / 50.0) - 1
	return level


func _next_milestone(amount: int) -> int:
	for threshold in ShopButton.MILESTONES:
		if amount < threshold:
			return threshold
	return (floori(amount / 50.0) + 1) * 50


func _mult() -> float:
	var rep_bonus: float = p.rep_bonus + _tree_effect("empire_hq")
	var rep_factor: float = 1.0 + rep_bonus * (sqrt(float(rep)) if p.rep_model == "sqrt" else float(rep))
	var coin_factor: float = p.coin_bonus * golden
	if p.coin_cap >= 0.0:
		coin_factor = minf(coin_factor, p.coin_cap + _tree_effect("golden_vault"))
	var tree_factor := (1.0 + _tree_effect("trade_network")) * (1.0 + _tree_effect("global_brand"))
	if present or not prof.closed:
		tree_factor *= 1.0 + _tree_effect("open_all_night")
	return (1.0 + coin_factor) * rep_factor * tree_factor


func _reputation_for(earned: float) -> int:
	return floori(pow(maxf(earned, 0.0) / p.prest_div, 1.0 / p.prest_root) + 1e-9)


func _ips(counts: PackedInt32Array, upg: PackedInt32Array) -> float:
	var total := 0.0
	var synergy_boost := 1.0 + _tree_effect("supply_chains")
	for i in counts.size():
		if counts[i] == 0:
			continue
		var syn := 1.0
		if i + 1 < counts.size():
			syn += synergy[i] * counts[i + 1] * synergy_boost
		total += base_income[i] * counts[i] * pow(2.0, _milestone_level(counts[i]) + upg[i]) * syn
	return total * _mult()


func _click_rate(ink: int, boost: int, ips: float) -> float:
	var cps: float = prof.cps
	var combo := GameData.COMBO_MAX + _tree_effect("ergonomics") if cps >= 1.0 / Game.COMBO_WINDOW else 1.0
	var press := pow(2.0, _tr("printing_press"))
	return cps * combo * (pow(2.0, ink) * press * _mult() + ips * Game.BOOST_PER_LEVEL * boost)


func _clicking(c: Dictionary) -> bool:
	return present and prof.cps > 0.0 and cities.find(c) == focus


func _rate(c: Dictionary) -> float:
	var ips := _ips(c.counts, c.upg)
	return ips * _efficiency() + (_click_rate(c.ink, c.boost, ips) if _clicking(c) else 0.0)


func _unlocked(c: Dictionary, i: int) -> bool:
	return c.counts[i] > 0 or c.total >= base_cost[i] * ShopButton.REVEAL_FRACTION


func _earn(c: Dictionary, amount: float, source: String) -> void:
	c.dollars += amount
	c.total += amount
	c.lifetime += amount
	m.earned += amount
	m[source] += amount


func _advance(dt: float) -> void:
	var eff := _efficiency()
	for c in cities:
		var ips := _ips(c.counts, c.upg)
		_earn(c, ips * eff * dt, "offline" if prof.closed and not present else "build")
		if _clicking(c):
			_earn(c, _click_rate(c.ink, c.boost, ips) * dt, "click")
	if present and p.coins:
		coin_progress += dt * _coins_per_second()
		while coin_progress >= 1.0:
			coin_progress -= 1.0
			_collect_coin(cities[focus])


## Monedas especiales por segundo con el jugador presente (Lucky Press: cada clic puede soltar una).
func _coins_per_second() -> float:
	var interval := (Game.GOLDEN_DELAY.x + Game.GOLDEN_DELAY.y) / 2.0
	if owned.has("lucky_charm"):
		interval *= 0.7
	interval /= 1.0 + _tree_effect("lucky_streets")
	return 1.0 / interval + prof.cps * _tree_effect("lucky_press")


func _collect_coin(c: Dictionary) -> void:
	_earn(c, _coin_ev(c), "coin")
	c.dollars -= Game.RED_CHANCE * 0.5 * Game.RED_LOSS * c.dollars
	golden += (1.0 - Game.RED_CHANCE) * (0.9 + 0.1 * chain_links)


## Valor esperado de una moneda especial en la ciudad c.
func _coin_ev(c: Dictionary) -> float:
	var stretch := (1.5 if owned.has("golden_age") else 1.0) * (1.0 + _tree_effect("long_party"))
	var ips := _ips(c.counts, c.upg)
	var clicks := _click_rate(c.ink, c.boost if p.frenzy_boost else 0, ips) if prof.cps > 0.0 else 0.0
	var midas := _tree_effect("midas_odds")
	var gold := ips * ((0.4 - midas) * Game.LUCKY_SECONDS + (0.35 + midas) * (Game.FRENZY_MULTIPLIER - 1.0) * Game.FRENZY_TIME * stretch
			+ 0.1 * chain_seconds) + 0.15 * clicks * (Game.CLICK_FRENZY_MULTIPLIER - 1.0) * Game.CLICK_FRENZY_TIME * stretch
	var red := 0.5 * ips * Game.RED_JACKPOT_SECONDS
	return (1.0 - Game.RED_CHANCE) * gold + Game.RED_CHANCE * red


# --- Decisiones del jugador --------------------------------------------------------

func _decide() -> void:
	var previous_focus := focus
	var previous_rep := rep
	var previous_cities := cities.size()
	_choose_focus()
	_consider_renewal()
	_consider_founding()
	var bought_tree := _consider_tree()
	# Solo se recalcula la mejor compra cuando cambia el contexto o ya se puede pagar el objetivo.
	var dirty := focus != previous_focus or rep != previous_rep or cities.size() != previous_cities or bought_tree
	for c in cities:
		if tree_goal > 0.0:
			c.target = -1.0  # todas las ciudades ahorran para el árbol
		elif c.saving:
			c.target = _found_cost()
		elif dirty or c.target < 0.0 or c.dollars >= c.target:
			_shop(c)


func _choose_focus() -> void:
	var best := 0
	var best_ips := -1.0
	for i in cities.size():
		var ips := _ips(cities[i].counts, cities[i].upg)
		if ips > best_ips:
			best_ips = ips
			best = i
	var newest := cities.size() - 1
	focus = newest if _ips(cities[newest].counts, cities[newest].upg) < 0.1 * best_ips else best


func _shop(c: Dictionary) -> void:
	for guard in 2000:
		var best := _best_purchase(c)
		if best.is_empty():
			c.target = -1.0
			return
		if best.cost > c.dollars:
			c.target = best.cost
			return
		_buy(c, best)


func _best_purchase(c: Dictionary) -> Dictionary:
	var clicking := _clicking(c)
	var ips := _ips(c.counts, c.upg)
	var before := ips + (_click_rate(c.ink, c.boost, ips) if clicking else 0.0)
	var rate := ips * _efficiency() + (before - ips)
	var best := {}
	var best_score := INF
	var options: Array[Dictionary] = []
	for i in base_cost.size():
		if not _unlocked(c, i):
			continue
		var first := base_cost[i] * pow(ShopButton.COST_GROWTH, c.counts[i])
		var to_milestone: int = _next_milestone(c.counts[i]) - c.counts[i]
		for quantity in ([1, to_milestone] if to_milestone > 1 else [1]):
			var counts: PackedInt32Array = c.counts.duplicate()
			counts[i] += quantity
			var cost := first * (pow(ShopButton.COST_GROWTH, quantity) - 1.0) / (ShopButton.COST_GROWTH - 1.0)
			options.append({"kind": "building", "index": i, "qty": quantity, "cost": cost,
				"after": _value(counts, c.upg, c.ink, c.boost, clicking)})
		if c.upg[i] < ShopButton.MAX_LEVEL and c.counts[i] >= ShopButton.LEVEL_REQUIREMENTS[c.upg[i]]:
			var upg: PackedInt32Array = c.upg.duplicate()
			upg[i] += 1
			options.append({"kind": "upgrade", "index": i, "cost": base_cost[i] * p.level_base * pow(p.level_growth, c.upg[i]),
				"after": _value(c.counts, upg, c.ink, c.boost, clicking)})
			options[-1].cost *= 1.0 - _tree_effect("franchising")
	if clicking:
		options.append({"kind": "ink", "cost": Game.INK_BASE_COST * pow(Game.INK_GROWTH, c.ink),
			"after": _value(c.counts, c.upg, c.ink + 1, c.boost, true)})
		options.append({"kind": "boost", "cost": Game.BOOST_BASE_COST * pow(Game.BOOST_GROWTH, c.boost),
			"after": _value(c.counts, c.upg, c.ink, c.boost + 1, true)})
	for option in options:
		var gain: float = option.after - before
		if gain <= 1e-12:
			continue
		var wait := 0.0
		if option.cost > c.dollars:
			wait = (option.cost - c.dollars) / rate if rate > 0.0 else INF
		var score: float = wait + option.cost / gain
		if score < best_score:
			best_score = score
			best = option
			best.score = score
	return best


func _value(counts: PackedInt32Array, upg: PackedInt32Array, ink: int, boost: int, clicking: bool) -> float:
	var ips := _ips(counts, upg)
	return ips + (_click_rate(ink, boost, ips) if clicking else 0.0)


func _buy(c: Dictionary, option: Dictionary) -> void:
	c.dollars -= option.cost
	m.purchases[option.kind] = m.purchases.get(option.kind, 0) + 1
	match option.kind:
		"building":
			var i: int = option.index
			var highest := 0
			for j in base_cost.size():
				if _unlocked(c, j):
					highest = j
			m.building_buys += 1
			if i == highest:
				m.latest_buys += 1
			c.counts[i] += option.qty
			if m.first[i] == NEVER:
				m.first[i] = t
		"upgrade":
			c.upg[option.index] += 1
		"ink":
			c.ink += 1
		"boost":
			c.boost += 1


func _found_cost() -> float:
	return roundf(p.found_base * pow(p.found_growth, cities.size() - 1) * (1.0 - _tree_effect("real_estate")))


func _consider_founding() -> void:
	for c in cities:
		if c.saving:
			c.target = -1.0
		c.saving = false
	if p.found_save <= 0.0:
		return
	var payer: Dictionary = cities[0]
	for c in cities:
		if _ips(c.counts, c.upg) > _ips(payer.counts, payer.upg):
			payer = c
	var cost := _found_cost()
	if cost > _ips(payer.counts, payer.upg) * p.found_save:
		return
	if payer.dollars < cost:
		payer.saving = true
		return
	payer.dollars -= cost
	cities.append(_new_city())
	m.foundings.append({"t": t, "cost": cost, "city": cities[-1]})
	if cities.size() == 2:
		m.t_second_city = t


## Reputación que daría renovar la ciudad c.
## city: raíz propia de la ciudad menos lo que ya reclamó.
## empire: raíz de lo ganado por todo el imperio menos la reputación ya cobrada, repartida
## según lo que cada ciudad ha ganado desde su última renovación.
func _pending(c: Dictionary) -> int:
	if p.rep_scope == "city":
		return _reputation_for(c.lifetime) - c.claimed
	var total := 0.0
	var unclaimed := 0.0
	for city in cities:
		total += city.lifetime
		unclaimed += city.lifetime - city.claimed_life
	if unclaimed <= 0.0:
		return 0
	var open := maxi(0, _reputation_for(total) - rep)
	return floori(open * (c.lifetime - c.claimed_life) / unclaimed + 1e-9)


func _consider_renewal() -> void:
	if not p.renew:
		return
	var best: Dictionary = {}
	var best_pending := 0
	for c in cities:
		var pending := _pending(c)
		if pending > best_pending:
			best_pending = pending
			best = c
	if best.is_empty() or best_pending < maxi(1, rep):
		return
	m.watch.append({"city": best, "pre": _ips(best.counts, best.upg), "t": t})
	rep += best_pending
	chips += best_pending
	best.claimed += best_pending
	best.claimed_life = best.lifetime
	best.counts = PackedInt32Array([0, 0, 0, 0, 0])
	# Heritage conserva hasta `rango` niveles de cada edificio.
	var keep := _tr("heritage")
	for i in best.upg.size():
		best.upg[i] = mini(best.upg[i], keep)
	best.ink = 0
	best.boost = 0
	best.total = 0.0
	best.target = -1.0
	m.renewals += 1
	if m.t_first_renew == NEVER:
		m.t_first_renew = t
	for u in rep_upgrades:
		if not owned.has(u.id) and chips >= u.cost:
			chips -= u.cost
			owned[u.id] = true
	_apply_start_bonus(best)


## Registra recuperaciones tras renovar y amortización de cada fundación.
func _track() -> void:
	var still: Array = []
	for w: Dictionary in m.watch:
		if _ips(w.city.counts, w.city.upg) >= w.pre:
			m.recoveries.append(t - w.t)
		else:
			still.append(w)
	m.watch = still
	for f: Dictionary in m.foundings:
		if not f.has("paid") and f.city.lifetime >= f.cost:
			f.paid = true
			m.found_paybacks.append(t - f.t)


# --- Formato -----------------------------------------------------------------------

func _median(values: Array) -> float:
	if values.is_empty():
		return NEVER
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _t(seconds: float) -> String:
	if seconds < 0.0:
		return "—"
	if seconds < 60.0:
		return "%d s" % roundi(seconds)
	if seconds < H:
		return "%d min" % roundi(seconds / 60.0)
	return "%.1f h" % (seconds / H)


func _m(value: float) -> String:
	return Fmt.money(value)


func _pct(value: float) -> String:
	return "%d %%" % roundi(value * 100.0)


func _purchases(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	for kind in r.purchases:
		parts.append("%s %d" % [kind, r.purchases[kind]])
	return ", ".join(parts)
