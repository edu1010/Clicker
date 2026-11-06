class_name Building
extends Sprite2D
## Edificio comprado: genera `income` dólares cada vez que salta el temporizador (3 s).

signal produced(amount: int)

@export var income := 5


func _on_timer_timeout() -> void:
	produced.emit(income)
