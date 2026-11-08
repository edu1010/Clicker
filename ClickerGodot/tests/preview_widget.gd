extends SceneTree

func _initialize() -> void:
	_preview.call_deferred()

func _preview() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	game.use_save = false
	root.title = "MoneyClicker Widget Preview"
	root.add_child(game)
	root.show()
	game.dollars = 1500.0
	game.total_earned = 5000.0
	game.buttons[0].count = 12
	game.buttons[1].count = 3
	game.buttons[2].count = 1
	game.add_city()
	game.change_city(-1)

