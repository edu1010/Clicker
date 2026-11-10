class_name DesktopMode
extends CanvasLayer
## Ventana flotante de Windows; gestos en píxeles físicos para admitir el escalado.

var game: Node
var enabled := false
var pinned := true
var _normal_rect := Rect2i(100, 100, 960, 688)
var _normal_mode := Window.MODE_WINDOWED
var _normal_borderless := false
var _normal_on_top := false
var _normal_min := Vector2i.ZERO
var _widget_rect := Rect2i(0, 0, 600, 430)
var _has_widget_rect := false
var _bar: HBoxContainer
var _title: Label
var _previous: Button
var _next: Button
var _new_city: Button
var _buy_mode: Button
var _toggle: Button
var _pin: Button
var _minimize: Button
var _close: Button
var _grip: Label
var _dragging := false
var _resize_edge := -1
var _gesture_rect := Rect2i()
var _gesture_delta := Vector2.ZERO


func supported() -> bool:
	return OS.get_name() == "Windows" and DisplayServer.get_name() != "headless"


func _ready() -> void:
	layer = 10
	_bar = HBoxContainer.new()
	_bar.position = Vector2(12, 8)
	_bar.size = Vector2(936, 32)
	_bar.add_theme_constant_override("separation", 5)
	_bar.theme = UiTheme.create()
	add_child(_bar)
	_previous = _button("‹", "Previous city", func(): game.change_city(-1))
	_title = Label.new()
	_title.custom_minimum_size.x = 134
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_STOP
	_title.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_title.tooltip_text = "Drag here to move the widget"
	_title.gui_input.connect(_drag)
	_bar.add_child(_title)
	_next = _button("›", "Next city", func(): game.change_city(1))
	_new_city = _button("+", "Found a new city", game.request_found_city)
	_buy_mode = _button("Buy x1", "How many buildings each shop click buys", game.cycle_buy_mode)
	_buy_mode.custom_minimum_size.x = 96
	_toggle = _button("Widget", "Switch between desktop widget and normal window", func(): set_enabled(not enabled))
	_toggle.custom_minimum_size.x = 100
	_toggle.disabled = not supported()
	if not supported():
		_toggle.tooltip_text = "Desktop widget is available in the standalone Windows game"
	_pin = _button("Pin", "Keep widget above other windows", func(): set_pinned(not pinned))
	_minimize = _button("−", "Minimize", func(): get_window().mode = Window.MODE_MINIMIZED)
	_close = _button("×", "Save and close", _quit)
	_grip = Label.new()
	_grip.text = "◢"
	_grip.position = Vector2(932, 660)
	_grip.size = Vector2(28, 28)
	_grip.mouse_filter = Control.MOUSE_FILTER_STOP
	_grip.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	add_child(_grip)
	get_window().focus_exited.connect(_end_gesture)
	_update_controls()


