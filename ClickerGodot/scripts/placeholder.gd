@tool
class_name Placeholder
extends Node2D
## Rectángulo de color con texto para edificios que aún no tienen sprite.

@export var size := Vector2(80, 60):
	set(value):
		size = value
		queue_redraw()
@export var color := Color(0.5, 0.5, 0.5):
	set(value):
		color = value
		queue_redraw()
@export var text := "?":
	set(value):
		text = value
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.5), false, 3.0)
	var font := ThemeDB.fallback_font
	var font_size := int(clampf(size.y * 0.28, 10.0, 28.0))
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(-width / 2.0, font_size * 0.35), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
