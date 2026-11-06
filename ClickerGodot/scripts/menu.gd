class_name GameMenu
extends Control
## Menú con pestañas: Upgrades, Reputation, Achievements, Stats y Options.
## Se construye por código a partir del estado del juego (game.gd).

const TABS := ["Upgrades", "Reputation", "Achievements", "Stats", "Options"]
const LIVE_INTERVAL := 0.25
const GOLD := Color(1.0, 0.85, 0.3)
const GREY := Color(0.6, 0.6, 0.6)

## Lo asigna game.gd en su _ready.
var game: Node

var _tabs: TabContainer
## Funciones que actualizan textos/estados mientras el menú está abierto.
var _live: Array[Callable] = []
var _live_timer := 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(PRESET_FULL_RECT)
	shade.gui_input.connect(_on_shade_input)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = Vector2(100, 40)
	panel.custom_minimum_size = Vector2(760, 560)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2b2e33")
	style.border_color = Color("404040")
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := _label(header, "MoneyClicker", 20)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var close_button := Button.new()
	close_button.text = "  Close  "
	close_button.focus_mode = FOCUS_NONE
	close_button.pressed.connect(close)
	header.add_child(close_button)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = SIZE_EXPAND_FILL
	vbox.add_child(_tabs)
	for tab_name in TABS:
		var scroll := ScrollContainer.new()
		scroll.name = tab_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 10)
		scroll.add_child(list)
		_tabs.add_child(scroll)
	_tabs.tab_changed.connect(func(_tab: int) -> void: rebuild())


func _process(delta: float) -> void:
	if not visible:
		return
	_live_timer += delta
	if _live_timer >= LIVE_INTERVAL:
		_live_timer = 0.0
		_update_live()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open(tab_name := "") -> void:
	visible = true
	if tab_name in TABS:
		_tabs.current_tab = TABS.find(tab_name)
	rebuild()


func close() -> void:
	visible = false


func current_tab_name() -> String:
	return TABS[_tabs.current_tab]


func rebuild() -> void:
	var list: VBoxContainer = _tabs.get_current_tab_control().get_child(0)
	for child in list.get_children():
		child.queue_free()
	_live.clear()
	match current_tab_name():
		"Upgrades": _build_upgrades(list)
		"Reputation": _build_reputation(list)
		"Achievements": _build_achievements(list)
		"Stats": _build_stats(list)
		"Options": _build_options(list)
	_update_live()


func _update_live() -> void:
	for update in _live:
		update.call()


# --- Pestañas ----------------------------------------------------------------------

func _build_upgrades(list: VBoxContainer) -> void:
	_label(list, "Each upgrade doubles that building's income. Buildings also boost the previous one (synergy).", 13, GREY)
	var any := false
	for i in game.buttons.size():
		var b: ShopButton = game.buttons[i]
		if not b.is_unlocked(game.total_earned):
			continue
		any = true
		var row := HBoxContainer.new()
		list.add_child(row)
		var info := _label(row, "", 13)
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var buy := _button(row, "Buy")
		buy.pressed.connect(func() -> void:
			game.buy_building_upgrade(i)
			rebuild())
		var update := func() -> void:
			info.text = _upgrade_text(i)
			buy.visible = b.has_more_upgrades()
			buy.disabled = not game.can_buy_building_upgrade(i)
		_live.append(update)
	if not any:
		_label(list, "Buy your first building to unlock upgrades.", 14)


func _upgrade_text(i: int) -> String:
	var b: ShopButton = game.buttons[i]
	var lines: PackedStringArray = ["%s  (upgrades %d/%d, x%d)" % [b.building_name, b.upgrades_bought,
			ShopButton.UPGRADE_THRESHOLDS.size(), roundi(pow(2.0, b.upgrades_bought))]]
	if not b.has_more_upgrades():
		lines.append("   All upgrades bought!")
	elif b.next_upgrade_ready():
		lines.append("   Next: %s — %s x2 — %s $" % [b.next_upgrade_name(), b.building_name, Fmt.money(b.next_upgrade_cost())])
	else:
		lines.append("   Next: %s — needs %d %s" % [b.next_upgrade_name(), b.next_upgrade_threshold(), b.building_name])
	if b.synergy_from_next > 0.0 and i + 1 < game.buttons.size():
		var next: ShopButton = game.buttons[i + 1]
		lines.append("   Synergy: each %s gives +%d%% (now +%d%%)" % [next.title,
				roundi(b.synergy_from_next * 100.0), roundi((game.synergy_factor(i) - 1.0) * 100.0)])
	return "\n".join(lines)


