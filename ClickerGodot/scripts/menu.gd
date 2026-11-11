class_name GameMenu
extends Control
## Menú con pestañas: Upgrades, Empire, Reputation, Achievements, Stats y Options.
## Se construye por código a partir del estado del juego (game.gd) usando
## las variaciones de UiTheme (tarjetas, botones de compra, títulos...).

const TABS := ["Upgrades", "Empire", "Reputation", "Achievements", "Stats", "Options"]
const LIVE_INTERVAL := 0.25
const PANEL_RECT := Rect2(90, 30, 780, 580)
const ICON_SIZE := Vector2(56, 56)

## Lo asigna game.gd en su _ready.
var game: Node

var _tabs: TabContainer
var _summary: Label
var _bold: FontVariation
## Funciones que actualizan textos/estados mientras el menú está abierto.
var _live: Array[Callable] = []
var _live_timer := 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	_bold = FontVariation.new()
	_bold.base_font = ThemeDB.fallback_font
	_bold.variation_embolden = 0.6

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.06, 0.08, 0.7)
	shade.set_anchors_preset(PRESET_FULL_RECT)
	shade.gui_input.connect(_on_shade_input)
	add_child(shade)

	var panel := PanelContainer.new()
	panel.position = PANEL_RECT.position
	panel.custom_minimum_size = PANEL_RECT.size
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	vbox.add_child(header)
	var title := _label(header, "MoneyClicker", "Title")
	title.add_theme_font_override("font", _bold)
	_summary = _label(header, "", "Muted")
	_summary.size_flags_horizontal = SIZE_EXPAND_FILL
	_summary.size_flags_vertical = SIZE_SHRINK_CENTER
	var close_button := _button(header, "Close")
	close_button.pressed.connect(close)

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
	_live.append(_update_summary)
	match current_tab_name():
		"Upgrades": _build_upgrades(list)
		"Empire": _build_empire(list)
		"Reputation": _build_reputation(list)
		"Achievements": _build_achievements(list)
		"Stats": _build_stats(list)
		"Options": _build_options(list)
	_update_live()


func _update_live() -> void:
	for update in _live:
		update.call()


func _update_summary() -> void:
	_summary.text = "%s $   ·   %s $/s   ·   Reputation %d   ·   %d/%d achievements" % [
			Fmt.money(game.dollars), Fmt.small(game.income_per_second()), game.prestige_points,
			game.achievements.size(), game.achievement_list.size()]


# --- Upgrades ----------------------------------------------------------------------

func _build_upgrades(list: VBoxContainer) -> void:
	_label(list, "Each level doubles that building's income (10 levels per building, also on the streets list). Every building also boosts the previous one (synergy).", "Muted").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var any := false
	for i in game.buttons.size():
		var b: ShopButton = game.buttons[i]
		if not b.is_unlocked(game.total_earned):
			continue
		any = true
		var row := _card(list, HBoxContainer.new())
		row.add_theme_constant_override("separation", 14)
		row.add_child(_icon(b))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 10)
		info.add_child(title_row)
		var title := _label(title_row, "", "Heading")
		title.add_theme_font_override("font", _bold)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 4)
		pips.size_flags_vertical = SIZE_SHRINK_CENTER
		title_row.add_child(pips)
		for p in ShopButton.MAX_LEVEL:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(12, 12)
			pips.add_child(pip)
		var next := _label(info, "")
		var synergy := _label(info, "", "Muted")

		var buy := _button(row, "", "BuyButton")
		buy.custom_minimum_size = Vector2(120, 44)
		buy.size_flags_vertical = SIZE_SHRINK_CENTER
		buy.pressed.connect(func() -> void:
			game.level_up(i)
			rebuild())
		var maxed := _label(row, "MAX", "Heading")
		maxed.custom_minimum_size.x = 120
		maxed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		maxed.size_flags_vertical = SIZE_SHRINK_CENTER

		var update := func() -> void:
			title.text = "%s  x%d" % [b.building_name, b.count]
			for p in pips.get_child_count():
				var pip_rect: ColorRect = pips.get_child(p)
				pip_rect.color = UiTheme.GOLD if p < b.level else UiTheme.TRACK
			var more := not b.is_max_level()
			buy.visible = more
			maxed.visible = not more
			if not more:
				next.text = "Max level  (income x%s)" % Fmt.money(pow(2.0, b.level))
			elif b.level_ready():
				next.text = "Next: level %d  —  %s x2" % [b.level + 1, b.building_name]
			else:
				next.text = "Next: level %d  —  needs %d %s" % [b.level + 1, b.next_level_requirement(), b.building_name]
			buy.text = Fmt.money(b.next_level_cost()) + " $" if more else ""
			buy.disabled = not game.can_level_up(i)
			synergy.visible = b.synergy_from_next > 0.0 and i + 1 < game.buttons.size()
			if synergy.visible:
				var source: ShopButton = game.buttons[i + 1]
				synergy.text = "Synergy: each %s gives +%d%%  (now +%d%%)" % [source.title,
						roundi(b.synergy_from_next * 100.0), roundi((game.synergy_factor(i) - 1.0) * 100.0)]
		_live.append(update)
	if not any:
		_empty(list, "Buy your first building to unlock levels.")