func _button(text: String, hint: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(36, 32)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_bar.add_child(button)
	return button


func _end_gesture() -> void:
	_dragging = false
	_resize_edge = -1


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		_resize_edge = -1
		return
	if event is InputEventMouseMotion and (_dragging or _resize_edge >= 0):
		_gesture_delta += event.screen_relative
		_update_gesture()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var window := get_window()
	var point := Vector2i(get_viewport().get_final_transform() * event.position)
	var left := point.x < 8
	var right := point.x >= window.size.x - 8
	var top := point.y < 8
	var bottom := point.y >= window.size.y - 8
	var edge := -1
	if top:
		edge = DisplayServer.WINDOW_EDGE_TOP_LEFT if left else (DisplayServer.WINDOW_EDGE_TOP_RIGHT if right else DisplayServer.WINDOW_EDGE_TOP)
	elif bottom:
		edge = DisplayServer.WINDOW_EDGE_BOTTOM_LEFT if left else (DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT if right else DisplayServer.WINDOW_EDGE_BOTTOM)
	elif left:
		edge = DisplayServer.WINDOW_EDGE_LEFT
	elif right:
		edge = DisplayServer.WINDOW_EDGE_RIGHT
	if _grip.get_global_rect().has_point(event.position):
		edge = DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT
	if edge >= 0:
		_resize_edge = edge
		_gesture_rect = Rect2i(window.position, window.size)
		_gesture_delta = Vector2.ZERO
		get_viewport().set_input_as_handled()


func _drag(event: InputEvent) -> void:
	if enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		_gesture_rect = Rect2i(get_window().position, get_window().size)
		_gesture_delta = Vector2.ZERO


func _update_gesture() -> void:
	var window := get_window()
	var movement := Vector2i(_gesture_delta.round())
	if _dragging:
		window.position = _gesture_rect.position + movement
		return
	var rect := _gesture_rect
	var minimum := window.min_size
	if _resize_edge in [DisplayServer.WINDOW_EDGE_LEFT, DisplayServer.WINDOW_EDGE_TOP_LEFT, DisplayServer.WINDOW_EDGE_BOTTOM_LEFT]:
		var width := maxi(minimum.x, rect.size.x - movement.x)
		rect.position.x = rect.end.x - width
		rect.size.x = width
	elif _resize_edge in [DisplayServer.WINDOW_EDGE_RIGHT, DisplayServer.WINDOW_EDGE_TOP_RIGHT, DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT]:
		rect.size.x = maxi(minimum.x, rect.size.x + movement.x)
	if _resize_edge in [DisplayServer.WINDOW_EDGE_TOP, DisplayServer.WINDOW_EDGE_TOP_LEFT, DisplayServer.WINDOW_EDGE_TOP_RIGHT]:
		var height := maxi(minimum.y, rect.size.y - movement.y)
		rect.position.y = rect.end.y - height
		rect.size.y = height
	elif _resize_edge in [DisplayServer.WINDOW_EDGE_BOTTOM, DisplayServer.WINDOW_EDGE_BOTTOM_LEFT, DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT]:
		rect.size.y = maxi(minimum.y, rect.size.y + movement.y)
	# Mantiene la proporción del juego para evitar bandas y botones deformados.
	var vertical_edge := _resize_edge in [DisplayServer.WINDOW_EDGE_TOP, DisplayServer.WINDOW_EDGE_BOTTOM]
	var corner := _resize_edge in [DisplayServer.WINDOW_EDGE_TOP_LEFT, DisplayServer.WINDOW_EDGE_TOP_RIGHT, DisplayServer.WINDOW_EDGE_BOTTOM_LEFT, DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT]
	if vertical_edge or (corner and absf(_gesture_delta.y) > absf(_gesture_delta.x) * 688.0 / 960.0):
		rect.size.x = maxi(minimum.x, roundi(rect.size.y * 960.0 / 688.0))
	else:
		rect.size.y = maxi(minimum.y, roundi(rect.size.x * 688.0 / 960.0))
	if _resize_edge in [DisplayServer.WINDOW_EDGE_LEFT, DisplayServer.WINDOW_EDGE_TOP_LEFT, DisplayServer.WINDOW_EDGE_BOTTOM_LEFT]:
		rect.position.x = _gesture_rect.end.x - rect.size.x
	if _resize_edge in [DisplayServer.WINDOW_EDGE_TOP, DisplayServer.WINDOW_EDGE_TOP_LEFT, DisplayServer.WINDOW_EDGE_TOP_RIGHT]:
		rect.position.y = _gesture_rect.end.y - rect.size.y
	window.position = rect.position
	window.size = rect.size


func _process(_delta: float) -> void:
	_title.text = game.city_title()
	var blocked: bool = not game.can_change_city()
	_previous.disabled = blocked or game.city_states.size() < 2
	_next.disabled = _previous.disabled
	_new_city.disabled = blocked
	_new_city.tooltip_text = "Found City %d for %s $ (paid by this city; keeps all existing cities)" % [
			game.city_states.size() + 1, Fmt.money(game.found_cost())]
	_new_city.theme_type_variation = &"GoldButton" if game.dollars >= game.found_cost() else &""
	_buy_mode.text = game.buy_mode_label()
	# El menú y los diálogos tienen prioridad sobre los controles de la ventana.
	_bar.visible = not game.menu.visible and not game.hud.is_modal_open()


func set_enabled(value: bool) -> void:
	if value == enabled or (value and not supported()):
		return
	var window := get_window()
	if value:
		_normal_rect = Rect2i(window.position, window.size)
		_normal_mode = window.mode
		_normal_borderless = window.borderless
		_normal_on_top = window.always_on_top
		_normal_min = window.min_size
		window.mode = Window.MODE_WINDOWED
		window.borderless = true
		window.transparent = true
		window.transparent_bg = true
		window.always_on_top = pinned
		window.min_size = Vector2i(480, 344)
		if not _has_widget_rect:
			var area := DisplayServer.screen_get_usable_rect(window.current_screen)
			_widget_rect.position = area.end - _widget_rect.size - Vector2i(16, 16)
			_has_widget_rect = true
		_apply_rect(_widget_rect)
	else:
		_widget_rect = Rect2i(window.position, window.size)
		window.always_on_top = _normal_on_top
		window.transparent_bg = false
		window.transparent = false
		window.borderless = _normal_borderless
		window.min_size = _normal_min
		_apply_rect(_normal_rect)
		window.mode = _normal_mode
	_dragging = false
	_resize_edge = -1
	enabled = value
	game.get_node("Frame").widget_mode = enabled
	game.get_node("Frame").queue_redraw()
	_update_controls()
	if game.use_save and not game._resetting and not game.city_states.is_empty():
		game.save_game()


func _apply_rect(rect: Rect2i) -> void:
	# Adapta posiciones antiguas si se ha desconectado un monitor.
	var window := get_window()
	var screen := window.current_screen
	for i in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(i).has_point(rect.get_center()):
			screen = i
			break
	var area := DisplayServer.screen_get_usable_rect(screen)
	var minimum := window.min_size.max(Vector2i(480, 344))
	window.size = rect.size.max(minimum).min(area.size)
	window.position = rect.position.clamp(area.position, area.end - window.size)


func set_pinned(value: bool) -> void:
	pinned = value
	if enabled:
		get_window().always_on_top = pinned
	_update_controls()


func _update_controls() -> void:
	_toggle.text = "Normal" if enabled else "Widget"
	_pin.visible = enabled
	_pin.modulate = Color(1.0, 0.85, 0.3) if pinned else Color.WHITE
	_minimize.visible = enabled
	_close.visible = enabled
	_grip.visible = enabled


func _quit() -> void:
	if game.use_save:
		game.save_game()
	get_tree().quit()


func save_settings(cfg: ConfigFile) -> void:
	if enabled:
		_widget_rect = Rect2i(get_window().position, get_window().size)
	cfg.set_value("window", "widget", enabled)
	cfg.set_value("window", "pinned", pinned)
	cfg.set_value("window", "widget_rect", _widget_rect)
	cfg.set_value("window", "has_widget_rect", _has_widget_rect)


func restore_settings(cfg: ConfigFile) -> void:
	pinned = cfg.get_value("window", "pinned", true)
	_widget_rect = cfg.get_value("window", "widget_rect", _widget_rect)
	_has_widget_rect = cfg.get_value("window", "has_widget_rect", false)
	if cfg.get_value("window", "widget", false):
		set_enabled.call_deferred(true)
