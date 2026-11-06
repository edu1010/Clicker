class_name GoldenCoin
extends Clickable
## Moneda especial que aparece al azar unos segundos.
## - "gold": premio, frenesí, clic loco o cadena de monedas.
## - "red": maldita. 50 % premio gordo, 50 % pierdes dinero.

signal collected(coin: GoldenCoin)

const LIFETIME := 10.0
const CHAIN_LIFETIME := 6.0
const BLINK_TIME := 3.0
const SPRITE_SCALE := 0.2

## "gold" o "red". Asignar antes de añadir al árbol.
var kind := "gold"
## Eslabón de la cadena (0 = no es parte de una cadena).
var chain := 0

var _age := 0.0
var _lifetime := LIFETIME
var _glow := Color(1.0, 0.9, 0.3)

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	super()
	pressed.connect(_on_pressed)
	if kind == "red":
		_sprite.modulate = Color(1.0, 0.35, 0.35)
		_glow = Color(1.0, 0.25, 0.2)
	if chain > 0:
		_lifetime = CHAIN_LIFETIME
	_sprite.scale = Vector2.ZERO
	create_tween().tween_property(_sprite, "scale", Vector2.ONE * SPRITE_SCALE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_age += delta
	_sprite.position.y = sin(_age * 3.0) * 4.0
	if _age > _lifetime - BLINK_TIME:
		modulate.a = 1.0 if fmod(_age, 0.3) < 0.18 else 0.25
	if _age >= _lifetime:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var radius := 38.0 + sin(_age * 5.0) * 5.0
	draw_circle(Vector2.ZERO, radius, Color(_glow, 0.25))
	draw_circle(Vector2.ZERO, radius * 0.7, Color(_glow.lightened(0.3), 0.25))


func _on_pressed() -> void:
	input_pickable = false
	collected.emit(self)
	queue_free()