# --- Empire (árbol del imperio) ----------------------------------------------------

func _build_empire(list: VBoxContainer) -> void:
	var top := _card(list, VBoxContainer.new(), true)
	top.add_theme_constant_override("separation", 6)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	top.add_child(stats)
	var treasury := _stat_block(stats, "Treasury (all cities)")
	var ranks := _stat_block(stats, "Tree ranks")
	var breakdown := _label(top, "", "Muted")
	breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(top, "Empire upgrades are paid with the money of ALL your cities: each city pays in proportion to its cash. Their effects are permanent, apply to every city and survive renewals.", "Muted").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_live.append(func() -> void:
		treasury.text = Fmt.money(game.empire_cash()) + " $"
		ranks.text = "%d / %d" % [game.tree_ranks_bought(), game.tree_ranks_total()]
		var parts: PackedStringArray = []
		for i in game.city_states.size():
			var cash: float = game.dollars if i == game.active_city else float(game.city_states[i].get("dollars", 0.0))
			parts.append("City %d: %s $" % [i + 1, Fmt.money(cash)])
		breakdown.text = "  ·  ".join(parts))

	var grid := _grid(list)
	for branch in GameData.TREE_BRANCHES:
		var column := _card(grid, VBoxContainer.new())
		column.custom_minimum_size.x = 345
		column.add_theme_constant_override("separation", 8)
		var heading := _label(column, branch, "Heading")
		heading.add_theme_font_override("font", _bold)
		for node: Dictionary in game.tree_list:
			if node.branch == branch:
				_tree_node(column, node)


## Un nodo del árbol: nombre y rangos, descripción, efecto actual y botón de compra.
func _tree_node(parent: VBoxContainer, node: Dictionary) -> void:
	var id: String = node.id
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	box.add_child(title_row)
	if node.requires != "":
		_label(title_row, "↳", "Muted")
	var title := _label(title_row, node.name)
	title.add_theme_font_override("font", _bold)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 3)
	pips.size_flags_vertical = SIZE_SHRINK_CENTER
	title_row.add_child(pips)
	for p in int(node.max):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(10, 10)
		pips.add_child(pip)
	var desc := _label(box, node.desc, "Muted")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	box.add_child(bottom)
	var effect := _label(bottom, "")
	effect.size_flags_horizontal = SIZE_EXPAND_FILL
	effect.size_flags_vertical = SIZE_SHRINK_CENTER
	var buy := _button(bottom, "", "BuyButton")
	buy.custom_minimum_size = Vector2(130, 34)
	buy.pressed.connect(func() -> void:
		game.buy_tree(id)
		_update_live())
	_live.append(func() -> void:
		var rank: int = game.tree_rank(id)
		for p in pips.get_child_count():
			var pip_rect: ColorRect = pips.get_child(p)
			pip_rect.color = UiTheme.GOLD if p < rank else UiTheme.TRACK
		effect.text = "Now: " + GameData.tree_effect_text(node, rank) if rank > 0 else "Not bought"
		effect.modulate = UiTheme.GOLD if rank > 0 else UiTheme.MUTED
		if game.tree_maxed(id):
			buy.text = "MAX"
			buy.disabled = true
		elif not game.tree_unlocked(id):
			buy.text = "Needs %s" % game.tree_node(node.requires).name
			buy.disabled = true
		else:
			buy.text = Fmt.money(game.tree_cost(id)) + " $"
			buy.disabled = not game.can_buy_tree(id))


