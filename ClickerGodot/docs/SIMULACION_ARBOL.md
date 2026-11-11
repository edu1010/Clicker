# Simulación del árbol del imperio y de la producción offline — MoneyClicker

Generado por `tools/balance_sim.gd -- --suite=tree` el 2026-11-11. Mismos bots que [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md), renovando y fundando (ahorro si cabe en 10 min), horizonte de 72 h.

- El bot compara cada rango del árbol con las compras de las ciudades usando la misma puntuación (`espera + coste / aumento de $/s`, con el aumento medido en todo el imperio, incluidos clics y monedas); ahorra para el árbol cuando su mejor rango puntúa mejor que la mejor compra de cualquier ciudad. Franchising, Real Estate y Heritage, que no suben los $/s directamente, cuentan como +5 %, +3 % y +10 % por rango. Mientras ahorra, ninguna ciudad compra otra cosa. Paga con el dinero de todas las ciudades, en proporción a lo que tiene cada una.
- El árbol tiene 48 rangos en 15 nodos. «Escala» multiplica todos los costes de `GameData.empire_tree()` (1 = valores del juego).
- «Ganado vs sin árbol» compara el dinero total de 72 h con el mismo perfil sin árbol.

## 1. Escala de costes

| Escala | Perfil | 1.ª compra | Rangos 1 h | 4 h | 24 h | 72 h | Árbol completo | Gastado en el árbol | Ganado vs sin árbol |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 0.1 | Activo | 6 min | 20 | 25 | 33 | 40 | — | 14.3Qa $ (22 %) | +1075 % |
| 0.1 | Espaciado | 2.5 h | 0 | 2 | 28 | 33 | — | 125T $ (6 %) | +199 % |
| 0.1 | Sesiones | 6 min | 20 | 20 | 23 | 30 | — | 62.4T $ (7 %) | +249 % |
| 0.3 | Activo | 6 min | 20 | 25 | 33 | 38 | — | 6.07Qa $ (9 %) | +1151 % |
| 0.3 | Espaciado | 3.0 h | 0 | 2 | 25 | 29 | — | 187T $ (9 %) | +188 % |
| 0.3 | Sesiones | 6 min | 20 | 20 | 23 | 28 | — | 37.3T $ (5 %) | +204 % |
| 1.0 | Activo | 13 min | 17 | 23 | 28 | 35 | — | 2.75Qa $ (4 %) | +1049 % |
| 1.0 | Espaciado | 3.0 h | 0 | 1 | 24 | 27 | — | 124T $ (6 %) | +187 % |
| 1.0 | Sesiones | 13 min | 17 | 17 | 20 | 25 | — | 8.87T $ (1 %) | +193 % |
| 3.0 | Activo | 14 min | 16 | 21 | 25 | 34 | — | 8.24Qa $ (14 %) | +1003 % |
| 3.0 | Espaciado | 4.0 h | 0 | 0 | 23 | 25 | — | 26.6T $ (1 %) | +189 % |
| 3.0 | Sesiones | 14 min | 16 | 16 | 19 | 25 | — | 26.6T $ (3 %) | +188 % |
| 10.0 | Activo | 17 min | 13 | 20 | 23 | 28 | — | 1.24Qa $ (4 %) | +487 % |
| 10.0 | Espaciado | 4.0 h | 0 | 0 | 21 | 25 | — | 88.7T $ (4 %) | +190 % |
| 10.0 | Sesiones | 17 min | 13 | 13 | 17 | 23 | — | 19.5T $ (3 %) | +165 % |

## 2. Ritmo con los costes del juego (escala 1)

Momento en que se compra el primer y el último rango de cada nodo (— = no llega en 72 h).

| Rama | Nodo | Rangos | Coste del 1.er rango | Activo: primero / último | Espaciado: primero / último |
|---|---|---:|---:|---:|---:|
| Commerce | Trade Network | 5 | 1.00M $ | 13 min / 42 min | 3.0 h / 6.0 h |
| Commerce | Supply Chains | 3 | 10.0B $ | 46 min / 3.1 h | 6.0 h / 11.0 h |
| Commerce | Franchising | 3 | 100T $ | 19.6 h / — | 55.0 h / — |
| Commerce | Global Brand | 2 | 100Qa $ | — / — | — / — |
| Fortune | Lucky Streets | 5 | 3.00M $ | 20 min / 52 min | 4.0 h / 9.5 h |
| Fortune | Midas Odds | 5 | 30.0B $ | 1.4 h / 40.9 h | 11.0 h / — |
| Fortune | Long Party | 3 | 300T $ | 40.9 h / — | — / — |
| Fortune | Golden Vault | 3 | 300Qa $ | — / — | — / — |
| Hands | Ergonomics | 4 | 2.00M $ | 20 min / 46 min | 4.5 h / 6.0 h |
| Hands | Printing Press | 3 | 20.0B $ | 19.9 h / 44.5 h | — / — |
| Hands | Lucky Press | 3 | 200T $ | 41.0 h / — | — / — |
| Logistics | Open All Night | 2 | 5.00M $ | 13 min / 19 min | 4.0 h / 5.0 h |
| Logistics | Real Estate | 3 | 50.0B $ | 1.3 h / 5.5 h | 9.5 h / 22.0 h |
| Logistics | Heritage | 2 | 500T $ | 28.0 h / — | — / — |
| Logistics | Empire HQ | 2 | 500Qa $ | — / — | — / — |

Si el bot Activo prioriza el árbol (lo compra aunque puntúe hasta 3 veces peor que la mejor compra de una ciudad): 32 rangos a las 24 h, 35 a las 72 h, ganado +854 % frente a sin árbol.

## 3. Producción con el juego cerrado

Perfil Sesiones (dos sesiones de 1 h al día) cerrando el juego entre sesiones con distintas reglas offline, frente a dejarlo abierto como widget (100 %, monedas solo durante las sesiones). «Cerrar / widget» = ganado cerrando ÷ ganado con widget.

Widget abierto: ganado 72 h 1.80Qa $, $/s final 14.1B, 26 rangos del árbol.

| Regla offline | Ganado 72 h | Cerrar / widget | Parte offline | $/s 72 h | Rangos del árbol 72 h | Ciudades 72 h |
|---|---:|---:|---:|---:|---:|---:|
| Sin offline | 123T $ | 7 % | 0 % | 3.95B | 25 | 9 |
| 25 %, 4 h | 305T $ | 17 % | 43 % | 6.39B | 25 | 9 |
| 25 %, 8 h | 476T $ | 26 % | 61 % | 7.32B | 25 | 9 |
| 50 %, 8 h (actual) | 782T $ | 43 % | 71 % | 9.14B | 25 | 9 |
| 100 %, 8 h | 1.01Qa $ | 56 % | 76 % | 9.05B | 25 | 9 |
| 100 %, sin límite | 1.51Qa $ | 84 % | 81 % | 10.4B | 27 | 9 |
