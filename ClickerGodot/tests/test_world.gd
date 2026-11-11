extends SceneTree

var game: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.use_save = false
	game.save_path = "user://widget_world_test.cfg"
	root.add_child(game)
	game.set_process(false)
	game.buttons[0].count = 2
	game.dollars = 123.0
	game.total_earned = 500.0
	game.ink_level = 2
	game.buttons[0].timer = 0.4
	game.add_modifier(GameData.TARGET_ALL, 7.0, 2.0, "Test frenzy")
	game.schedule_payout(3.0, 20.0, "Test investor")
	# Fundar cuesta dinero de la ciudad seleccionada; sin saldo no cobra nada.
	check(game.found_cost() == 250000.0, "Second city costs the base price")
	check(not game.found_city(), "Founding requires money")
	check(game.city_states.size() == 1 and game.dollars == 123.0, "Failed founding charges nothing")
	game.dollars = 250123.0
	check(game.found_city(), "Founding with enough money succeeds")
	check(game.city_states[0].dollars == 123.0, "Founding charges exactly the price to the paying city")
	check(game.found_cost() == 2000000.0, "Next city price grows with existing cities")
	check(game.city_states.size() == 2 and game.active_city == 1, "Creates independent city")
	check(game.dollars == 0.0 and game.buttons[0].count == 0, "New city has its own economy")
	game._advance_other_cities(5.0)
	# 2 bars = 3/s: 2 seconds x7 + 3 seconds x1 + 20 delayed payout.
	check(is_equal_approx(game.city_states[0].dollars, 194.0), "Background income integrates expiring bonus and investor")
	game.change_city(-1)
	check(game.dollars == 194.0 and game.ink_level == 2, "Switch restores cash and upgrades")
	check(game.buttons[0].count == 2 and is_equal_approx(game.buttons[0].timer, 0.4), "Switch restores buildings and payout phase")
	check(game.modifiers.is_empty() and game.payouts.is_empty(), "Expired effects do not return on switch")
	game.change_city(-1)
	check(game.active_city == 1, "Arrows wrap around")
	check(game.found_cost() == 2000000.0, "Navigating does not change the founding price")
	game.menu.open()
	game.change_city(1)
	game.dollars = 3e6
	game.found_city()
	check(game.active_city == 1 and game.city_states.size() == 2 and game.dollars == 3e6, "Cannot switch with modal menu open")
	game.dollars = 0.0
	game.menu.close()
	game.hud.show_event("Test", "Test", "A", "B", func(_choice): pass)
	game.change_city(1)
	check(game.active_city == 1, "Cannot move an unresolved event to another city")
	game.hud.get_node("EventDialog").hide()
	# Reputación de imperio: ∛(ganado por todas las ciudades / 10M), repartida según lo que
	# cada ciudad ganó desde su última renovación.
	check(game.reputation_for(8e7) == 2 and game.reputation_for(7.9e7) == 1, "Reputation uses a cube root over 10M")
	game.city_states[0].lifetime = 8e7
	game.city_states[0].claimed_life = 0.0
	check(game.empire_pending_reputation() == 2, "Empire reputation counts every city")
	check(game.pending_reputation() == 0, "Empty city cannot claim reputation earned elsewhere")
	game.city_lifetime = 8e7
	check(game.empire_pending_reputation() == 2 and game.pending_reputation() == 1, "Founding does not add a new root; renewal claims its share")
	game.buttons[0].count = 1
	game.prestige()
	check(game.prestige_points == 1 and game.buttons[0].count == 0, "Prestige resets current city")
	check(game.renewals == 1 and game.city_claimed_life == 8e7 and game.pending_reputation() == 0, "Prestige records claimed earnings")
	check(game.empire_pending_reputation() == 1 and is_equal_approx(game.city_share(), 0.0), "Remaining reputation belongs to the other city")
	check(game.city_lifetime == 8e7 and game.city_states.size() == 2, "Prestige keeps city history and city count")
	check(game.city_states[0].buildings[0].count == 2, "Prestige preserves other cities")
	check(is_equal_approx(game.reputation_speedup(10), 10.0 / 101.0), "Reputation speedup is relative")
	# Monedas: bonus permanente con tope y Click Frenzy sin Golden Touch.
	game.golden_coins = 100
	check(is_equal_approx(game.golden_bonus(), game.GOLDEN_BONUS_CAP), "Golden coin bonus is capped")
	game.golden_coins = 0
	game.buttons[0].count = 10
	game.boost_level = 1
	game.combo = 1.0
	game.add_modifier(GameData.TARGET_CLICK, 777.0, 10.0, "Click x777")
	var expected_click: float = 777.0 * game.global_multiplier() + game.income_per_second() * game.BOOST_PER_LEVEL
	check(is_equal_approx(game.click_value(), expected_click), "Click Frenzy multiplies only the base click")
	game.modifiers.clear()
	game.boost_level = 0
	game.buttons[0].count = 0
	# Compras múltiples.
	var bar: ShopButton = game.buttons[0]
	check(is_equal_approx(bar.cost_of(3), 15.0 + 17.25 + 19.8375), "Bulk cost is a geometric series")
	check(bar.affordable_count(52.0875) == 3 and bar.affordable_count(52.08) == 2, "Affordable count respects exact balance")
	check(is_equal_approx(game.purchase_gain(0, 1), 1.5 * game.global_multiplier()), "Marginal gain recomputes income")
	game.buy_mode = game.BUY_MODES.find(game.BUY_NEXT_MILESTONE)
	check(game.purchase_quantity(bar) == 10, "Buy-to-milestone quantity")
	game.buy_mode = game.BUY_MODES.find(game.BUY_MAX)
	game.dollars = 60.0
	game.total_earned = 60.0
	game._on_shop_button_pressed(bar)
	check(bar.count == 3 and is_equal_approx(game.dollars, 60.0 - 52.0875), "Buy max spends the right amount")
	game.buy_mode = 0
	bar.count = 0
	# Niveles de edificio: requisito de cantidad, coste creciente y "subir todo" sin compras parciales.
	var factory: ShopButton = game.buttons[1]
	game.total_earned = 1e6
	bar.count = 1
	check(is_equal_approx(bar.next_level_cost(), 15.0 * ShopButton.LEVEL_COST_BASE), "First level cost")
	game.dollars = bar.next_level_cost() - 1.0
	check(not game.level_up(0), "Level up needs enough money")
	game.dollars = bar.next_level_cost()
	check(game.level_up(0) and bar.level == 1 and game.dollars == 0.0, "Level up charges exactly its cost")
	check(not bar.level_ready() and bar.next_level_requirement() == 10, "Next level needs more buildings")
	bar.count = 10
	factory.count = 1
	var all_cost := bar.next_level_cost() + factory.next_level_cost()
	check(game.levels_ready() == [0, 1] and is_equal_approx(game.level_all_cost(), all_cost), "Level-all cost sums every ready building")
	game.dollars = all_cost - 1.0
	check(not game.level_up_all() and bar.level == 1 and factory.level == 0, "Level-all never buys partially")
	game.dollars = all_cost
	check(game.level_up_all() and bar.level == 2 and factory.level == 1 and is_equal_approx(game.dollars, 0.0), "Level-all levels every ready building")
	check(is_equal_approx(bar.income(1.0), 1.5 * 10 * pow(2.0, 1 + 2)), "Each level doubles income")
	bar.level = ShopButton.MAX_LEVEL
	check(bar.is_max_level() and not bar.level_ready(), "Level 10 is the maximum")
	bar.level = 0
	bar.count = 0
	factory.count = 0
	game.dollars = 0.0
	game.total_earned = 0.0
	# Árbol del imperio: se paga con el dinero de todas las ciudades, en proporción a lo que tiene cada una.
	var other: int = 1 - game.active_city
	var other_cash: float = game.city_states[other].dollars
	game.dollars = 3e5
	game.city_states[other].dollars = 7e5
	check(is_equal_approx(game.empire_cash(), 1e6), "Treasury adds the cash of every city")
	check(game.tree_cost("trade_network") == 1e6, "First empire tree rank costs 1M")
	check(not game.can_buy_tree("supply_chains"), "Tree nodes need the previous node")
	var mult_before: float = game.permanent_multiplier()
	check(game.buy_tree("trade_network"), "Tree rank bought with pooled money")
	check(is_zero_approx(game.dollars) and is_zero_approx(game.city_states[other].dollars), "Every city pays its share")
	check(is_equal_approx(game.permanent_multiplier(), mult_before * 1.04), "Trade Network raises income")
	game.dollars = 12e6
	game.city_states[other].dollars = 4e6
	check(game.buy_tree("trade_network") and is_equal_approx(game.dollars, 6e6) and is_equal_approx(game.city_states[other].dollars, 2e6),
			"Cities pay in proportion to their cash")
	check(not game.buy_tree("supply_chains"), "Tree purchase needs enough money in the empire")
	game.empire_tree["open_all_night"] = 1
	check(is_equal_approx(game.permanent_multiplier(true) / game.permanent_multiplier(false), 1.1), "Open All Night only counts while the game is open")
	game.empire_tree["franchising"] = 2
	game.empire_tree["real_estate"] = 1
	game._apply_tree()
	bar.count = 1
	check(is_equal_approx(bar.next_level_cost(), 15.0 * ShopButton.LEVEL_COST_BASE * 0.8), "Franchising discounts levels")
	check(game.found_cost() == 1700000.0, "Real Estate discounts founding")
	bar.level = 3
	game._reset_city(1)
	check(bar.level == 1 and bar.count == 0, "Heritage keeps levels when renewing")
	bar.level = 0
	game.empire_tree.erase("open_all_night")
	game.empire_tree.erase("franchising")
	game.empire_tree.erase("real_estate")
	game._apply_tree()
	game.dollars = 0.0
	game.city_states[other].dollars = other_cash
	game.save_game()
	var cfg := ConfigFile.new()
	check(cfg.load(game.save_path) == OK, "Save succeeds")
	check(cfg.get_value("game", "version") == 5, "Save schema upgraded")
	check(cfg.get_value("progress", "renewals") == 1, "Renewals saved under their own name")
	game.city_states.clear()
	game.active_city = 0
	game.load_game()
	check(game.city_states.size() == 2 and game.active_city == 1, "Save reload preserves cities and selection")
	check(game.buttons[1].level == 1, "Save reload preserves building levels")
	game.change_city(-1)
	check(game.buttons[0].count == 2 and game.ink_level == 2, "Save reload preserves independent economy")
	check(game.city_states[1].claimed_life == 8e7 and game.city_states[1].lifetime == 8e7, "Save reload preserves reputation tracks")
	check(game.found_cost() == 2000000.0, "Save reload preserves founding price")
	check(game.tree_rank("trade_network") == 2 and is_equal_approx(ShopButton.level_discount, 1.0), "Save reload preserves the empire tree")
	game.empire_tree.clear()
	# La producción sin conexión incluye la reputación compartida y se reparte al 50 %.
	game.city_states[1].buildings[0].count = 1
	game.save_game()
	var offline_cfg := ConfigFile.new()
	offline_cfg.load(game.save_path)
	offline_cfg.set_value("game", "saved_at", Time.get_unix_time_from_system() - 120.0)
	offline_cfg.save(game.save_path)
	game.load_game()
	check(absf(game.dollars - 375.8) < 0.1, "Offline income restores active city")
	check(absf(game.city_states[1].dollars - 90.9) < 0.1, "Offline income restores background city")
	game.hud.get_node("WelcomeDialog").hide()
	# Legado v2: el estado anterior se convierte en la primera ciudad sin pérdida.
	var legacy := ConfigFile.new()
	legacy.set_value("game", "version", 2)
	legacy.set_value("city", "dollars", 456.0)
	legacy.set_value("city", "total_earned", 1000.0)
	legacy.set_value("buildings", "ButtonBar", 4)
	legacy.set_value("progress", "cities", 3)
	legacy.save("user://widget_legacy_test.cfg")
	var migrated: Node = load("res://scenes/main.tscn").instantiate()
	migrated.save_path = "user://widget_legacy_test.cfg"
	root.add_child(migrated)
	migrated.set_process(false)
	check(migrated.city_states.size() == 1 and migrated.dollars == 456.0, "Legacy save migrates to one city")
	check(migrated.buttons[0].count == 4 and migrated.renewals == 3, "Migration keeps buildings and prestige history")
	migrated.use_save = false
	migrated.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://widget_legacy_test.cfg"))
	# Legado v3: la Reputación global ya cobrada no se puede volver a reclamar desde otra ciudad.
	var v3 := ConfigFile.new()
	v3.set_value("game", "version", 3)
	v3.set_value("progress", "prestige_points", 5)
	v3.set_value("progress", "lifetime_earned", 4e6)
	v3.set_value("progress", "cities", 2)
	v3.set_value("world", "active_city", 0)
	v3.set_value("world", "cities", [{"dollars": 10.0, "total_earned": 1e6, "buildings": [{"count": 3, "upgrades": 2}]},
			{"dollars": 20.0, "total_earned": 2e6, "buildings": []}])
	v3.save("user://widget_v3_test.cfg")
	var old_world: Node = load("res://scenes/main.tscn").instantiate()
	old_world.save_path = "user://widget_v3_test.cfg"
	root.add_child(old_world)
	old_world.set_process(false)
	check(old_world.renewals == 2 and old_world.city_states.size() == 2, "v3 migration keeps cities and renewals")
	check(old_world.city_lifetime == 2e6 and old_world.city_claimed_life == 2e6, "v3 migration assigns unattributed earnings without debt")
	check(old_world.city_states[1].claimed_life == 2e6 and old_world.prestige_points == 5, "v3 migration keeps points and marks old earnings as claimed")
	check(old_world.pending_reputation() == 0, "v3 migration grants no free reputation in the active city")
	check(old_world.buttons[0].level == 2, "Old building upgrades become levels")
	old_world.change_city(1)
	check(old_world.pending_reputation() == 0 and old_world.dollars == 20.0, "v3 migration grants no free reputation in other cities")
	old_world.use_save = false
	old_world.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://widget_v3_test.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await process_frame
	print("Widget/world checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
