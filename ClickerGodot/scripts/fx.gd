class_name Fx
extends RefCounted
## Efectos de partículas sin texturas (cuadraditos de colores).

const BILLS: Array[Color] = [Color("5fae4a"), Color("7cc95e"), Color("3f8a35")]
const CONFETTI: Array[Color] = [Color("ffd84d"), Color("ff6b6b"), Color("6bc5ff"), Color("8cff7a"), Color("d58cff")]


static func burst(parent: Node, at: Vector2, colors: Array[Color], amount := 14,
		speed := 180.0, spread := 70.0, direction := Vector2.UP, size := Vector2(3, 6)) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.9
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 500)
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = size.x
	p.scale_amount_max = size.y

	var initial := Gradient.new()
	initial.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var gradient_colors := PackedColorArray()
	for i in colors.size():
		offsets.append(float(i) / colors.size())
		gradient_colors.append(colors[i])
	initial.offsets = offsets
	initial.colors = gradient_colors
	p.color_initial_ramp = initial

	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	p.color_ramp = fade

	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func confetti(parent: Node, at: Vector2) -> void:
	burst(parent, at, CONFETTI, 40, 280.0, 180.0, Vector2.UP, Vector2(3, 6))


## Hace volar unas monedas desde `from` hasta `to` (p. ej. hacia el contador).
static func fly(parent: Node, scene: PackedScene, from: Vector2, to: Vector2, count := 5) -> void:
	for i in count:
		var coin: Node2D = scene.instantiate()
		coin.position = from + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		parent.add_child(coin)
		var tween := coin.create_tween()
		tween.tween_interval(i * 0.06)
		tween.tween_property(coin, "position", to, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(coin, "scale", coin.scale * 0.5, 0.5)
		tween.tween_callback(coin.queue_free)
