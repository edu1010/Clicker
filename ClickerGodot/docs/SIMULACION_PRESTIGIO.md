# Simulación de alternativas de prestigio — MoneyClicker

Generado por `tools/balance_sim.gd -- --suite=prestige` el 2026-11-10. Mismos bots y supuestos que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md): renovar cuando la reputación pendiente duplica la total, fundar con el precio actual (250K × 5) cuando cabe en 10 min de producción, horizonte de 72 h.

- **Renovar ×:** dinero ganado en 72 h renovando frente a no renovar nunca (ambos fundando).
- **Fundar:** dinero ganado en 72 h fundando frente a no fundar (ambos renovando).
- **Recuperación:** mediana del tiempo que tarda una ciudad renovada en volver a producir lo de antes.
- **Monedas corregidas:** +0,5 % permanente por moneda (en vez de +2 %) y Click Frenzy calculado sin Golden Touch.

## Monedas actuales

Sin renovar, Activo: ganado 157Qa $, 13 ciudades, $/s final 532B.
Sin renovar, Espaciado: ganado 952T $, 10 ciudades, $/s final 6.40B.

| Fórmula | Perfil | 1.ª renovación | Renovaciones | Recuperación | Reputación 72 h | Ganado 72 h | Renovar × | Fundar | Ciudades 72 h |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Actual: √(ganado/100K), +1 %/punto | Activo | 2 min | 38 | 4 min | 2.23T | 358Oc $ | ×2.28T | +329 % | 31 |
| Actual: √(ganado/100K), +1 %/punto | Espaciado | 30 min | 21 | 30 min | 254M | 45.1Sx $ | ×47.4M | +3117 % | 22 |
| √(ganado/10M), +1 %/punto | Activo | 4 min | 32 | 8 min | 5.75B | 433Sp $ | ×2.77B | +359 % | 26 |
| √(ganado/10M), +1 %/punto | Espaciado | 30 min | 19 | 30 min | 924K | 44.0Qi $ | ×46.2K | +3877 % | 17 |
| √(ganado/1B), +1 %/punto | Activo | 6 min | 25 | 25 min | 21.9M | 339Sx $ | ×2.17M | +265 % | 22 |
| √(ganado/1B), +1 %/punto | Espaciado | 1.5 h | 11 | 1.5 h | 3.34K | 56.8Qa $ | ×59.7 | +2726 % | 13 |
| ∛(ganado/100K), +1 %/punto | Activo | 2 min | 19 | 6 min | 299K | 5.66Sx $ | ×36.1K | +294 % | 19 |
| ∛(ganado/100K), +1 %/punto | Espaciado | 30 min | 10 | 30 min | 8.23K | 294Qa $ | ×308.5 | +2237 % | 14 |
| ∛(ganado/10M), +1 %/punto | Activo | 4 min | 16 | 21 min | 33.1K | 312Qi $ | ×1.99K | +222 % | 18 |
| ∛(ganado/10M), +1 %/punto | Espaciado | 30 min | 10 | 1.5 h | 986 | 15.9Qa $ | ×16.7 | +1423 % | 13 |
| √(ganado/100K), +10 %·√reputación | Activo | 2 min | 24 | 9 min | 90.9M | 1.28Sx $ | ×8.20K | +84 % | 18 |
| √(ganado/100K), +10 %·√reputación | Espaciado | 30 min | 15 | 30 min | 880K | 316Qa $ | ×332.2 | +1052 % | 14 |

## Monedas corregidas

Sin renovar, Activo: ganado 12.3Qa $, 12 ciudades, $/s final 87.9B.
Sin renovar, Espaciado: ganado 396T $, 10 ciudades, $/s final 2.53B.

| Fórmula | Perfil | 1.ª renovación | Renovaciones | Recuperación | Reputación 72 h | Ganado 72 h | Renovar × | Fundar | Ciudades 72 h |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Actual: √(ganado/100K), +1 %/punto | Activo | 2 min | 31 | 2 min | 7.23B | 43.5Sp $ | ×3.53B | +2298 % | 25 |
| Actual: √(ganado/100K), +1 %/punto | Espaciado | 30 min | 18 | 30 min | 47.2M | 1.96Sx $ | ×4.96M | +13180 % | 19 |
| √(ganado/10M), +1 %/punto | Activo | 4 min | 26 | 5 min | 43.1M | 44.2Sx $ | ×3.59M | +1297 % | 22 |
| √(ganado/10M), +1 %/punto | Espaciado | 30 min | 17 | 30 min | 165K | 1.55Qi $ | ×3.93K | +10458 % | 15 |
| √(ganado/1B), +1 %/punto | Activo | 7 min | 18 | 31 min | 131K | 48.5Qi $ | ×3.94K | +1287 % | 17 |
| √(ganado/1B), +1 %/punto | Espaciado | 1.5 h | 9 | 2.0 h | 836 | 3.63Qa $ | ×9.2 | +3140 % | 12 |
| ∛(ganado/100K), +1 %/punto | Activo | 2 min | 16 | 5 min | 37.9K | 22.9Qi $ | ×1.86K | +905 % | 17 |
| ∛(ganado/100K), +1 %/punto | Espaciado | 30 min | 9 | 30 min | 3.68K | 35.6Qa $ | ×90.0 | +4646 % | 13 |
| ∛(ganado/10M), +1 %/punto | Activo | 4 min | 13 | 17 min | 4.10K | 1.20Qi $ | ×97.1 | +846 % | 15 |
| ∛(ganado/10M), +1 %/punto | Espaciado | 30 min | 9 | 1.5 h | 416 | 2.09Qa $ | ×5.3 | +1850 % | 11 |
| √(ganado/100K), +10 %·√reputación | Activo | 2 min | 22 | 9 min | 6.44M | 14.9Qi $ | ×1.21K | +592 % | 16 |
| √(ganado/100K), +10 %·√reputación | Espaciado | 30 min | 13 | 30 min | 263K | 59.4Qa $ | ×150.1 | +2655 % | 13 |

## Ventaja del juego activo

Dinero ganado en 72 h por el perfil Activo dividido entre el del perfil Espaciado (ambos renovando y fundando).

| Fórmula | Monedas | Activo / Espaciado |
|---|---|---:|
| Actual: √(ganado/100K), +1 %/punto | actuales | ×7.93M |
| √(ganado/10M), +1 %/punto | actuales | ×9.85M |
| √(ganado/1B), +1 %/punto | actuales | ×5.97M |
| ∛(ganado/100K), +1 %/punto | actuales | ×19.3K |
| ∛(ganado/10M), +1 %/punto | actuales | ×19.6K |
| √(ganado/100K), +10 %·√reputación | actuales | ×4.06K |
| Actual: √(ganado/100K), +1 %/punto | corregidas | ×22.1K |
| √(ganado/10M), +1 %/punto | corregidas | ×28.5K |
| √(ganado/1B), +1 %/punto | corregidas | ×13.4K |
| ∛(ganado/100K), +1 %/punto | corregidas | ×641.5 |
| ∛(ganado/10M), +1 %/punto | corregidas | ×572.0 |
| √(ganado/100K), +10 %·√reputación | corregidas | ×250.2 |
