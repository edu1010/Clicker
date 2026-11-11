# Simulación de balance — MoneyClicker

Generado por `tools/balance_sim.gd` el 2026-11-10. No editar a mano: volver a ejecutar el simulador.

## Supuestos

- Economía leída de `main.tscn`, `game.gd` y `shop_button.gd`; horizonte de 72 h de reloj.
- **Activo:** presente siempre, 2 clics/s (cota superior de juego activo).
- **Espaciado:** widget abierto; mira 1 min cada 30 min y hace 2 clics/s mientras mira.
- **Sesiones:** dos sesiones de 1 h al día; cierra el juego entre sesiones.
- Compra: entre todas las opciones (1 edificio, edificios hasta el siguiente hito, mejora de edificio, Better Ink, Golden Touch) elige la de menor `espera + precio / aumento de $/s`, recalculando toda la ciudad (hitos y sinergias).
- Los clics y las monedas se hacen en la ciudad más nueva mientras produce menos del 10 % de la mejor; después, en la mejor.
- Monedas especiales como valor esperado (Lucky, Frenzy, Click Frenzy, cadenas, rojas) cuando el jugador está presente. Sin eventos ni logros.
- Fundar: la ciudad que más produce ahorra cuando el precio cabe en `X` segundos de su producción, y funda al poder pagarlo.
- Renovar: la ciudad con más reputación pendiente se renueva cuando duplica la reputación total (`pendiente >= max(1, reputación)`). Las mejoras de Reputación se compran en cuanto se pueden pagar.

## 1. Ritmo de una ciudad (sin fundar ni renovar)

| Perfil | 1.ª Fábrica | 1.er Hospital | 1.er Banco | 1.er Casino | $/s 1 h | $/s 4 h | $/s 24 h | $/s 72 h |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Activo | 26 s | 55 s | 1 min | 2 min | 91.6M | 149M | 160M | 160M |
| Espaciado | 26 s | 55 s | 30 min | 30 min | 3.53M | 71.1M | 159M | 195M |
| Sesiones | 26 s | 55 s | 1 min | 2 min | 91.6M | 91.6M | 141M | 160M |

**Origen del dinero y estrategia dominante (72 h):**

| Perfil | Edificios | Clics | Monedas | Offline | Compras de edificio que son el más caro desbloqueado | $/s 24 h sin monedas | Efecto de las monedas a 24 h |
|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | 24 % | 15 % | 61 % | 0 % | 19 % | 107M | x1.5 |
| Espaciado | 91 % | 2 % | 8 % | 0 % | 21 % | 99.3M | x1.6 |
| Sesiones | 12 % | 7 % | 31 % | 50 % | 19 % | 61.1M | x2.3 |

Las compras se reparten así en el perfil Activo: building 419, upgrade 20, boost 10, ink 7.

## 2. Coste de fundar ciudades

Comparación con no fundar nunca (mismo perfil, renovando). «Ganado» = dinero total generado en 72 h. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.

### Perfil Activo

Sin fundar: ganado 72 h 915T $, reputación 256, $/s final 697M.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 3 min | 15 | 15 | +120 % | 160 | 3 min |
| 100K | 5 | 10 min | 3 min | 11 | 11 | +59 % | 128 | 3 min |
| 100K | 8 | 10 min | 3 min | 9 | 9 | +37 % | 128 | 4 min |
| 250K | 3 | 10 min | 2 min | 14 | 14 | +80 % | 128 | 3 min |
| 250K | 5 | 10 min | 2 min | 10 | 10 | +49 % | 128 | 3 min |
| 250K | 8 | 10 min | 2 min | 8 | 8 | +38 % | 128 | 3 min |
| 1.00M | 3 | 10 min | 3 min | 13 | 13 | +80 % | 128 | 4 min |
| 1.00M | 5 | 10 min | 3 min | 9 | 10 | +41 % | 256 | 3 min |
| 1.00M | 8 | 10 min | 3 min | 8 | 8 | +39 % | 160 | 3 min |
| 100K | 3 | 1.0 h | 7 min | 17 | 17 | +107 % | 128 | 3 min |
| 100K | 5 | 1.0 h | 7 min | 12 | 12 | +67 % | 128 | 3 min |
| 100K | 8 | 1.0 h | 7 min | 9 | 9 | +38 % | 128 | 3 min |
| 250K | 3 | 1.0 h | 11 min | 16 | 16 | +128 % | 160 | 3 min |
| 250K | 5 | 1.0 h | 11 min | 11 | 11 | +69 % | 128 | 3 min |
| 250K | 8 | 1.0 h | 11 min | 9 | 9 | +40 % | 256 | 4 min |
| 1.00M | 3 | 1.0 h | 3 min | 15 | 15 | +98 % | 128 | 5 min |
| 1.00M | 5 | 1.0 h | 3 min | 10 | 11 | +97 % | 256 | 6 min |
| 1.00M | 8 | 1.0 h | 3 min | 8 | 8 | +40 % | 160 | 4 min |

