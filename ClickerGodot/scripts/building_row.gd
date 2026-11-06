class_name BuildingRow
extends Node2D
## Una calle: dibuja hasta 5 edificios y muestra cantidad y $/s.

const MAX_SPRITES := 5
const GROUND := 62.0
const BUILDING_HEIGHT := 50.0
const FIRST_X := 50.0
const SPACING := 84.0
const PLACEHOLDER_SIZE := Vector2(62, 46)
## La calle "evoluciona" (cielo con nubes) a partir de este nivel de hito (25 edificios).
const CLOUDS_MILESTONE := 2
const CLOUD_SPEED := 25.0
const NIGHT_TINT := Color(0.35, 0.4, 0.7)
const LOCKED_TINT := Color(0.45, 0.45, 0.5)

var _texture: Texture2D
var _shown := 0
var _night := 0.0
var _unlocked := true

@onready var _street: CanvasItem = $Street
@onready var _clouds: Sprite2D = $Clouds
@onready var _buildings: Node2D = $Buildings
@onready var _traffic: Traffic = $Traffic
@onready var _info: Label = $Info


func _process(delta: float) -> void:
	if _clouds.visible:
		_clouds.region_rect.position.x = fmod(_clouds.region_rect.position.x + CLOUD_SPEED * delta,
				_clouds.texture.get_width())


func show_building(button: ShopButton, unlocked: bool, income: float) -> void:
	_unlocked = unlocked
	if unlocked:
		_info.text = "%s x%d\n%s $/s" % [button.building_name, button.count, Fmt.small(income)]
	else:
		_info.text = "???"
	_clouds.visible = unlocked and button.milestone_level() >= CLOUDS_MILESTONE
	_traffic.set_car_count(0 if button.count == 0 else mini(5, 1 + button.milestone_level()))
	_apply_tint()
	_sync_sprites(button)


## 0 = día, 1 = noche.
func set_daylight(night: float) -> void:
	_night = night
	_traffic.night = night
	_apply_tint()


func _apply_tint() -> void:
	var tint := Color.WHITE.lerp(NIGHT_TINT, _night)
	if not _unlocked:
		tint *= LOCKED_TINT
	_street.modulate = tint
	_clouds.modulate = tint
	_buildings.modulate = Color.WHITE.lerp(tint, 0.6)


## Vacía la calle (al fundar una ciudad nueva).
func reset() -> void:
	for child in _buildings.get_children():
		child.queue_free()
	_shown = 0
	_texture = null


## Punto (local) donde mostrar los "+X $" de esta calle.
func popup_point() -> Vector2:
	var visible_count := maxi(1, mini(_shown, MAX_SPRITES))
	return Vector2(FIRST_X + SPACING * (visible_count - 1) / 2.0, 18)


func pulse() -> void:
	for child: Node2D in _buildings.get_children():
		if child.is_queued_for_deletion():
			continue
		var base: Vector2 = child.get_meta("base_scale")
		var old: Tween = child.get_meta("tween", null)
		if old:
			old.kill()
		var tween := child.create_tween()
		tween.tween_property(child, "scale", base * Vector2(1.1, 1.15), 0.08)
		tween.tween_property(child, "scale", base, 0.12)
		child.set_meta("tween", tween)


func _sync_sprites(button: ShopButton) -> void:
	var texture := button.current_building_texture()
	if texture != _texture:
		_texture = texture
		for child in _buildings.get_children():
			child.queue_free()
		_shown = 0
	var wanted := mini(button.count, MAX_SPRITES)
	while _shown < wanted:
		_add_sprite(button, _shown)
		_shown += 1


func _add_sprite(button: ShopButton, index: int) -> void:
	var node: Node2D
	var height := BUILDING_HEIGHT
	if _texture:
		var sprite := Sprite2D.new()
		sprite.texture = _texture
		var k := BUILDING_HEIGHT / _texture.get_height()
		sprite.scale = Vector2(k, k)
		node = sprite
	else:
		var placeholder := Placeholder.new()
		placeholder.size = PLACEHOLDER_SIZE
		placeholder.color = button.placeholder_color
		placeholder.text = button.title
		height = PLACEHOLDER_SIZE.y
		node = placeholder
	node.position = Vector2(FIRST_X + SPACING * index, GROUND - height / 2.0)
	var base := node.scale
	node.set_meta("base_scale", base)
	_buildings.add_child(node)

	node.scale = Vector2.ZERO
	var tween := node.create_tween()
	tween.tween_property(node, "scale", base, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.set_meta("tween", tween)