# --- Reputation --------------------------------------------------------------------

func _build_reputation(list: VBoxContainer) -> void:
	var top := _card(list, VBoxContainer.new(), true)
	top.add_theme_constant_override("separation", 10)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	top.add_child(stats)
	var rep := _stat_block(stats, "Reputation")
	var unspent := _stat_block(stats, "Unspent")
	var cities := _stat_block(stats, "Cities")
	var renewals := _stat_block(stats, "Renewals")

	var progress_label := _label(top, "", "Muted")
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 12
	progress.max_value = 1.0
	top.add_child(progress)

	var prestige := _button(top, "", "GoldButton")
	prestige.custom_minimum_size.y = 46
	prestige.add_theme_font_size_override("font_size", 17)
	prestige.add_theme_font_override("font", _bold)
	prestige.pressed.connect(func() -> void:
		var gain: int = game.pending_reputation()
		_confirm("Renew City %d?" % (game.active_city + 1),
				("Resets only City %d: money, buildings and upgrades. You get +%d reputation (production +%.1f%%). " +
				"Other cities, reputation, achievements and golden coins are kept. Founding new cities is a separate purchase.") % [
					game.active_city + 1, gain, game.reputation_speedup(gain) * 100.0],
				func() -> void:
					game.prestige()
					rebuild()))
	_label(top, "Empire reputation = ∛(earnings of all your cities / 10M). Renewing a city claims the share it earned since its last renewal. Each point gives +1% income everywhere, forever.", "Muted").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_live.append(func() -> void:
		rep.text = "%d  (+%d%%)" % [game.prestige_points, roundi(game.prestige_points * game.reputation_bonus() * 100.0)]
		unspent.text = str(game.chips)
		cities.text = str(game.city_states.size())
		renewals.text = str(game.renewals)
		progress.value = game.reputation_progress()
		progress_label.text = "Empire earnings: %s $  ·  next point at %s $  ·  unclaimed %d, City %d share %d%%" % [
				Fmt.money(game.empire_lifetime()), Fmt.money(game.next_reputation_at()),
				game.empire_pending_reputation(), game.active_city + 1, roundi(game.city_share() * 100.0)]
		var pending: int = game.pending_reputation()
		prestige.text = "Renew City %d   (+%d reputation · +%.1f%% production)" % [
				game.active_city + 1, pending, game.reputation_speedup(pending) * 100.0]
		prestige.disabled = pending < 1)

	_section(list, "Permanent upgrades")
	var grid := _grid(list)
	for u in game.reputation_list:
		var card := _card(grid, VBoxContainer.new())
		card.custom_minimum_size.x = 345
		var name_label := _label(card, u.name, "Heading")
		name_label.add_theme_font_override("font", _bold)
		var desc := _label(card, u.desc, "Muted")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var bottom := HBoxContainer.new()
		card.add_child(bottom)
		var cost := _label(bottom, "%d reputation" % u.cost)
		cost.size_flags_horizontal = SIZE_EXPAND_FILL
		cost.modulate = UiTheme.GOLD
		var buy := _button(bottom, "Buy", "BuyButton")
		buy.custom_minimum_size.x = 90
		var id: String = u.id
		buy.pressed.connect(func() -> void:
			game.buy_reputation_upgrade(id)
			rebuild())
		var owned_card: PanelContainer = card.get_parent()
		_live.append(func() -> void:
			var owned: bool = game.has_reputation_upgrade(id)
			buy.text = "Owned" if owned else "Buy"
			buy.disabled = owned or game.chips < u.cost
			owned_card.theme_type_variation = &"CardGold" if owned else &"Card")


# --- Achievements ------------------------------------------------------------------

