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

var count := 0
## Tiempo acumulado hacia el próximo pago.
var timer := 0.0

@onready var _icon_root: Node2D = $IconRoot
@onready var _title_label: Label = $TitleLabel
@onready var _cost_label: Label = $CostLabel
@onready var _info_label: Label = $InfoLabel


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


func income(global_multiplier: float) -> float:
	return income_per_second * count * pow(2.0, milestone_level()) * global_multiplier


func current_building_texture() -> Texture2D:
	if milestone_texture and count >= MILESTONES[0]:
		return milestone_texture
	return building_texture


func is_unlocked(total_earned: float) -> bool:
	return count > 0 or total_earned >= base_cost * REVEAL_FRACTION


func refresh(dollars: float, total_earned: float) -> void:
	var unlocked := is_unlocked(total_earned)
	var affordable := dollars >= cost()
	input_pickable = unlocked
	_title_label.text = title if unlocked else "???"
	_cost_label.text = Fmt.money(cost()) + " $"
	_cost_label.modulate = Color(1.0, 0.85, 0.3) if affordable else Color(0.75, 0.75, 0.75)
	_info_label.text = "x%d  ·  x2 at %d" % [count, next_milestone()] if unlocked else ""
	if not unlocked:
		_icon_root.modulate = Color.BLACK
	elif affordable:
		_icon_root.modulate = Color.WHITE
	else:
		_icon_root.modulate = Color(0.45, 0.45, 0.45)
