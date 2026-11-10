# MoneyClicker (Godot 4)

Port a **Godot 4.7** del clicker original hecho en Defold (carpeta `../Clicker`),
ampliado con las mecánicas clásicas de los juegos incrementales.

## Cómo abrirlo
1. Abre Godot 4.7 → *Import* → selecciona `ClickerGodot/project.godot`.
2. Pulsa **F5** para jugar.

## Cómo se juega

### Dinero
- **Impresora:** cada clic da dinero. Si haces clic rápido sube un **combo** hasta x3.
- Mejoras de clic (debajo de la impresora): *Better Ink* (clic x2 por nivel) y
  *Golden Touch* (cada clic suma un 1 % de tus $/s por nivel).

### Edificios
Sin límite; cada compra encarece el siguiente un 15 %. Cada tipo paga a su ritmo:

| Edificio | Coste base | $/s | Paga cada | Sinergia |
|----------|-----------:|----:|----------:|----------|
| Bar      |         15 |  1,5 |  1 s | +2 % por fábrica |
| Fábrica  |        120 |    9 |  3 s | +3 % por hospital |
| Hospital |      1.300 |   50 |  6 s | +4 % por banco |
| Banco *(placeholder)*  | 14.000 | 260 | 10 s | +5 % por casino |
| Casino *(placeholder)* | 160.000 | 1.400 | 15 s | — |

- **Hitos:** con 10, 25, 50, 100, 150… edificios de un tipo, su producción se duplica.
- **Mejoras por edificio** (Menú → Upgrades): 4 por tipo, cada una x2.
- **Desbloqueos:** cada edificio aparece como `???` hasta que has ganado la mitad de su coste.
- **Compras múltiples:** el botón **Buy x1** de la barra superior alterna entre ×1, ×10, ×25,
  *hasta el siguiente hito* (`Buy to x2`) y *máximo pagable*. El precio mostrado es el de toda la compra.
- **Comparar compras:** bajo cada edificio, en verde, se ve cuántos $/s añadiría esa compra
  (recalculando hitos y sinergias) y en cuánto tiempo se recupera (precio ÷ ganancia).

### Monedas especiales (cada 30–75 s, duran 10 s)
- **Dorada:** premio de 60 s de producción, frenesí x7 (30 s), clic loco x777 (10 s)
  o una **cadena** de monedas seguidas. Cada dorada da +2 % de ingresos permanente.
- **Roja (maldita):** 50 % premio de 10 min de producción, 50 % pierdes el 10 % del dinero.

### Eventos
Cada 3–6 min aparece un evento con dos opciones (inspección de Hacienda, huelga,
festival, inversor, turistas, apagón).

### Prestigio
**Menú → Reputation → Renew City N.** Reinicias solo la ciudad seleccionada (dinero, edificios
y mejoras) a cambio de **Reputación**. Cada ciudad tiene su propio contador:
√(lo que ha ganado esa ciudad desde su fundación / 100.000) menos lo que ya reclamó.
Así una ciudad vacía no puede cobrar la reputación que generan las demás.
El botón indica también el aumento real de producción (de 100 a 110 puntos es +5 %, no +10 %).
Cada punto da +1 % de ingresos para siempre y se gasta en mejoras permanentes:
Head Start, Seed Money, Lucky Charm, Night Owl y Golden Age.

### Logros y estadísticas
24 logros (+1 % de ingresos cada uno) y estadísticas completas en el menú.

### Ciudad viva
Ciclo día/noche (4 min) con farolas, coches que aumentan con los hitos y
cielo con nubes en las calles que superan los 25 edificios.

### Widget de escritorio (Windows)
- Pulsa **Widget** en la barra superior o actívalo en **Menú → Options**.
- Se convierte en una ventana pequeña sin bordes, inicialmente en la esquina inferior derecha.
- **Mover:** arrastra el título de la ciudad en la barra superior.
- **Tamaño:** arrastra un borde o el tirador **◢** de la esquina inferior derecha.
  Conserva la proporción del juego; mínimo 480 × 344 píxeles.
- **Pin:** activa/desactiva mantenerlo por encima de otras ventanas.
- **−** minimiza y **×** guarda y cierra. **Normal** recupera la ventana anterior.
- Se guardan el modo, tamaño, posición y Pin; al reconectar se ajusta a los monitores disponibles.
- Usa una ventana independiente: desactiva *Embed Game on Play* en el editor de Godot.
  En la versión web el widget está deshabilitado.

### Varias ciudades
- **+** abre la ficha para **fundar** una ciudad independiente sin borrar las anteriores.
  Cuesta dinero de la ciudad seleccionada: 250K $ la segunda, 1,25M $ la tercera, 6,25M $ la cuarta…
  (×5 por cada ciudad existente; valores de prototipo pendientes de balance). La ficha muestra coste,
  saldo resultante y precio de la siguiente; solo su botón cobra. El **+** se ilumina cuando puedes pagarla.
- Fundar (comprar una ciudad) y renovar (prestigio) son acciones distintas.
- **‹ / ›** cambia de ciudad y vuelve al principio/final al llegar al extremo.
- Cada ciudad mantiene dinero, edificios, mejoras, efectos y pagos pendientes.
  Las demás siguen produciendo mientras juegas; los efectos temporales caducan.
