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
| Activo | 26 s | 55 s | 1 min | 2 min | 265M | 982M | 13.5B | 43.2B |
| Espaciado | 26 s | 55 s | 30 min | 30 min | 5.93M | 74.2M | 244M | 640M |
| Sesiones | 26 s | 55 s | 1 min | 2 min | 265M | 265M | 544M | 2.51B |

**Origen del dinero y estrategia dominante (72 h):**

| Perfil | Edificios | Clics | Monedas | Offline | Compras de edificio que son el más caro desbloqueado | $/s 24 h sin monedas | Efecto de las monedas a 24 h |
|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | 5 % | 4 % | 91 % | 0 % | 20 % | 107M | x126.5 |
| Espaciado | 66 % | 1 % | 33 % | 0 % | 21 % | 99.3M | x2.5 |
| Sesiones | 5 % | 3 % | 69 % | 23 % | 22 % | 61.1M | x8.9 |

Las compras se reparten así en el perfil Activo: building 563, upgrade 20, boost 13, ink 10.

## 2. Coste de fundar ciudades

Comparación con no fundar nunca (mismo perfil, renovando). «Ganado» = dinero total generado en 72 h. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.

### Perfil Activo

Sin fundar: ganado 72 h 83.4Oc $, reputación 600829579648, $/s final 22.1Sx.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 4 min | 40 | 45 | +423 % | 1723543678119 | 8 min |
| 100K | 5 | 10 min | 4 min | 28 | 31 | +255 % | 1241169868694 | 6 min |
| 100K | 8 | 10 min | 4 min | 22 | 24 | +229 % | 1158467957762 | 6 min |
| 250K | 3 | 10 min | 4 min | 39 | 44 | +387 % | 2134708817060 | 7 min |
| 250K | 5 | 10 min | 4 min | 27 | 31 | +329 % | 2232139263757 | 7 min |
| 250K | 8 | 10 min | 4 min | 21 | 24 | +300 % | 2295320133062 | 6 min |
| 1.00M | 3 | 10 min | 6 min | 38 | 43 | +335 % | 2223286707648 | 8 min |
| 1.00M | 5 | 10 min | 6 min | 26 | 29 | +252 % | 1258143764858 | 8 min |
| 1.00M | 8 | 10 min | 6 min | 21 | 23 | +226 % | 1198575851349 | 7 min |
| 100K | 3 | 1.0 h | 14 min | 42 | 47 | +341 % | 2226388776861 | 13 min |
| 100K | 5 | 1.0 h | 14 min | 29 | 32 | +326 % | 2159865476739 | 12 min |
| 100K | 8 | 1.0 h | 14 min | 23 | 25 | +369 % | 2194217763311 | 13 min |
| 250K | 3 | 1.0 h | 14 min | 41 | 45 | +320 % | 1577957863920 | 12 min |
| 250K | 5 | 1.0 h | 14 min | 28 | 32 | +347 % | 2072575337710 | 12 min |
| 250K | 8 | 1.0 h | 14 min | 22 | 25 | +224 % | 1193245749446 | 12 min |
| 1.00M | 3 | 1.0 h | 19 min | 40 | 44 | +287 % | 1219985864713 | 13 min |
| 1.00M | 5 | 1.0 h | 19 min | 27 | 31 | +396 % | 2176582895881 | 13 min |
| 1.00M | 8 | 1.0 h | 19 min | 22 | 24 | +242 % | 1328168659189 | 10 min |

### Perfil Espaciado

Sin fundar: ganado 72 h 1.40Sx $, reputación 83329018, $/s final 13.1Qa.

| Base | Factor | Ahorra si cabe en | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Ganado 72 h vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 10 min | 1.5 h | 28 | 32 | +6023 % | 217272939 | 30 min |
| 100K | 5 | 10 min | 1.5 h | 20 | 22 | +3806 % | 182568073 | 30 min |
| 100K | 8 | 10 min | 1.5 h | 16 | 17 | +3360 % | 205253375 | 30 min |
| 250K | 3 | 10 min | 1.0 h | 27 | 31 | +4644 % | 238750240 | 30 min |
| 250K | 5 | 10 min | 1.0 h | 19 | 22 | +3117 % | 253884531 | 30 min |
| 250K | 8 | 10 min | 1.0 h | 15 | 17 | +2748 % | 291522118 | 30 min |
| 1.00M | 3 | 10 min | 1.5 h | 25 | 30 | +4734 % | 208047076 | 30 min |
| 1.00M | 5 | 10 min | 1.5 h | 18 | 21 | +3000 % | 173478956 | 30 min |
| 1.00M | 8 | 10 min | 1.5 h | 14 | 16 | +3116 % | 246148365 | 30 min |
| 100K | 3 | 1.0 h | 2.0 h | 30 | 33 | +5274 % | 193392360 | 30 min |
| 100K | 5 | 1.0 h | 2.0 h | 20 | 23 | +3982 % | 226026016 | 30 min |
| 100K | 8 | 1.0 h | 2.0 h | 16 | 18 | +3302 % | 222229519 | 30 min |
| 250K | 3 | 1.0 h | 3.0 h | 29 | 32 | +4747 % | 177760866 | 30 min |
| 250K | 5 | 1.0 h | 3.0 h | 20 | 23 | +4340 % | 285107335 | 30 min |
| 250K | 8 | 1.0 h | 3.0 h | 16 | 18 | +3129 % | 302315564 | 30 min |
| 1.00M | 3 | 1.0 h | 1.5 h | 27 | 31 | +4880 % | 255241630 | 30 min |
| 1.00M | 5 | 1.0 h | 1.5 h | 19 | 22 | +3598 % | 214225179 | 30 min |
| 1.00M | 8 | 1.0 h | 1.5 h | 15 | 17 | +3080 % | 198027965 | 30 min |

## 3. Renovar (prestigio por ciudad)

Con el precio actual de fundación (250K × 5) y ahorro si cabe en 10 min. «Recuperación» = mediana del tiempo que tarda la ciudad renovada en volver a producir lo que producía antes.

| Perfil | Renovar | 1.ª renovación | Renovaciones | Reputación 72 h | Ciudades 72 h | Ganado 72 h | $/s 72 h | Recuperación |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Activo | no | — | 0 | 0 | 13 | 157Qa | 532B | — |
| Activo | sí | 2 min | 38 | 2232139263757 | 31 | 358Oc | 2.44Sp | 4 min |
| Espaciado | no | — | 0 | 0 | 10 | 952T | 6.40B | — |
| Espaciado | sí | 30 min | 21 | 253884531 | 22 | 45.1Sx | 1.02Qi | 30 min |
| Sesiones | no | — | 0 | 0 | 11 | 1.21Qa | 16.5B | — |
| Sesiones | sí | 2 min | 28 | 2430220644 | 24 | 1.26Sp | 26.9Qi | 1 min |
