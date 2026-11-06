# MoneyClicker (Godot 4)

Port a **Godot 4.7** del clicker original hecho en Defold (carpeta `../Clicker`),
ampliado con mecánicas clásicas de juegos incrementales.

## Cómo abrirlo
1. Abre Godot 4.7 → *Import* → selecciona `ClickerGodot/project.godot`.
2. Pulsa **F5** para jugar.

## Cómo se juega
- **Impresora:** cada clic da dinero. Mejoras de clic (se revelan al acercarte a su precio):
  - *Better Ink*: clic x2 por nivel (100 $, x10 por nivel).
  - *Golden Touch*: cada clic suma además un 1 % de tus $/s por nivel (1.000 $, x10 por nivel).
- **Edificios sin límite.** Cada compra encarece el siguiente un 15 %. Cada tipo paga a su ritmo:

| Edificio | Coste base | $/s | Paga cada |
|----------|-----------:|----:|----------:|
| Bar      |         15 |  1,5 |  1 s |
| Fábrica  |        120 |    9 |  3 s |
| Hospital |      1.300 |   50 |  6 s |
| Banco *(placeholder)*  | 14.000 | 260 | 10 s |
| Casino *(placeholder)* | 160.000 | 1.400 | 15 s |

- **Hitos:** con 10, 25, 50, 100, 150… edificios de un tipo, su producción se duplica.
  Las fábricas cambian de sprite al llegar a 10.
- **Desbloqueos:** cada edificio aparece como `???` hasta que has ganado la mitad de su coste.
- **Monedas doradas:** salen al azar cada 30–75 s y duran 10 s. Si la pillas:
  premio de 60 s de producción *o* frenesí x7 durante 30 s. Cada moneda da además
  +2 % de ingresos permanente y se queda en la bandeja de abajo.
- **FX:** la casilla de arriba a la izquierda activa/desactiva números flotantes y rebotes.
- **Guardado:** automático cada 10 s y al cerrar. Al volver ganas el 50 % de tu producción
  del tiempo que estuviste fuera (máx. 8 h).
  Para empezar de cero borra `%APPDATA%\Godot\app_userdata\MoneyClicker\save.cfg`.

## Estructura
| Archivo | Qué hace |
|---------|----------|
| `scripts/game.gd` | Economía, compras, monedas doradas, guardado |
| `scripts/shop_button.gd` + `scenes/shop_button.tscn` | Datos de cada edificio (coste, $/s, ritmo, sprites) y su botón |
| `scripts/building_row.gd` + `scenes/building_row.tscn` | Calle que dibuja hasta 5 edificios y su $/s |
| `scripts/golden_coin.gd` + `scenes/golden_coin.tscn` | Moneda dorada clicable |
| `scripts/hud.gd`, `scripts/pie.gd` | Interfaz (dinero, $/s, frenesí, mejoras, FX) |
| `scripts/clickable.gd` | Base para todo lo clicable (Area2D con "aplastado") |
| `scripts/frame.gd` | Fondo y marco de paneles (5 calles) |
| `scripts/floating_text.gd`, `scripts/fmt.gd`, `scripts/placeholder.gd` | Textos flotantes, formato 1.23K/M/B, placeholders |

Costes, ingresos, ritmos, colores de placeholder y sprites de cada edificio se editan
desde el inspector (propiedades exportadas de cada `ShopButton` en `main.tscn`).
Para dar arte a Banco y Casino basta con asignar `button_texture` y `building_texture`.
