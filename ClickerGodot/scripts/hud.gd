class_name Hud
extends CanvasLayer
## Interfaz: dinero, $/s, efectos activos, combo, monedas, mejoras de clic,
## botón de menú, avisos ("toasts") y ventanas de eventos.

signal ink_pressed
signal boost_pressed
signal menu_pressed

const TOAST_TIME := 2.8

var _toasts: Array[String] = []
var _toast_left := 0.0
var _event_callback := Callable()

@onready var _dollars: Label = $DollarsLabel
@onready var _rate: Label = $RateLabel
@onready var _effects: Label = $EffectsLabel
@onready var _pie: Control = $Pie
@onready var _combo: Label = $ComboLabel
@onready var _coins: Label = $CoinsLabel
@onready var _ink: Button = $InkButton
@onready var _boost: Button = $BoostButton
@onready var _menu: Button = $MenuButton
@onready var _toast: PanelContainer = $Toast
@onready var _toast_label: Label = $Toast/Label
@onready var _welcome: AcceptDialog = $WelcomeDialog
@onready var _event: ConfirmationDialog = $EventDialog


func _ready() -> void:
	_ink.pressed.connect(ink_pressed.emit)
	_boost.pressed.connect(boost_pressed.emit)
	_menu.pressed.connect(menu_pressed.emit)
	_event.confirmed.connect(_on_event_choice.bind(true))
	_event.canceled.connect(_on_event_choice.bind(false))
	_toast.visible = false


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)
		if _toast_left <= 0.0:
			_toast.visible = false
	elif not _toasts.is_empty():
		_toast_label.text = _toasts.pop_front()
		_toast.visible = true
		_toast.modulate.a = 1.0
		_toast_left = TOAST_TIME


func set_dollars(text: String) -> void:
	_dollars.text = text + " Dollars"


func set_rate(per_second: float, boosted: bool) -> void:
	_rate.text = "per second: %s $" % Fmt.small(per_second)
	_rate.modulate = Color(1.0, 0.85, 0.3) if boosted else Color.WHITE


## Lista los modificadores activos; el círculo muestra lo que le queda al primero temporal.
func set_effects(modifiers: Array[Dictionary]) -> void:
	var parts: PackedStringArray = []
	var fraction := -1.0
	for m in modifiers:
		if m.time_left == INF:
			parts.append(m.label)
		else:
			parts.append("%s %ds" % [m.label, ceili(m.time_left)])
			if fraction < 0.0:
				fraction = m.time_left / m.duration
	_effects.text = "  ·  ".join(parts)
	_effects.visible = not parts.is_empty()
	_pie.visible = fraction >= 0.0
	if fraction >= 0.0:
		_pie.fill = fraction


func set_combo(value: float) -> void:
	_combo.visible = value > 1.04
	_combo.text = "Combo x%.2f" % value
	_combo.modulate = Color(1.0, 0.85, 0.3) if value >= GameData.COMBO_MAX else Color.WHITE


func set_coins(amount: int, bonus: float) -> void:
	_coins.text = "Golden coins: %d  (+%d%% income)" % [amount, roundi(bonus * 100.0)]


func set_upgrade(which: String, text: String, enabled: bool) -> void:
	var button := _ink if which == "ink" else _boost
	button.text = text
	button.disabled = not enabled


func set_menu_badge(has_news: bool) -> void:
	_menu.text = "Menu •" if has_news else "Menu"
	_menu.modulate = Color(1.0, 0.85, 0.3) if has_news else Color.WHITE


func toast(text: String) -> void:
	_toasts.append(text)


func show_welcome(text: String) -> void:
	_welcome.dialog_text = text
	_welcome.popup_centered.call_deferred()


func is_event_open() -> bool:
	return _event.visible


## Muestra un evento con dos opciones. callback(choice_a: bool).
func show_event(title: String, text: String, option_a: String, option_b: String, callback: Callable) -> void:
	_event.title = title
	_event.dialog_text = text
	_event.ok_button_text = option_a
	_event.cancel_button_text = option_b
	_event_callback = callback
	_event.popup_centered()


func _on_event_choice(choice_a: bool) -> void:
	if _event_callback.is_valid():
		var callback := _event_callback
		_event_callback = Callable()
		callback.call(choice_a)