func _build_reputation(list: VBoxContainer) -> void:
	var header := _label(list, "", 14)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var prestige_button := _button(list, "")
	prestige_button.pressed.connect(func() -> void:
		_confirm("Found a new city? You keep reputation, achievements and golden coins, " +
				"but lose your money, buildings and upgrades.", func() -> void:
			game.prestige()
			rebuild()))
	_live.append(func() -> void:
		header.text = ("Reputation: %d  (+%d%% income)   ·   Unspent: %d\n" +
				"All-time earnings: %s $. Next reputation point at %s $.") % [
				game.prestige_points, game.prestige_points, game.chips,
				Fmt.money(game.lifetime_earned), Fmt.money(game.next_reputation_at())]
		var pending: int = game.pending_reputation()
		prestige_button.text = "Found a new city  (+%d reputation)" % pending
		prestige_button.disabled = pending < 1)

	list.add_child(HSeparator.new())
	_label(list, "Reputation shop (permanent):", 15, GOLD)
	for u in game.reputation_list:
		var row := HBoxContainer.new()
		list.add_child(row)
		var info := _label(row, "%s  (%d rep)\n   %s" % [u.name, u.cost, u.desc], 13)
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		var buy := _button(row, "Buy")
		var id: String = u.id
		buy.pressed.connect(func() -> void:
			game.buy_reputation_upgrade(id)
			rebuild())
		_live.append(func() -> void:
			var owned: bool = game.has_reputation_upgrade(id)
			buy.text = "Owned" if owned else "Buy"
			buy.disabled = owned or game.chips < u.cost
			info.modulate = GOLD if owned else Color.WHITE)


func _build_achievements(list: VBoxContainer) -> void:
	_label(list, "Unlocked %d / %d   (+%d%% income)" % [game.achievements.size(),
			game.achievement_list.size(), game.achievements.size()], 15, GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	list.add_child(grid)
	for a in game.achievement_list:
		var unlocked: bool = game.achievements.has(a.id)
		var label := _label(grid, "%s %s\n   %s" % ["[x]" if unlocked else "[  ]", a.name, a.desc], 13,
				GOLD if unlocked else GREY)
		label.custom_minimum_size.x = 340


func _build_stats(list: VBoxContainer) -> void:
	var label := _label(list, "", 14)
	_live.append(func() -> void:
		label.text = "\n".join(PackedStringArray([
			"Money now: %s $" % Fmt.money(game.dollars),
			"Earned this city: %s $" % Fmt.money(game.total_earned),
			"Earned all-time: %s $" % Fmt.money(game.lifetime_earned),
			"Income now: %s $/s   (best: %s $/s)" % [Fmt.small(game.income_per_second()), Fmt.small(game.best_ips)],
			"Click value: %s $   (best combo x%.2f)" % [Fmt.small(game.click_value()), game.best_combo],
			"Printer clicks: %d" % game.clicks_total,
			"Buildings: %s" % _building_counts(),
			"Golden coins: %d   ·   Cursed coins clicked: %d   ·   Best chain: %d" % [
					game.golden_coins, game.red_clicked, game.best_chain],
			"Events resolved: %d" % game.events_resolved,
			"Cities founded: %d   ·   Reputation: %d" % [game.cities, game.prestige_points],
			"Achievements: %d / %d" % [game.achievements.size(), game.achievement_list.size()],
			"Time played: %s" % _time(game.time_played),
			"Total multiplier: x%.2f" % game.global_multiplier(),
		])))


func _build_options(list: VBoxContainer) -> void:
	var fx := CheckBox.new()
	fx.text = "Visual effects (floating numbers, bounces, particles)"
	fx.focus_mode = FOCUS_NONE
	fx.button_pressed = game.fx_enabled
	fx.toggled.connect(game.set_fx)
	list.add_child(fx)

	var numbers := HBoxContainer.new()
	list.add_child(numbers)
	_label(numbers, "Number format:", 14)
	var format := OptionButton.new()
	format.focus_mode = FOCUS_NONE
	format.add_item("Short (1.23M)")
	format.add_item("Scientific (1.23e6)")
	format.selected = 1 if Fmt.scientific else 0
	format.item_selected.connect(func(index: int) -> void: game.set_scientific(index == 1))
	numbers.add_child(format)

	if game.has_method("set_volume"):
		for bus in ["Master", "Music", "SFX"]:
			var row := HBoxContainer.new()
			list.add_child(row)
			var name_label := _label(row, bus + " volume", 14)
			name_label.custom_minimum_size.x = 140
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.05
			slider.custom_minimum_size.x = 260
			slider.value = game.get_volume(bus)
			slider.value_changed.connect(func(value: float) -> void: game.set_volume(bus, value))
			row.add_child(slider)

	list.add_child(HSeparator.new())
	var reset := _button(list, "Reset game (deletes all progress)")
	reset.modulate = Color(1.0, 0.6, 0.6)
	reset.pressed.connect(func() -> void:
		_confirm("Delete ALL progress, including reputation and achievements?", game.hard_reset))


# --- Utilidades -------------------------------------------------------------------

func _label(parent: Node, text: String, font_size := 14, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	parent.add_child(label)
	return label


func _button(parent: Node, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = FOCUS_NONE
	button.custom_minimum_size.x = 90
	parent.add_child(button)
	return button


func _confirm(text: String, on_ok: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Are you sure?"
	dialog.dialog_text = text
	dialog.dialog_autowrap = true
	dialog.size = Vector2i(420, 150)
	dialog.confirmed.connect(on_ok)
	dialog.visibility_changed.connect(func() -> void:
		if not dialog.visible:
			dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


func _building_counts() -> String:
	var parts: PackedStringArray = []
	for b: ShopButton in game.buttons:
		parts.append("%s %d" % [b.title, b.count])
	return ", ".join(parts)


func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


static func _time(seconds: float) -> String:
	var total := floori(seconds)
	return "%dh %02dm %02ds" % [floori(total / 3600.0), floori(total % 3600 / 60.0), total % 60]
