extends Control
## Indicador circular del progreso hasta la siguiente moneda.

@export var color := Color.WHITE

var fill := 0.0:
	set(value):
		fill = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	draw_arc(center, radius, 0.0, TAU, 48, Color(color, 0.35), 1.0, true)
	if fill <= 0.0:
		return
	var steps := maxi(2, ceili(64.0 * fill))
	var points := PackedVector2Array([center])
	for i in steps + 1:
		var angle := -PI / 2.0 + TAU * fill * i / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
