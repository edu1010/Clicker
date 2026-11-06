# MoneyClicker (Godot 4)

Port a **Godot 4.7** del clicker original hecho en Defold (carpeta `../Clicker`).

## Cómo abrirlo
1. Abre Godot 4.7 → *Import* → selecciona `ClickerGodot/project.godot`.
2. Pulsa **F5** para jugar.

## Cómo se juega
- Haz clic en la **impresora** para ganar 1 dólar.
- Cada 10 dólares aparece una **moneda** (máx. 27) que genera 1 dólar cada 3 s.
- Compra edificios con los botones de arriba (máx. 5 de cada):

| Edificio  | Coste | Dólares cada 3 s |
|-----------|------:|-----------------:|
| Bar       |    10 |                5 |
| Fábrica   |   100 |               25 |
| Hospital  |   200 |               50 |

## Estructura
| Godot | Equivalente en Defold |
|-------|-----------------------|
| `scenes/main.tscn` + `scripts/game.gd` | `main.collection`, `Click.script`, `CreateBuildings/*.script` |
| `scripts/hud.gd`, `scripts/pie.gd` | `TextDollarsGui.gui`, `DollarText.gui_script` |
| `scripts/clickable.gd` (Area2D) | `Cursor.script` + collision objects |
| `scenes/shop_button.tscn` | `Prefabs/Buttons/*.go` |
| `scenes/building.tscn` | `Bar.go`, `Factory.go`, `Hospital.go` + `BuildingsIncrement.script` |
| `scenes/coin.tscn` | `Coin.go` + `Coin.script` |
| `scenes/printer.tscn` | `Printer.go` |

Los costes, ingresos y textos de cada botón se editan desde el inspector
(propiedades exportadas de `ShopButton` en `main.tscn`).
