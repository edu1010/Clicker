class_name ShopButton
extends Clickable
## Botón de la tienda. Guarda los datos de un tipo de edificio y cuántos tienes.

const COST_GROWTH := 1.15
## Al llegar a estas cantidades la producción del edificio se multiplica x2.
## A partir de 100, cada 50 más también dan x2.
const MILESTONES: Array[int] = [10, 25, 50]
## Se revela cuando has ganado en total esta fracción de su coste base.
const REVEAL_FRACTION := 0.5

## Nombre en plural para la calle ("Bars", "Factories"...).
@export var building_name := "Bars"
@export var title := "Bar"
@export var base_cost := 15.0
@export var income_per_second := 1.5
## Cada cuántos segundos paga (ritmo distinto por edificio).
@export var period := 1.0
@export var button_texture: Texture2D
@export var building_texture: Texture2D
## Sprite opcional que sustituye al normal tras el primer hito (x10).
@export var milestone_texture: Texture2D
## Color del placeholder cuando no hay textura.
@export var placeholder_color := Color(0.5, 0.5, 0.5)
## Nombres de las 4 mejoras de este edificio (cada una duplica su producción).
@export var upgrade_names := PackedStringArray()
## Bonus por cada edificio del siguiente tipo (sinergia). 0.02 = +2 % por unidad.
@export var synergy_from_next := 0.0

## Edificios necesarios y multiplicador de coste (sobre base_cost) de cada mejora.
const UPGRADE_THRESHOLDS: Array[int] = [1, 5, 25, 50]
const UPGRADE_COST_FACTORS: Array[float] = [10.0, 50.0, 500.0, 50000.0]

var count := 0
var upgrades_bought := 0
## Tiempo acumulado hacia el próximo pago.
var timer := 0.0

@onready var _icon_root: Node2D = $IconRoot
@onready var _title_label: Label = $TitleLabel
@onready var _cost_label: Label = $CostLabel
@onready var _info_label: Label = $InfoLabel
@onready var _gain_label: Label = $GainLabel


func _ready() -> void:
	super()
	var sprite: Sprite2D = $IconRoot/Sprite
	var placeholder: Placeholder = $IconRoot/Placeholder
	sprite.texture = button_texture
	sprite.visible = button_texture != null
	placeholder.visible = button_texture == null
	placeholder.color = placeholder_color
	placeholder.text = title


func cost() -> float:
	return base_cost * pow(COST_GROWTH, count)


## Coste de comprar `quantity` unidades seguidas (serie geométrica).
func cost_of(quantity: int) -> float:
	if quantity <= 0:
		return 0.0
	return cost() * (pow(COST_GROWTH, quantity) - 1.0) / (COST_GROWTH - 1.0)


## Cuántas unidades se pueden pagar con `dollars` (0 si ni una).
func affordable_count(dollars: float) -> int:
	var first := cost()
	if dollars < first:
		return 0
	var amount := floori(log(dollars * (COST_GROWTH - 1.0) / first + 1.0) / log(COST_GROWTH))
	# Corrige redondeos cerca del saldo exacto.
	while amount > 0 and cost_of(amount) > dollars:
		amount -= 1
	while cost_of(amount + 1) <= dollars:
		amount += 1
	return amount

func milestone_level(amount := count) -> int:
	var level := 0
	for m in MILESTONES:
		if amount >= m:
			level += 1
	if amount >= 100:
		level += floori(amount / 50.0) - 1
	return level


func next_milestone() -> int:
	for m in MILESTONES:
		if count < m:
			return m
	return (floori(count / 50.0) + 1) * 50


func income(multiplier: float) -> float:
	return income_per_second * count * pow(2.0, milestone_level() + upgrades_bought) * multiplier


func has_more_upgrades() -> bool:
	return upgrades_bought < UPGRADE_THRESHOLDS.size()


func next_upgrade_name() -> String:
	if upgrades_bought < upgrade_names.size():
		return upgrade_names[upgrades_bought]
	return "%s upgrade %d" % [title, upgrades_bought + 1]


func next_upgrade_threshold() -> int:
	return UPGRADE_THRESHOLDS[upgrades_bought]


func next_upgrade_cost() -> float:
	return base_cost * UPGRADE_COST_FACTORS[upgrades_bought]


func next_upgrade_ready() -> bool:
	return has_more_upgrades() and count >= next_upgrade_threshold()


func current_building_texture() -> Texture2D:
	if milestone_texture and count >= MILESTONES[0]:
		return milestone_texture
	return building_texture


func is_unlocked(total_earned: float) -> bool:
	return count > 0 or total_earned >= base_cost * REVEAL_FRACTION


## quantity: unidades de la próxima compra. gain: $/s extra que aportaría, recalculado
## con hitos y sinergias; junto a él se muestra la recuperación simple (precio / ganancia).
func refresh(dollars: float, total_earned: float, quantity := 1, gain := 0.0) -> void:
	var unlocked := is_unlocked(total_earned)
	var price := cost_of(quantity)
	var affordable := dollars >= price
	input_pickable = unlocked
	_title_label.text = title if unlocked else "???"
	_cost_label.text = ("x%d · " % quantity if quantity > 1 else "") + Fmt.money(price) + " $"
	_cost_label.modulate = Color(1.0, 0.85, 0.3) if affordable else Color(0.75, 0.75, 0.75)
	_info_label.text = "x%d  ·  x2 at %d" % [count, next_milestone()] if unlocked else ""
	_gain_label.visible = unlocked and gain > 0.0
	if _gain_label.visible:
		_gain_label.text = "+%s $/s · %s" % [Fmt.small(gain), payback_text(price / gain)]
	if not unlocked:
		_icon_root.modulate = Color.BLACK
	elif affordable:
		_icon_root.modulate = Color.WHITE
	else:
		_icon_root.modulate = Color(0.45, 0.45, 0.45)


## Recuperación simple en formato corto (12s, 5m, 2.5h).
static func payback_text(seconds: float) -> String:
	if seconds < 10.0:
		return "%.1fs" % seconds
	if seconds < 60.0:
		return "%ds" % roundi(seconds)
	if seconds < 3600.0:
		return "%dm" % roundi(seconds / 60.0)
	return "%.1fh" % (seconds / 3600.0)
