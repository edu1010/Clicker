class_name Clickable
extends Area2D
## Área clicable que se "aplasta" brevemente al pulsarla
## (equivale al cursor + collisionobject del proyecto Defold).

signal pressed

## Escala relativa mientras está pulsado.
@export var pressed_scale := 0.9
## Segundos que dura el aplastamiento.
@export var press_time := 0.1

var _base_scale := Vector2.ONE
var _tween: Tween


func _ready() -> void:
	_base_scale = scale


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_squish()
		pressed.emit()


func _squish() -> void:
	if _tween:
		_tween.kill()
	scale = _base_scale * pressed_scale
	_tween = create_tween()
	_tween.tween_interval(press_time)
	_tween.tween_callback(func() -> void: scale = _base_scale)
