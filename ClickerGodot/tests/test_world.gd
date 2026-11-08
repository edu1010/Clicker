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
	game.add_city()
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
	game.menu.open()
	game.change_city(1)
	game.add_city()
	check(game.active_city == 1 and game.city_states.size() == 2, "Cannot switch with modal menu open")
	game.menu.close()
	game.hud.show_event("Test", "Test", "A", "B", func(_choice): pass)
	game.change_city(1)
	check(game.active_city == 1, "Cannot move an unresolved event to another city")
	game.hud.get_node("EventDialog").hide()
	game.lifetime_earned = 100000.0
	game.buttons[0].count = 1
	game.prestige()
	check(game.prestige_points == 1 and game.buttons[0].count == 0, "Prestige resets current city")
	check(game.city_states[0].buildings[0].count == 2, "Prestige preserves other cities")
	game.save_game()
	var cfg := ConfigFile.new()
	check(cfg.load(game.save_path) == OK, "Save succeeds")
	check(cfg.get_value("game", "version") == 3, "Save schema upgraded")
	game.city_states.clear()
	game.active_city = 0
	game.load_game()
	check(game.city_states.size() == 2 and game.active_city == 1, "Save reload preserves cities and selection")
	game.change_city(-1)
	check(game.buttons[0].count == 2 and game.ink_level == 2, "Save reload preserves independent economy")
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
	check(migrated.buttons[0].count == 4 and migrated.cities == 3, "Migration keeps buildings and prestige history")
	migrated.use_save = false
	migrated.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://widget_legacy_test.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	game.queue_free()
	await process_frame
	print("Widget/world checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