func _build_achievements(list: VBoxContainer) -> void:
	var unlocked_count: int = game.achievements.size()
	var total: int = game.achievement_list.size()
	var head := _card(list, VBoxContainer.new(), true)
	_label(head, "%d / %d unlocked   ·   +%d%% income" % [unlocked_count, total, unlocked_count], "Heading")
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.max_value = total
	bar.value = unlocked_count
	head.add_child(bar)

	var grid := _grid(list)
	for a in game.achievement_list:
		var unlocked: bool = game.achievements.has(a.id)
		var row := _card(grid, HBoxContainer.new(), unlocked)
		row.custom_minimum_size.x = 345
		row.add_theme_constant_override("separation", 10)
		var badge := ColorRect.new()
		badge.custom_minimum_size = Vector2(18, 18)
		badge.size_flags_vertical = SIZE_SHRINK_CENTER
		badge.color = UiTheme.GOLD if unlocked else UiTheme.TRACK
		row.add_child(badge)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		row.add_child(text)
		var name_label := _label(text, a.name)
		name_label.add_theme_font_override("font", _bold)
		name_label.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.55)
		_label(text, a.desc, "Muted")


# --- Stats -------------------------------------------------------------------------

func _build_stats(list: VBoxContainer) -> void:
	var sections := {
		"Money": [
			["Money now", func() -> String: return Fmt.money(game.dollars) + " $"],
			["Earned this city", func() -> String: return Fmt.money(game.total_earned) + " $"],
			["Earned all-time", func() -> String: return Fmt.money(game.lifetime_earned) + " $"],
			["Income now", func() -> String: return Fmt.small(game.income_per_second()) + " $/s"],
			["Best income", func() -> String: return Fmt.small(game.best_ips) + " $/s"],
			["Total multiplier", func() -> String: return "x%.2f" % game.global_multiplier()],
		],
		"Clicking": [
			["Printer clicks", func() -> String: return str(game.clicks_total)],
			["Click value", func() -> String: return Fmt.small(game.click_value()) + " $"],
			["Best combo", func() -> String: return "x%.2f" % game.best_combo],
		],
		"City": [
			["Buildings", func() -> String: return _building_counts()],
			["Golden coins", func() -> String: return str(game.golden_coins)],
			["Cursed coins clicked", func() -> String: return str(game.red_clicked)],
			["Best coin chain", func() -> String: return str(game.best_chain)],
			["Events resolved", func() -> String: return str(game.events_resolved)],
		],
		"Legacy": [
			["Cities", func() -> String: return str(game.city_states.size())],
			["City renewals", func() -> String: return str(game.renewals)],
			["Reputation", func() -> String: return str(game.prestige_points)],
			["Achievements", func() -> String: return "%d / %d" % [game.achievements.size(), game.achievement_list.size()]],
			["Time played", func() -> String: return _time(game.time_played)],
		],
	}
	for section in sections:
		var card := _card(list, VBoxContainer.new())
		_label(card, section, "Heading")
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 30)
		grid.add_theme_constant_override("v_separation", 4)
		card.add_child(grid)
		for entry: Array in sections[section]:
			var key := _label(grid, entry[0])
			key.modulate = UiTheme.MUTED
			key.custom_minimum_size.x = 200
			var value := _label(grid, "")
			value.add_theme_font_override("font", _bold)
			var getter: Callable = entry[1]
			_live.append(func() -> void: value.text = getter.call())


# --- Options -----------------------------------------------------------------------

