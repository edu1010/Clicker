class_name Fmt
extends RefCounted
## Formato de números grandes: 999, 1.23K, 45.6M, 789B...

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


## Opción del menú: notación científica (1.23e9) en vez de sufijos.
static var scientific := false


static func money(value: float) -> String:
	if value < 1000.0:
		return str(floori(value))
	if scientific and value >= 1e6:
		var exponent := floori(log(value) / log(10.0) + 1e-9)
		return "%.2fe%d" % [value / pow(10.0, exponent), exponent]
	var tier := floori(log(value) / log(1000.0) + 1e-9)
	if tier >= SUFFIXES.size():
		return String.num_scientific(value)
	var scaled := value / pow(1000.0, tier)
	var pattern := "%.2f" if scaled < 10.0 else ("%.1f" if scaled < 100.0 else "%.0f")
	return (pattern % scaled) + SUFFIXES[tier]


## Igual que money() pero con un decimal para cantidades pequeñas (1.5, 4.2...).
static func small(value: float) -> String:
	if value < 10.0 and not is_equal_approx(value, roundf(value)):
		return "%.1f" % value
	return money(value)
