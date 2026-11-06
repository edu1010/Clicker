class_name ShopButton
extends Clickable
## Botón de la tienda que compra un tipo de edificio.

## Nombre que se muestra en el HUD ("Bars", "Factories", ...).
@export var building_name := "Bars"
@export var title := "Make a New Bar"
@export var cost := 10
## Dólares que genera cada edificio cada 3 segundos.
@export var income := 5
@export var max_count := 5
@export var button_texture: Texture2D
@export var building_texture: Texture2D
## Posición del primer edificio de la fila; los siguientes van 100 px a la derecha.
@export var row_origin := Vector2.ZERO

var count := 0


func _ready() -> void:
	super()
	$Sprite.texture = button_texture
	$TitleLabel.text = title
	$CostLabel.text = "Cost: %d Dollars" % cost
