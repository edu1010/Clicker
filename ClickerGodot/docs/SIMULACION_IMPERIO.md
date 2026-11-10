# Simulación de Reputación de imperio y tope de monedas — MoneyClicker

Generado por `tools/balance_sim.gd -- --suite=empire` el 2026-11-10. Mismos bots que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md); prestigio ∛(ganado/10M) con +1 % por punto (candidato de la sección 22); Click Frenzy sin Golden Touch; horizonte de 72 h.

- **Ciudad:** cada ciudad tiene su propia raíz (como el juego ahora).
- **Imperio:** la raíz se calcula sobre lo ganado por todas las ciudades; al renovar una ciudad se cobra la parte pendiente proporcional a lo que ganó desde su última renovación.
- **Renovar ×:** ganado renovando frente a no renovar (ambos fundando). **Fundar:** ganado fundando frente a no fundar (ambos renovando).

## 1. Ámbito de la Reputación y monedas

Precio de fundación actual (250K × 5), ahorrando cuando cabe en 10 min de producción.

| Ámbito | Monedas | Perfil | 1.ª renovación | Renovaciones | Recuperación | Reputación 72 h | Ganado 72 h | Renovar × | Fundar | Ciudades 72 h |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Ciudad | +0,5 %/moneda sin tope | Activo | 4 min | 13 | 17 min | 4.10K | 1.20Qi $ | ×97.1 | +846 % | 15 |
| Ciudad | +0,5 %/moneda sin tope | Espaciado | 30 min | 9 | 1.5 h | 416 | 2.09Qa $ | ×5.3 | +1850 % | 11 |
| Imperio | +0,5 %/moneda sin tope | Activo | 4 min | 11 | 49 min | 1.02K | 265Qa $ | ×21.5 | +110 % | 14 |
| Imperio | +0,5 %/moneda sin tope | Espaciado | 1.0 h | 5 | 2.5 h | 52 | 627T $ | ×1.6 | +484 % | 10 |
| Ciudad | +2 %/moneda, tope +50 % | Activo | 4 min | 10 | 12 min | 512 | 5.22Qa $ | ×9.4 | +470 % | 11 |
| Ciudad | +2 %/moneda, tope +50 % | Espaciado | 30 min | 9 | 1.5 h | 476 | 1.28Qa $ | ×3.3 | +1395 % | 11 |
| Imperio | +2 %/moneda, tope +50 % | Activo | 4 min | 8 | 51 min | 128 | 1.36Qa $ | ×2.5 | +49 % | 10 |
| Imperio | +2 %/moneda, tope +50 % | Espaciado | 1.0 h | 5 | 2.0 h | 52 | 538T $ | ×1.4 | +528 % | 10 |
| Ciudad | sin bonus permanente | Activo | 4 min | 10 | 20 min | 576 | 1.84Qa $ | ×5.7 | +259 % | 11 |
| Ciudad | sin bonus permanente | Espaciado | 30 min | 8 | 1.0 h | 200 | 715T $ | ×3.1 | +1367 % | 10 |
| Imperio | sin bonus permanente | Activo | 5 min | 8 | 1.3 h | 128 | 852T $ | ×2.6 | +67 % | 10 |
| Imperio | sin bonus permanente | Espaciado | 1.0 h | 5 | 3.0 h | 52 | 305T $ | ×1.3 | +526 % | 10 |

**Ventaja del juego activo** (ganado por Activo ÷ ganado por Espaciado, ambos renovando y fundando):

| Ámbito | Monedas | Activo / Espaciado |
|---|---|---:|
| Ciudad | +0,5 %/moneda sin tope | ×572.0 |
| Imperio | +0,5 %/moneda sin tope | ×422.9 |
| Ciudad | +2 %/moneda, tope +50 % | ×4.1 |
| Imperio | +2 %/moneda, tope +50 % | ×2.5 |
| Ciudad | sin bonus permanente | ×2.6 |
| Imperio | sin bonus permanente | ×2.8 |

## 2. Precio de fundación con Reputación de imperio

Monedas: +2 %/moneda, tope +50 %. «Recupera» = mediana del tiempo que tarda cada ciudad nueva en generar lo que costó.

### Perfil Activo

Sin fundar: ganado 72 h 915T $, reputación 256.

| Base | Factor | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Fundar vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 3 min | 15 | 15 | +120 % | 160 | 3 min |
| 100K | 5 | 3 min | 11 | 11 | +59 % | 128 | 3 min |
| 100K | 8 | 3 min | 9 | 9 | +37 % | 128 | 4 min |
| 250K | 3 | 2 min | 14 | 14 | +80 % | 128 | 3 min |
| 250K | 5 | 2 min | 10 | 10 | +49 % | 128 | 3 min |
| 250K | 8 | 2 min | 8 | 8 | +38 % | 128 | 3 min |
| 1.00M | 3 | 3 min | 13 | 13 | +80 % | 128 | 4 min |
| 1.00M | 5 | 3 min | 9 | 10 | +41 % | 256 | 3 min |
| 1.00M | 8 | 3 min | 8 | 8 | +39 % | 160 | 3 min |

### Perfil Espaciado

Sin fundar: ganado 72 h 85.7T $, reputación 104.

| Base | Factor | 2.ª ciudad | Ciudades 24 h | Ciudades 72 h | Fundar vs no fundar | Reputación 72 h | Recupera |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 100K | 3 | 30 min | 14 | 15 | +629 % | 36 | 60 min |
| 100K | 5 | 30 min | 10 | 11 | +540 % | 72 | 59 min |
| 100K | 8 | 30 min | 8 | 8 | +423 % | 72 | 30 min |
| 250K | 3 | 30 min | 13 | 14 | +730 % | 48 | 60 min |
| 250K | 5 | 30 min | 10 | 10 | +528 % | 52 | 60 min |
| 250K | 8 | 30 min | 8 | 8 | +419 % | 64 | 59 min |
| 1.00M | 3 | 30 min | 12 | 12 | +625 % | 40 | 59 min |
| 1.00M | 5 | 30 min | 9 | 9 | +466 % | 80 | 60 min |
| 1.00M | 8 | 30 min | 7 | 7 | +361 % | 84 | 30 min |
