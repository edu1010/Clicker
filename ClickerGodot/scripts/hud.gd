class_name Hud
extends CanvasLayer
## Interfaz: dinero, $/s, frenesí, monedas doradas, mejoras de clic y opciones.

signal ink_pressed
signal boost_pressed
signal fx_toggled(enabled: bool)

@onready var _dollars: Label = $DollarsLabel
@onready var _rate: Label = $RateLabel
@onready var _frenzy: Label = $FrenzyLabel
@onready var _pie: Control = $Pie
@onready var _coins: Label = $CoinsLabel
@onready var _ink: Button = $InkButton
@onready var _boost: Button = $BoostButton
@onready var _fx: CheckBox = $FxToggle
@onready var _welcome: AcceptDialog = $WelcomeDialog


func _ready() -> void:
	_ink.pressed.connect(ink_pressed.emit)
	_boost.pressed.connect(boost_pressed.emit)
	_fx.toggled.connect(fx_toggled.emit)


func set_dollars(text: String) -> void:
	_dollars.text = text + " Dollars"


func set_rate(per_second: float, frenzy: bool) -> void:
	_rate.text = "per second: %s $" % Fmt.small(per_second)
	_rate.modulate = Color(1.0, 0.85, 0.3) if frenzy else Color.WHITE


func set_frenzy(seconds_left: float, total: float) -> void:
	var active := seconds_left > 0.0
	_frenzy.visible = active
	_pie.visible = active
	if active:
		_frenzy.text = "FRENZY x7  %ds" % ceili(seconds_left)
		_pie.fill = seconds_left / total


func set_coins(amount: int, bonus: float) -> void:
	_coins.text = "Golden coins: %d  (+%d%% income)" % [amount, roundi(bonus * 100.0)]


func set_upgrade(which: String, text: String, enabled: bool) -> void:
	var button := _ink if which == "ink" else _boost
	button.text = text
	button.disabled = not enabled


func set_fx(enabled: bool) -> void:
	_fx.set_pressed_no_signal(enabled)


func show_welcome(text: String) -> void:
	_welcome.dialog_text = text
	_welcome.popup_centered.call_deferred()