func _build_options(list: VBoxContainer) -> void:
	var display := _card(list, VBoxContainer.new())
	_label(display, "Display", "Heading")
	var widget := CheckBox.new()
	widget.text = "Desktop widget (Windows): drag city title, resize edges"
	widget.focus_mode = FOCUS_NONE
	widget.button_pressed = game.desktop.enabled
	widget.disabled = not game.desktop.supported()
	widget.toggled.connect(game.desktop.set_enabled)
	display.add_child(widget)
	var pin := CheckBox.new()
	pin.text = "Keep widget above other windows"
	pin.button_pressed = game.desktop.pinned
	pin.disabled = not game.desktop.supported()
	pin.toggled.connect(game.desktop.set_pinned)
	display.add_child(pin)
	var fx := CheckBox.new()
	fx.text = "Visual effects (floating numbers, bounces, particles)"
	fx.focus_mode = FOCUS_NONE
	fx.button_pressed = game.fx_enabled
	fx.toggled.connect(game.set_fx)
	display.add_child(fx)
	var numbers := HBoxContainer.new()
	numbers.add_theme_constant_override("separation", 12)
	display.add_child(numbers)
	var format_label := _label(numbers, "Number format")
	format_label.size_flags_vertical = SIZE_SHRINK_CENTER
	var format := OptionButton.new()
	format.focus_mode = FOCUS_NONE
	format.add_item("Short (1.23M)")
	format.add_item("Scientific (1.23e6)")
	format.selected = 1 if Fmt.scientific else 0
	format.item_selected.connect(func(index: int) -> void: game.set_scientific(index == 1))
	numbers.add_child(format)

	if game.has_method("set_volume"):
		var audio := _card(list, VBoxContainer.new())
		_label(audio, "Audio", "Heading")
		for bus in ["Master", "Music", "SFX"]:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			audio.add_child(row)
			var name_label := _label(row, {"Master": "Master", "Music": "Music", "SFX": "Effects"}[bus])
			name_label.custom_minimum_size.x = 90
			var slider := HSlider.new()
			slider.min_value = 0.0
			slider.max_value = 1.0
			slider.step = 0.05
			slider.size_flags_horizontal = SIZE_EXPAND_FILL
			slider.size_flags_vertical = SIZE_SHRINK_CENTER
			slider.value = game.get_volume(bus)
			row.add_child(slider)
			var percent := _label(row, "", "Muted")
			percent.custom_minimum_size.x = 44
			percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			percent.text = "%d%%" % roundi(slider.value * 100.0)
			slider.value_changed.connect(func(value: float) -> void:
				game.set_volume(bus, value)
				percent.text = "%d%%" % roundi(value * 100.0))

	var danger := _card(list, VBoxContainer.new())
	_label(danger, "Danger zone", "Heading")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	danger.add_child(row)
	var warning := _label(row, "Deletes ALL progress, including reputation and achievements.", "Muted")
	warning.size_flags_horizontal = SIZE_EXPAND_FILL
	warning.size_flags_vertical = SIZE_SHRINK_CENTER
	var reset := _button(row, "Reset game", "DangerButton")
	reset.pressed.connect(func() -> void:
		_confirm("Reset game?", "This deletes ALL progress, including reputation and achievements.", game.hard_reset))


# --- Piezas reutilizables ---------------------------------------------------------

func _label(parent: Node, text: String, variation := "") -> Label:
	var label := Label.new()
	label.text = text
	if variation != "":
		label.theme_type_variation = variation
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, variation := "") -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = FOCUS_NONE
	if variation != "":
		button.theme_type_variation = variation
	parent.add_child(button)
	return button


## Tarjeta con fondo; devuelve el contenedor interior para añadirle cosas.
func _card(parent: Node, inner: Container, gold := false) -> Container:
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardGold" if gold else &"Card"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(card)
	card.add_child(inner)
	return inner


func _grid(parent: Node) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	return grid


func _section(parent: Node, text: String) -> void:
	var label := _label(parent, text, "Heading")
	label.add_theme_font_override("font", _bold)


func _empty(parent: Node, text: String) -> void:
	var card := _card(parent, CenterContainer.new())
	card.custom_minimum_size.y = 120
	_label(card, text, "Muted")


## Número grande con un pie de texto; devuelve la etiqueta del número.
func _stat_block(parent: Node, caption: String) -> Label:
	var block := VBoxContainer.new()
	block.size_flags_horizontal = SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 0)
	parent.add_child(block)
	var value := _label(block, "0", "Value")
	value.add_theme_font_override("font", _bold)
	_label(block, caption, "Muted")
	return value


func _icon(b: ShopButton) -> Control:
	if b.button_texture:
		var rect := TextureRect.new()
		rect.texture = b.button_texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = ICON_SIZE
		rect.size_flags_vertical = SIZE_SHRINK_CENTER
		return rect
	var holder := Control.new()
	holder.custom_minimum_size = ICON_SIZE
	holder.size_flags_vertical = SIZE_SHRINK_CENTER
	var placeholder := Placeholder.new()
	placeholder.size = ICON_SIZE - Vector2(6, 6)
	placeholder.position = ICON_SIZE / 2.0
	placeholder.color = b.placeholder_color
	placeholder.text = b.title
	holder.add_child(placeholder)
	return holder


func _confirm(title: String, text: String, on_ok: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.dialog_autowrap = true
	dialog.ok_button_text = "Yes"
	dialog.cancel_button_text = "Cancel"
	dialog.size = Vector2i(440, 150)
	dialog.theme = theme
	dialog.get_ok_button().theme_type_variation = &"GoldButton"
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
