class_name GoldenCoin
extends Clickable
## Moneda dorada que aparece al azar unos segundos. Si la pillas, da un premio.

signal collected(coin: GoldenCoin)

const LIFETIME := 10.0
const BLINK_TIME := 3.0
const SPRITE_SCALE := 0.2

var _age := 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	super()
	pressed.connect(_on_pressed)
	_sprite.scale = Vector2.ZERO
	create_tween().tween_property(_sprite, "scale", Vector2.ONE * SPRITE_SCALE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_age += delta
	_sprite.position.y = sin(_age * 3.0) * 4.0
	if _age > LIFETIME - BLINK_TIME:
		modulate.a = 1.0 if fmod(_age, 0.3) < 0.18 else 0.25
	if _age >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var glow := 38.0 + sin(_age * 5.0) * 5.0
	draw_circle(Vector2.ZERO, glow, Color(1.0, 0.9, 0.3, 0.25))
	draw_circle(Vector2.ZERO, glow * 0.7, Color(1.0, 0.95, 0.5, 0.25))


func _on_pressed() -> void:
	input_pickable = false
	collected.emit(self)
	queue_free()
