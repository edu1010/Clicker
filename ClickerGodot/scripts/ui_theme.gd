class_name UiTheme
extends RefCounted
## Tema visual de toda la interfaz (botones, paneles, pestañas, ventanas...),
## creado por código para que encaje con los colores del juego.
##
## Variaciones de tipo disponibles (theme_type_variation):
##   Button:         BuyButton (verde), GoldButton (dorado), DangerButton (rojo)
##   PanelContainer: Card, CardGold, Toast
##   Label:          Title, Heading, Muted, Value

const BG := Color("25282d")
const PANEL := Color("2f3238")
const CARD := Color("3a3e45")
const CARD_BORDER := Color("2a2d32")
const BORDER := Color("17191c")
const TEXT := Color("f2f2f2")
const MUTED := Color("a3a8b0")
const GOLD := Color("ffd84d")
const GOLD_DARK := Color("d9a520")
const GREEN := Color("4f9a4a")
const RED := Color("b9473f")
const BUTTON := Color("4a4f57")
const TRACK := Color("1c1e22")


static func create() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14

	# Botones.
	_button(t, "Button", BUTTON, TEXT)
	_button(t, "BuyButton", GREEN, TEXT, "Button")
	_button(t, "GoldButton", GOLD_DARK, Color("2a1d00"), "Button")
	_button(t, "DangerButton", RED, TEXT, "Button")
	_button(t, "OptionButton", BUTTON, TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", GOLD)
	t.set_color("font_pressed_color", "CheckBox", TEXT)
	t.set_color("font_hover_pressed_color", "CheckBox", GOLD)

	# Paneles.
	t.set_stylebox("panel", "PanelContainer", box(PANEL, BORDER, 4, 8, 14))
	t.set_stylebox("panel", "Panel", box(PANEL, BORDER, 4, 8, 14))
	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", box(CARD, CARD_BORDER, 2, 6, 10))
	_variation(t, "CardGold", "PanelContainer")
	t.set_stylebox("panel", "CardGold", box(CARD, GOLD_DARK, 2, 6, 10))
	_variation(t, "Toast", "PanelContainer")
	t.set_stylebox("panel", "Toast", box(Color(0.1, 0.11, 0.13, 0.94), GOLD_DARK, 2, 6, 6))

	# Textos.
	t.set_color("font_color", "Label", TEXT)
	_variation(t, "Title", "Label")
	t.set_font_size("font_size", "Title", 24)
	t.set_color("font_color", "Title", GOLD)
	_variation(t, "Heading", "Label")
	t.set_font_size("font_size", "Heading", 16)
	t.set_color("font_color", "Heading", GOLD)
	_variation(t, "Muted", "Label")
	t.set_font_size("font_size", "Muted", 12)
	t.set_color("font_color", "Muted", MUTED)
	_variation(t, "Value", "Label")
	t.set_font_size("font_size", "Value", 22)
	t.set_color("font_color", "Value", TEXT)

	# Pestañas.
	var tab_selected := box(CARD, GOLD, 0, 0, 0)
	tab_selected.border_width_top = 3
	tab_selected.corner_radius_top_left = 5
	tab_selected.corner_radius_top_right = 5
	_margins(tab_selected, 14, 6, 14, 6)
	var tab_unselected := box(PANEL, CARD_BORDER, 0, 0, 0)
	tab_unselected.border_width_top = 3
	tab_unselected.border_color = PANEL
	tab_unselected.corner_radius_top_left = 5
	tab_unselected.corner_radius_top_right = 5
	_margins(tab_unselected, 14, 6, 14, 6)
	var tab_hover := tab_unselected.duplicate()
	tab_hover.bg_color = Color("3f434a")
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	t.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	t.set_stylebox("tab_hovered", "TabContainer", tab_hover)
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "TabContainer", box(Color("33363c"), CARD_BORDER, 0, 6, 12))
	t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font_size("font_size", "TabContainer", 15)

	# Barras de progreso, deslizadores, scroll y separadores.
	t.set_stylebox("background", "ProgressBar", box(TRACK, BORDER, 1, 4, 0))
	t.set_stylebox("fill", "ProgressBar", box(GOLD, GOLD, 0, 4, 0))
	t.set_color("font_color", "ProgressBar", Color("2a1d00"))
	t.set_stylebox("slider", "HSlider", _margins(box(TRACK, BORDER, 1, 4, 0), 0, 4, 0, 4))
	t.set_stylebox("grabber_area", "HSlider", _margins(box(GOLD_DARK, GOLD_DARK, 0, 4, 0), 0, 4, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", _margins(box(GOLD, GOLD, 0, 4, 0), 0, 4, 0, 4))
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, _margins(box(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 4, 0), 3, 3, 3, 3))
		t.set_stylebox("grabber", bar, box(Color("5a606a"), Color(0, 0, 0, 0), 0, 4, 0))
		t.set_stylebox("grabber_highlight", bar, box(Color("6c727d"), Color(0, 0, 0, 0), 0, 4, 0))
		t.set_stylebox("grabber_pressed", bar, box(GOLD_DARK, Color(0, 0, 0, 0), 0, 4, 0))
	var line := StyleBoxLine.new()
	line.color = Color("4a4f57")
	line.thickness = 2
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", 12)

	# Ventanas (eventos, confirmaciones, bienvenida).
	var frame := box(PANEL, BORDER, 4, 8, 0)
	frame.expand_margin_left = 4
	frame.expand_margin_right = 4
	frame.expand_margin_bottom = 4
	frame.expand_margin_top = 34
	frame.shadow_color = Color(0, 0, 0, 0.45)
	frame.shadow_size = 10
	t.set_stylebox("embedded_border", "Window", frame)
	t.set_stylebox("embedded_unfocused_border", "Window", frame)
	t.set_color("title_color", "Window", GOLD)
	t.set_font_size("title_font_size", "Window", 16)
	t.set_stylebox("panel", "AcceptDialog", box(PANEL, PANEL, 0, 0, 14))
	t.set_constant("buttons_separation", "AcceptDialog", 16)

	# Desplegables y tooltips.
	t.set_stylebox("panel", "PopupMenu", box(CARD, BORDER, 2, 6, 6))
	t.set_stylebox("hover", "PopupMenu", box(Color("4c515a"), Color(0, 0, 0, 0), 0, 4, 4))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", GOLD)
	t.set_stylebox("panel", "TooltipPanel", box(Color("1c1e22"), GOLD_DARK, 1, 4, 6))
	return t


static func box(bg: Color, border: Color, border_width := 2, radius := 5, margin := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


static func _margins(s: StyleBoxFlat, left: float, top: float, right: float, bottom: float) -> StyleBoxFlat:
	s.content_margin_left = left
	s.content_margin_top = top
	s.content_margin_right = right
	s.content_margin_bottom = bottom
	return s


static func _variation(t: Theme, variation: String, base: String) -> void:
	t.set_type_variation(variation, base)


## Botón con relieve: borde inferior más grueso que "se hunde" al pulsar.
static func _button(t: Theme, type: String, color: Color, font_color: Color, base := "") -> void:
	if base != "":
		_variation(t, type, base)
	var normal := _margins(box(color, BORDER, 2, 5, 0), 12, 5, 12, 5)
	normal.border_width_bottom = 4
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed := _margins(box(color.darkened(0.15), BORDER, 2, 5, 0), 12, 7, 12, 3)
	var disabled := normal.duplicate()
	disabled.bg_color = color.darkened(0.3).lerp(Color("3a3d42"), 0.65)
	disabled.border_color = Color("24262a")
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, type, font_color)
	t.set_color("font_disabled_color", type, Color(MUTED, 0.6))
