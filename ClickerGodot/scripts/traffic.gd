class_name Traffic
extends Node2D
## Coches que circulan por la calle y farolas que se encienden de noche.

const WIDTH := 590.0
const MARGIN := 20.0
const LANE_Y: Array[float] = [64.0, 69.0]
const LAMP_SPACING := 118.0
const CAR_COLORS: Array[Color] = [Color("d94f4f"), Color("4f8ad9"), Color("e0c341"), Color("5fbf6a"), Color("e8e8e8")]

## 0 = día, 1 = noche.
var night := 0.0

var _cars: Array[Dictionary] = []


func set_car_count(amount: int) -> void:
	while _cars.size() < amount:
		_cars.append({
			"x": randf() * WIDTH,
			"speed": randf_range(35.0, 80.0) * (1.0 if randf() < 0.5 else -1.0),
			"color": CAR_COLORS.pick_random(),
		})
	while _cars.size() > amount:
		_cars.pop_back()


func _process(delta: float) -> void:
	for car in _cars:
		car.x = fposmod(car.x + car.speed * delta + MARGIN, WIDTH + MARGIN * 2.0) - MARGIN
	queue_redraw()


func _draw() -> void:
	if night > 0.05:
		for i in 5:
			var x := 30.0 + LAMP_SPACING * i
			draw_circle(Vector2(x, 57), 12.0, Color(1.0, 0.9, 0.5, 0.18 * night))
			draw_rect(Rect2(x - 1.5, 55.5, 3, 3), Color(1.0, 0.95, 0.6, night))
	for car in _cars:
		var x: float = car.x
		if x < -9.0 or x > WIDTH + 9.0:
			continue
		var forward: float = signf(car.speed)
		var y: float = LANE_Y[0] if forward > 0.0 else LANE_Y[1]
		var color: Color = car.color
		draw_rect(Rect2(x - 9, y, 18, 5), color)
		draw_rect(Rect2(x - 5, y - 3, 10, 3), color.darkened(0.15))
		draw_rect(Rect2(x - 3, y - 2, 6, 2), Color(0.75, 0.9, 1.0))
		draw_rect(Rect2(x - 7, y + 5, 3, 2), Color(0.15, 0.15, 0.15))
		draw_rect(Rect2(x + 4, y + 5, 3, 2), Color(0.15, 0.15, 0.15))
		if night > 0.3:
			var front := x + 9.0 * forward
			draw_rect(Rect2(front - (2.0 if forward > 0.0 else 0.0), y + 1, 2, 2), Color(1.0, 0.95, 0.5, night))