- Reputación, monedas doradas, logros y estadísticas generales son compartidos.
- El prestigio reinicia solo la ciudad seleccionada; no afecta a las otras ciudades.
- Los eventos con una decisión pendiente deben resolverse antes de cambiar de ciudad.
- Las partidas anteriores se convierten automáticamente en la primera ciudad.
  Las ciudades ya creadas se conservan sin deudas; la reputación ya cobrada en partidas antiguas
  se reparte entre ciudades para que no pueda reclamarse dos veces.

### Opciones (Menú → Options)
Efectos visuales, formato de números (1.23M / 1.23e6), volumen general/música/efectos
y reiniciar la partida.

### Guardado
Automático cada 10 s y al cerrar. Al volver ganas el 50 % (75 % con Night Owl)
de tu producción del tiempo fuera, máximo 8 h. El resumen de bienvenida desglosa lo ganado
por ciudad y recuerda la eficiencia y el límite aplicados.

## Exportar a Windows
Selecciona **Project → Export → Windows Desktop → Export Project**.
El preset genera `build/windows/MoneyClicker.exe` con el paquete incluido.
Instala primero las plantillas de exportación de tu versión de Godot.

## Exportar a web (itch.io)
Ya hay un preset **Web** en `export_presets.cfg` (sin hilos, compatible con itch.io).
1. En Godot: *Editor → Manage Export Templates → Download and Install* (solo la primera vez).
2. *Project → Export → Web → Export Project* → se genera `build/web/index.html`.
3. Comprime la carpeta `build/web` en un .zip y súbelo a itch.io como juego HTML5.

## Diseño y próximas mejoras

La [investigación de diseño de incrementales](docs/INVESTIGACION_DISENO_INCREMENTALES.md) reúne referencias, GDD públicos, diagnóstico del juego y propuestas de balance. La sección 20 resume qué propuestas están ya implementadas (fases 1 y 2: coste de fundación, prestigio por ciudad, compras múltiples y comparación) y cuáles siguen abiertas.

## Estructura
| Archivo | Qué hace |
|---------|----------|
| `scripts/game.gd` | Economía, compras, prestigio, monedas, eventos, guardado |
| `scripts/game_data.gd` | Contenido: logros, mejoras de Reputación y eventos |
| `scripts/shop_button.gd` + `scenes/shop_button.tscn` | Datos de cada edificio y su botón |
| `scripts/building_row.gd` + `scenes/building_row.tscn` | Calle: edificios, $/s, nubes, día/noche |
| `scripts/traffic.gd` | Coches y farolas |
| `scripts/golden_coin.gd` + `scenes/golden_coin.tscn` | Monedas especiales |
| `scripts/hud.gd`, `scripts/pie.gd` | Interfaz, avisos y ventanas de eventos |
| `scripts/menu.gd` | Menú con pestañas (se construye por código) |
| `scripts/music.gd` | Música chiptune generada por código (placeholder) |
| `scripts/fx.gd`, `scripts/floating_text.gd` | Partículas y textos flotantes |
| `scripts/clickable.gd`, `scripts/frame.gd`, `scripts/fmt.gd`, `scripts/placeholder.gd` | Utilidades |

Costes, ingresos, ritmos, sinergias, nombres de mejoras, colores de placeholder y
sprites de cada edificio se editan desde el inspector (cada `ShopButton` en `main.tscn`).
Para dar arte a Banco y Casino basta con asignar `button_texture` y `building_texture`.
Para usar música real, pon un `.ogg` en el nodo `Music` y quítale el script.

Para empezar de cero: Menú → Options → Reset game.

## Comprobaciones
- `godot --headless --path ClickerGodot --script res://tests/test_world.gd`:
  ciudades independientes, coste de fundación, compras múltiples, producción y efectos, guardado, migraciones (v2 y v3) y prestigio por ciudad.
- `godot --path ClickerGodot --script res://tests/test_desktop.gd`:
  flags de ventana, tamaño, posición, guardado del widget y retorno a normal en Windows.
- `godot --path ClickerGodot --script res://tests/preview_widget.gd`:
  vista interactiva con dos ciudades de prueba; no lee ni modifica tu partida.
- `godot --headless --path ClickerGodot --script res://tools/balance_sim.gd`:
  simulador de balance (~30 min). Bots con tres perfiles de jugador, matriz de precios de fundación
  y prestigio; escribe `docs/SIMULACION_BALANCE.md`. Con `-- --probe=Activo,renew,found` ejecuta
  un solo escenario en segundos. Conclusiones en la sección 21 de la investigación.
  `-- --suite=prestige` compara fórmulas de prestigio y monedas (~20 min) y escribe
  `docs/SIMULACION_PRESTIGIO.md`; conclusiones en la sección 22.
  `-- --suite=empire` compara la Reputación por ciudad con la de imperio, el tope de monedas y los
  precios de fundación (~5 min) y escribe `docs/SIMULACION_IMPERIO.md`; conclusiones en la sección 23.