### Perfil Espaciado

Sin fundar: ganado 72 h 85.7T $, reputación 104, $/s final 399M.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 30 min | 14 | 15 | +629 % | 36 | 60 min |
| 100K | 5 | 10 min | 30 min | 10 | 11 | +540 % | 72 | 59 min |
| 100K | 8 | 10 min | 30 min | 8 | 8 | +423 % | 72 | 30 min |
| 250K | 3 | 10 min | 30 min | 13 | 14 | +730 % | 48 | 60 min |
| 250K | 5 | 10 min | 30 min | 10 | 10 | +528 % | 52 | 60 min |
| 250K | 8 | 10 min | 30 min | 8 | 8 | +419 % | 64 | 59 min |
| 1.00M | 3 | 10 min | 30 min | 12 | 12 | +625 % | 40 | 59 min |
| 1.00M | 5 | 10 min | 30 min | 9 | 9 | +466 % | 80 | 60 min |
| 1.00M | 8 | 10 min | 30 min | 7 | 7 | +361 % | 84 | 30 min |
| 100K | 3 | 1.0 h | 1.0 h | 16 | 16 | +790 % | 40 | 59 min |
| 100K | 5 | 1.0 h | 1.0 h | 11 | 12 | +579 % | 40 | 60 min |
| 100K | 8 | 1.0 h | 1.0 h | 9 | 9 | +459 % | 48 | 1.0 h |
| 250K | 3 | 1.0 h | 1.0 h | 15 | 15 | +767 % | 32 | 59 min |
| 250K | 5 | 1.0 h | 1.0 h | 11 | 11 | +545 % | 72 | 59 min |
| 250K | 8 | 1.0 h | 1.0 h | 9 | 9 | +443 % | 80 | 59 min |
| 1.00M | 3 | 1.0 h | 30 min | 14 | 14 | +728 % | 56 | 1.0 h |
| 1.00M | 5 | 1.0 h | 30 min | 10 | 10 | +506 % | 80 | 60 min |
| 1.00M | 8 | 1.0 h | 30 min | 8 | 8 | +407 % | 84 | 30 min |

## 3. Renovar (prestigio)

Con el precio actual de fundación (250K × 8) y ahorro si cabe en 10 min. «Recuperación» = mediana del tiempo que tarda la ciudad renovada en volver a producir lo que producía antes.

| Perfil | Renovar | 1.ª renovación | Renovaciones | Reputación 72 h | Ciudades 72 h | Ganado 72 h | $/s 72 h | Recuperación |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | no | — | 0 | 0 | 8 | 482T | 1.56B | — |
| Activo | sí | 4 min | 8 | 128 | 8 | 1.26Qa | 3.12B | 20 min |
| Espaciado | no | — | 0 | 0 | 8 | 325T | 1.57B | — |
| Espaciado | sí | 1.0 h | 6 | 64 | 8 | 445T | 2.25B | 1.5 h |
| Sesiones | no | — | 0 | 0 | 8 | 115T | 1.28B | — |
| Sesiones | sí | 4 min | 7 | 64 | 8 | 265T | 2.17B | 20 min |
