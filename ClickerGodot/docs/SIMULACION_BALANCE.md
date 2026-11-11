# Simulación de balance — MoneyClicker

Generado por `tools/balance_sim.gd` el 2026-11-11. No editar a mano: volver a ejecutar el simulador.

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
| Activo | 26 s | 1 min | 2 min | 2 min | 73.1M | 148M | 270M | 270M |
| Espaciado | 26 s | 30 min | 30 min | 31 min | 70.2K | 23.3M | 233M | 410M |
| Sesiones | 26 s | 1 min | 2 min | 2 min | 73.1M | 73.1M | 119M | 270M |

**Origen del dinero y estrategia dominante (72 h):**

| Perfil | Edificios | Clics | Monedas | Offline | Compras de edificio que son el más caro desbloqueado | $/s 24 h sin monedas | Efecto de las monedas a 24 h |
|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | 24 % | 14 % | 61 % | 0 % | 19 % | 159M | x1.7 |
| Espaciado | 91 % | 2 % | 8 % | 0 % | 19 % | 99.0M | x2.4 |
| Sesiones | 12 % | 7 % | 30 % | 51 % | 19 % | 49.9M | x2.4 |

Las compras se reparten así en el perfil Activo: building 412, ink 7, upgrade 26, boost 10.

## 2. Coste de fundar ciudades

Comparación con no fundar nunca (mismo perfil, renovando). «Ganado» = dinero total generado en 72 h. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.

### Perfil Activo

Sin fundar: ganado 72 h 2.28Qa $, reputación 512, $/s final 2.51B.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 2 min | 16 | 17 | +248 % | 256 | 7 min |
| 100K | 5 | 10 min | 2 min | 11 | 12 | +192 % | 256 | 6 min |
| 100K | 8 | 10 min | 2 min | 9 | 10 | +186 % | 512 | 7 min |
| 250K | 3 | 10 min | 3 min | 15 | 16 | +249 % | 256 | 6 min |
| 250K | 5 | 10 min | 3 min | 11 | 12 | +189 % | 256 | 7 min |
| 250K | 8 | 10 min | 3 min | 9 | 9 | +142 % | 256 | 9 min |
| 1.00M | 3 | 10 min | 4 min | 14 | 15 | +222 % | 256 | 12 min |
| 1.00M | 5 | 10 min | 4 min | 10 | 11 | +149 % | 256 | 14 min |
| 1.00M | 8 | 10 min | 4 min | 8 | 9 | +121 % | 256 | 16 min |
| 100K | 3 | 1.0 h | 7 min | 17 | 19 | +229 % | 256 | 10 min |
| 100K | 5 | 1.0 h | 7 min | 12 | 13 | +235 % | 256 | 12 min |
| 100K | 8 | 1.0 h | 7 min | 10 | 11 | +173 % | 256 | 13 min |
| 250K | 3 | 1.0 h | 9 min | 16 | 18 | +249 % | 256 | 11 min |
| 250K | 5 | 1.0 h | 9 min | 12 | 13 | +195 % | 256 | 16 min |
| 250K | 8 | 1.0 h | 9 min | 10 | 10 | +189 % | 256 | 10 min |
| 1.00M | 3 | 1.0 h | 6 min | 15 | 17 | +225 % | 256 | 20 min |
| 1.00M | 5 | 1.0 h | 6 min | 11 | 12 | +162 % | 256 | 16 min |
| 1.00M | 8 | 1.0 h | 6 min | 9 | 10 | +205 % | 512 | 16 min |

### Perfil Espaciado

Sin fundar: ganado 72 h 116T $, reputación 172, $/s final 1.12B.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 30 min | 15 | 15 | +898 % | 72 | 1.0 h |
| 100K | 5 | 10 min | 30 min | 11 | 11 | +770 % | 72 | 1.0 h |
| 100K | 8 | 10 min | 30 min | 8 | 9 | +654 % | 76 | 1.0 h |
| 250K | 3 | 10 min | 31 min | 14 | 15 | +984 % | 64 | 1.5 h |
| 250K | 5 | 10 min | 31 min | 10 | 10 | +707 % | 72 | 1.0 h |
| 250K | 8 | 10 min | 31 min | 8 | 8 | +499 % | 92 | 1.0 h |
| 1.00M | 3 | 10 min | 1.5 h | 13 | 13 | +959 % | 64 | 1.5 h |
| 1.00M | 5 | 10 min | 1.5 h | 9 | 10 | +748 % | 72 | 1.5 h |
| 1.00M | 8 | 10 min | 1.5 h | 7 | 8 | +619 % | 64 | 1.0 h |
| 100K | 3 | 1.0 h | 1.0 h | 16 | 17 | +1036 % | 40 | 1.5 h |
| 100K | 5 | 1.0 h | 1.0 h | 12 | 12 | +762 % | 76 | 1.0 h |
| 100K | 8 | 1.0 h | 1.0 h | 9 | 10 | +602 % | 80 | 1.0 h |
| 250K | 3 | 1.0 h | 1.0 h | 15 | 16 | +988 % | 64 | 1.5 h |
| 250K | 5 | 1.0 h | 1.0 h | 11 | 12 | +729 % | 80 | 1.0 h |
| 250K | 8 | 1.0 h | 1.0 h | 9 | 9 | +542 % | 64 | 1.0 h |
| 1.00M | 3 | 1.0 h | 1.5 h | 14 | 15 | +1053 % | 56 | 1.5 h |
| 1.00M | 5 | 1.0 h | 1.5 h | 10 | 11 | +769 % | 96 | 1.5 h |
| 1.00M | 8 | 1.0 h | 1.5 h | 8 | 9 | +646 % | 56 | 1.5 h |

## 3. Renovar (prestigio)

Con el precio actual de fundación (250K × 8) y ahorro si cabe en 10 min. «Recuperación» = mediana del tiempo que tarda la ciudad renovada en volver a producir lo que producía antes.

| Perfil | Renovar | 1.ª renovación | Renovaciones | Reputación 72 h | Ciudades 72 h | Ganado 72 h | $/s 72 h | Recuperación |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | no | — | 0 | 0 | 8 | 814T | 3.28B | — |
| Activo | sí | 7 min | 9 | 256 | 9 | 5.52Qa | 28.7B | 2.1 h |
| Espaciado | no | — | 0 | 0 | 8 | 506T | 3.28B | — |
| Espaciado | sí | 1.5 h | 7 | 92 | 8 | 694T | 4.70B | 4.0 h |
| Sesiones | no | — | 0 | 0 | 8 | 116T | 1.85B | — |
| Sesiones | sí | 7 min | 8 | 128 | 8 | 267T | 3.27B | 11.3 h |
