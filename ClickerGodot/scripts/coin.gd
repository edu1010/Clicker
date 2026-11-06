class_name Coin
extends AnimatedSprite2D
## Moneda: suena y genera 1 dólar cada 3 segundos.

signal produced(amount: int)


func _on_timer_timeout() -> void:
	$CoinSound.play()
	produced.emit(1)
