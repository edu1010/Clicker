class_name FloatingText
extends Label
## Texto que sube y se desvanece ("+12 $", "Frenzy x7!"...).

const RISE := 40.0
const DURATION := 0.8


static func spawn(parent: Node, at: Vector2, message: String,
		color := Color.WHITE, font_size := 18) -> void:
	var label := FloatingText.new()
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	label.reset_size()
	label.position = at - label.size / 2.0

	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - RISE, DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, DURATION * 0.75).set_delay(DURATION * 0.25)
	tween.chain().tween_callback(label.queue_free)
