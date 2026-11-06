extends CanvasLayer
## Textos de la interfaz (antes TextDollarsGui.gui + DollarText.gui_script).

@onready var _dollars: Label = $DollarsLabel
@onready var _coins: Label = $CoinsLabel
@onready var _pie: Control = $Pie
@onready var _building_labels := {
	"Bars": $BarsLabel,
	"Factories": $FactoriesLabel,
	"Hospitals": $HospitalsLabel,
}


func set_dollars(amount: int) -> void:
	_dollars.text = "%d Dollars" % amount


func set_coins(amount: int, max_amount: int) -> void:
	_coins.text = "Coins: %d/%d" % [amount, max_amount]


func set_progress(value: float) -> void:
	_pie.fill = value


func set_building_count(building_name: String, amount: int, max_amount: int) -> void:
	var label: Label = _building_labels.get(building_name)
	if label:
		label.text = "%s: %d/%d" % [building_name, amount, max_amount]
