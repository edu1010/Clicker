extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.use_save = false
	root.add_child(game)
	game.set_process(false)
	if not game.desktop.supported():
		print("Desktop checks: SKIP (requires native Windows display)")
		quit()
		return
	var desktop: DesktopMode = game.desktop
	var original_rect := Rect2i(root.position, root.size)
	var original_mode := root.mode
	var original_borderless := root.borderless
	var original_on_top := root.always_on_top
	var original_min := root.min_size
	desktop.set_enabled(true)
	await process_frame
	check(desktop.enabled and root.borderless and root.transparent and root.transparent_bg, "Widget enables borderless transparency")
	check(root.always_on_top and root.min_size == Vector2i(480, 344), "Widget pins and sets usable minimum")
	desktop.set_pinned(false)
	check(not root.always_on_top, "Pin can be disabled")
	var start := Rect2i(root.position, root.size)
	desktop._gesture_rect = start
	desktop._gesture_delta = Vector2(-120, -30)
	desktop._dragging = true
	desktop._update_gesture()
	check(root.position == start.position + Vector2i(-120, -30), "Move gesture changes window position")
	check(root.size == start.size, "Moving does not resize")
	desktop._dragging = false
	desktop._resize_edge = DisplayServer.WINDOW_EDGE_BOTTOM_RIGHT
	desktop._gesture_rect = Rect2i(root.position, root.size)
	desktop._gesture_delta = Vector2(-86, -57)
	desktop._update_gesture()
	check(root.size.x == 514 and root.size.y == 368, "Resize preserves game proportions")
	desktop._gesture_delta = Vector2(-10000, -10000)
	desktop._update_gesture()
	check(root.size == Vector2i(480, 344), "Resize clamps at usable minimum")
	desktop._end_gesture()
	var saved_rect := Rect2i(root.position, root.size)
	var cfg := ConfigFile.new()
	desktop.save_settings(cfg)
	check(cfg.get_value("window", "widget") and cfg.get_value("window", "widget_rect") == saved_rect, "Persists widget geometry and mode")
	check(not cfg.get_value("window", "pinned"), "Persists Pin choice")
	desktop.set_enabled(false)
	await process_frame
	check(root.size == original_rect.size and root.position == original_rect.position, "Normal restores original rectangle")
	check(root.mode == original_mode and root.borderless == original_borderless, "Normal restores window mode and decorations")
	check(root.always_on_top == original_on_top and root.min_size == original_min, "Normal restores flags and constraints")
	check(not root.transparent and not root.transparent_bg, "Normal restores opaque rendering")
	desktop.restore_settings(cfg)
	await process_frame
	await process_frame
	check(desktop.enabled and Rect2i(root.position, root.size) == saved_rect, "Widget reload restores its rectangle")
	check(not root.always_on_top, "Widget reload restores unpinned state")
	desktop.set_enabled(false)
	game.queue_free()
	await process_frame
	print("Desktop checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
