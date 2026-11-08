@tool
extends Node2D
## Fondo y marco de los paneles (sustituye a Fondo.png + Reborde.png,
## que solo tenían sitio para 3 calles).

const SCREEN := Rect2(0, -48, 960, 688)
const BORDER_COLOR := Color("404040")
const PANEL_COLOR := Color("555555")

const ROW_COUNT := 5
const ROW_TOP := 210.0
const ROW_STEP := 85.0
const ROW_HEIGHT := 78.0


static func row_rect(index: int) -> Rect2:
	return Rect2(360, ROW_TOP + ROW_STEP * index, 590, ROW_HEIGHT)


var widget_mode := false


func _draw() -> void:
	if widget_mode:
		var background := StyleBoxFlat.new()
		background.bg_color = BORDER_COLOR
		background.set_corner_radius_all(18)
		draw_style_box(background, SCREEN)
	else:
		draw_rect(SCREEN, BORDER_COLOR)
	var panels: Array[Rect2] = [
		Rect2(10, 10, 340, 438),   # impresora
		Rect2(10, 458, 340, 172),  # monedas
		Rect2(360, 10, 590, 190),  # tienda
	]
	for i in ROW_COUNT:
		panels.append(row_rect(i))
	for panel in panels:
		draw_rect(panel, PANEL_COLOR)
