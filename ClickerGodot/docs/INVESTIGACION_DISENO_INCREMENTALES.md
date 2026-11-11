# Investigación de diseño de clickers e incrementales — MoneyClicker

Fecha: **8 de noviembre de 2026**. Investigación y preparación de diseño, versión 1.

## 1. Propósito, alcance y decisiones

Queremos mejorar MoneyClicker como incremental de ciudades que también pueda acompañar al jugador en una esquina del escritorio. Este documento reúne bibliografía, documentos públicos de diseño, análisis del código y propuestas que podremos convertir después en un GDD y en cambios del juego.

**Requisito confirmado por el usuario: crear una ciudad nueva debe tener un coste.** El precio, la moneda y las condiciones concretas siguen pendientes de balance. La versión 1 documentó el requisito y las alternativas; la sección 20 describe el cobro ya implementado.

Convenciones:

- **Fuente:** conclusión o descripción atribuida a una referencia externa enlazada.
- **Observación local:** comportamiento deducido del código actual; no es un resultado de pruebas con jugadores.
- **Propuesta / hipótesis:** recomendación original para MoneyClicker. Los valores son candidatos de prototipo, no cifras avaladas por la literatura.

La búsqueda prioriza autores, publicaciones académicas, documentación de creadores y GDD públicos. No existe una fórmula universal que garantice diversión. Tampoco disponemos de métricas de sesiones reales. Se revisaron artículos, diapositivas, secciones de documentos y resúmenes académicos; el alcance concreto figura en la bibliografía. No se han jugado campañas completas de los juegos de referencia durante esta investigación.

## 2. Qué nos enseñan las fuentes

### 2.1 El atractivo va más allá de pulsar

Alexander King describe el género a partir de recursos que se reinvierten para acelerar su generación [R5]. En su artículo de diseño destaca descubrimiento, diferencias entre juego activo e inactivo y coherencia temática [R6]. Su continuación presenta la evolución y experimentación del género [R7].

**Aplicación propuesta:** la promesa puede ser «una pequeña ciudad que crece y que aprendes a gestionar», con decisiones sobre qué mejorar, cuándo expandirse y qué especialización elegir. Los números deben expresar cambios comprensibles en la ciudad.

### 2.2 Esperar también forma parte del juego

*Playing to Wait* analiza 66 juegos idle y 10 juegos de contraste, y estudia cómo el juego se desplaza hacia la planificación y la atención intermitente [R8]. Fizek estudia el disfrute delegado desde la interpasividad [R10]. Son marcos para pensar el género, no recetas numéricas de balance.

**Aplicación propuesta:** una sesión puede consistir en revisar la ciudad, tomar una decisión y dejarla trabajar. No hace falta inventar una tarea para cada segundo de espera.

### 2.3 Engagement no equivale a tiempo mirando la pantalla

El estudio de Cutting, Gundry y Cairns sobre Neko Atsume utiliza una encuesta de 1.972 personas y distingue formas de participación como tiempo de juego, sociabilidad y frecuencia de consulta [R9]. Ese contexto no permite trasladar sus resultados directamente a un clicker económico de Windows.

**Aplicación propuesta:** medir también si el jugador entiende su próximo objetivo, disfruta al volver y siente que puede ausentarse. Una sesión más larga puede indicar interés o una interfaz trabajosa.

### 2.4 Economía y ritmo deben diseñarse juntos

Pecorella estudia costes, producción y multiplicadores [R1], alternativas donde los generadores producen otros generadores [R2] y consecuencias de distintas bases de cálculo del prestigio [R3]. Sus diapositivas de GDC también tratan relevancia de generadores, compras múltiples y ciclos de reinicio [R4].

**Aplicación propuesta:** antes de añadir edificios, comprobar qué decisiones ofrecen los cinco actuales. Evitar que comprar siempre el último disponible sea la única estrategia interesante.

### 2.5 Respuesta, claridad y facilidad de uso

La revisión *Designing Game Feel* organiza las sensaciones de juego en physicality, amplification y support [R11]. MDA relaciona mecánicas, dinámicas y experiencia del jugador [R12].

**Aplicación propuesta:** distinguir que un clic se sienta bien, que una compra importante se note y que comprar resulte cómodo. Más partículas no resuelven automáticamente los otros dos problemas.

## 3. Dirección propuesta para MoneyClicker

### 3.1 Fantasía y pilares

**Fantasía:** empezar con una impresora y pequeños negocios, ver crecer barrios y construir una red de ciudades con identidad propia.

Pilares propuestos:

1. **Crecimiento visible:** una decisión importante cambia edificios, actividad o aspecto del barrio.
2. **Decisiones comprensibles:** precio, beneficio y alcance local/global se entienden antes de comprar.
3. **Expansión significativa:** una ciudad adicional tiene coste, identidad y utilidad.
4. **Atención opcional:** jugar activamente ayuda; ausentarse sigue siendo válido.
5. **Comodidad que se gana:** automatizar tareas repetidas es parte del progreso.
6. **Descubrimiento gradual:** orientar al jugador y reservar novedades que sorprendan.

Son propuestas para este proyecto, no instrucciones extraídas de documentos externos.

### 3.2 Bucles y escalas de tiempo

| Escala | Acción o expectativa propuesta | Recompensa perceptible |
|---|---|---|
| Segundos | Clic opcional, compra, habilidad | Respuesta inmediata y cambio en ingresos |
| Minutos | Hito, mejora, encargo | Evolución del barrio y nueva decisión |
| Sesión | Mejorar, ahorrar, expandirse o prestigiar | Meta clara alcanzada |
| Varias sesiones | Desarrollar otra ciudad o especialización | Cambia la estrategia disponible |
| Largo plazo | Completar una región o proyecto importante | Logro visible y siguiente capítulo opcional |

No convertir cada escala en una alarma. Una meta de horas puede progresar mientras el jugador ignora el widget.

### 3.3 Dos presentaciones, una economía

Propuesta: mismo cálculo económico en normal y widget, distinta densidad de información.

- **Normal:** planificación, comparaciones, árbol de mejoras, mapa y estadísticas.
- **Widget:** ciudad viva, dinero, siguiente objetivo y pocas acciones claras.
- Eventos como avisos discretos o tareas pendientes; evitar respuesta inmediata obligatoria.
- No aumentar producción por estar en primer plano ni por alternar modos.
- Separar ajustes de audio, movimiento, partículas y notificaciones.

Rusty's Retirement es una referencia específica: su descripción oficial presenta juego en un borde de pantalla, automatización, zoom y un modo de concentración que ralentiza cultivos [R21]. Esa ralentización pertenece a su diseño; no se propone copiarla automáticamente.

## 4. Diagnóstico del juego actual

Base revisada: `scripts/game.gd`, `game_data.gd`, `shop_button.gd`, `desktop_mode.gd`, `menu.gd`, `scenes/main.tscn` y README. Rutas relativas a `ClickerGodot/` para su uso dentro del repositorio.

### 4.1 Fortalezas

- Impresora activa y cinco tipos de edificios automáticos.
- Costes crecientes, hitos, mejoras y sinergias entre tipos.
- Monedas especiales, efectos temporales, decisiones y logros.
- Reputación y mejoras permanentes.
- Guardado, progreso offline y ciudades independientes.
- Calles con día/noche, tráfico y cambios visuales.
- Widget con tamaño y posición persistentes.

Existe base suficiente para mejorar decisiones y claridad antes de añadir muchas monedas o subsistemas.

### 4.2 Riesgos y oportunidades

| Prioridad | Observación local | Consecuencia | Propuesta |
|---|---|---|---|
| P0 | `add_city()` no comprueba ni descuenta dinero | Expandirse no compite con invertir | Coste creciente y compra explícita |
| P0 | Crear ciudades aplica Head Start y Seed Money mediante `_reset_city()` | Se replica capacidad productiva o capital inicial gratis | Revisar coste y beneficios iniciales |
| P0 | Prestigio usa ingresos históricos globales y reinicia solo la ciudad seleccionada | Una ciudad vacía puede reclamar reputación generada por otras | Resolver ámbito del prestigio |
| P1 | `cities` cuenta prestigios; `city_states.size()` cuenta ciudades existentes | Confusión en interfaz y fórmulas | Separar nombres y estadísticas |
| P1 | “Found a new city” también nombra el prestigio | Dos acciones parecen fundar ciudades | Distinguir «Fundar» y «Renovar» |
| P1 | Primer punto: 100.000 ganados; bono directo +1 % | Reiniciar puede sentirse poco gratificante | Medir recuperación y primeras mejoras |
| P1 | Combo premia intervalos menores de 0,6 s y decae tras 1 s | Progreso activo ligado a pulsación repetitiva | Habilidad, mantener pulsado o automatización |
| P1 | Monedas desaparecen y eventos abren diálogos | Demanda de atención en un juego de escritorio | Avisos diferibles |
| P1 | Ciudades con casi las mismas reglas | Repetición de compras y gestión | Especializaciones y automatización |
| P2 | Cada calle representa como máximo cinco edificios | Progresión tardía poco visible | Variantes, densidad y monumentos |
| P2 | Banco y casino usan arte provisional | Crecer pierde fuerza visual | Completar identidad artística |

**Ejemplo del problema de prestigio:** A genera 100.000 históricos mientras B está vacía. Seleccionar B permite reclamar reputación y reiniciar B; A mantiene su producción y recibe el bono global. Es una deducción de las funciones actuales, no un exploit medido en una campaña de pruebas.

Las ayudas iniciales no cuentan automáticamente como ingresos históricos al concederse: el riesgo consiste en replicar capacidad productiva gratuita y acelerar la producción agregada. Son efectos diferentes.

## 5. Fundar ciudades debe costar

### 5.1 Qué compra el jugador

Fundar debería aportar capacidad productiva futura y una posibilidad estratégica. El jugador debe poder comparar mejorar la ciudad existente, ahorrar para otra y reiniciar a cambio de progreso permanente.

El coste necesita un beneficio legible. Cobrar por repetir una ciudad idéntica solo añade espera.

### 5.2 Alternativas de financiación

| Modelo | Ventaja | Riesgo | Valoración |
|---|---|---|---|
| Dinero local y coste global creciente | Simple y usa la economía actual | Explicar qué ciudad paga | Primera opción para prototipo |
| Fondo común de expansión | Financia proyectos entre ciudades | Otra cuenta y transferencias | Evolución posible |
| Chips de reputación | Vincula expansión y metaprogreso | Compite con mejoras; depende de arreglar prestigio | Posponer |
| Dinero más licencia por hito | Evita expansión demasiado temprana | Bloqueo artificial por requisitos dobles | Solo si el precio no basta |
| Coste proporcional al ingreso actual | Fija una espera aproximada | Mejorar puede encarecer el objetivo continuamente | Evitar recálculo continuo |
| Mantenimiento recurrente | Decisión sostenida de tamaño | Puede castigar ausencia y exigir trabajo | Innecesario al principio |

### 5.3 Candidato concreto, pendiente de balance

**Hipótesis:** primera ciudad gratuita; las adicionales se pagan desde la ciudad seleccionada. Precio según número de ciudades existentes en todo el imperio.

```text
n = ciudades existentes antes de comprar; n >= 1
coste_siguiente_ciudad(n) = redondear(250.000 × 5^(n - 1))
```

| Ciudad nueva | Existentes | Precio candidato |
|---|---:|---:|
| Segunda | 1 | 250.000 $ |
| Tercera | 2 | 1.250.000 $ |
| Cuarta | 3 | 6.250.000 $ |
| Quinta | 4 | 31.250.000 $ |

Valores para simulación, no recomendados por una fuente externa. El umbral de prestigio y la producción real podrían exigir cambiar toda la escala.

Comparar bases **100.000 / 250.000 / 1.000.000** y factores **3 / 5 / 8**. No elegir solo la combinación que alargue más la partida.

Reglas propuestas:

1. `+` abre una ficha con coste, ciudad que paga, saldo resultante y beneficio.
2. Solo el botón de compra de esa ficha ejecuta gasto y fundación.
3. Si falta dinero, explicar cuánto; no cobrar parcialmente.
4. Cobro y creación coherentes: ni doble cobro ni ciudad gratis por doble pulsación.
5. Usar el número global de ciudades, nunca `cities` mientras represente prestigios.
6. Navegar no abarata la siguiente fundación.
7. Evaluar rentabilidad incluyendo Head Start y Seed Money.
8. Prestigiar no reduce el contador de ciudades ni regala licencias.
9. Si se permite vender ciudades, impedir ciclos de devolución rentables no deseados.
10. Conservar ciudades de partidas anteriores; no imponer deudas retroactivas.

### 5.4 Cómo evaluar el coste

Medir tiempo para comprar y para recuperar la inversión. Una ciudad nueva sin edificios puede producir cero: dividir el coste entre ese ingreso inicial no ayuda.

```text
inversión_total = fundación + edificios iniciales + mejoras necesarias
beneficio_hasta_T = integral(ingresos extra de expansión entre 0 y T)
recuperación = primer T con beneficio_hasta_T >= inversión_total
```

Comparar con invertir el mismo presupuesto en la ciudad original. Incluir gestión, hitos, sinergias y bonos permanentes.

- Si fundar siempre domina, revisar precio, condiciones o beneficio.
- Si nadie funda comprendiendo sus ventajas, revisar utilidad y coste.
- Si muchas ciudades obligan a recorrerlas continuamente, resolver automatización.
- Si la segunda repite el arranque sin novedades, mejorar contenido.

## 6. Separar expansión y prestigio

| Acción propuesta | Sacrificio | Conservación | Aportación buscada |
|---|---|---|---|
| Fundar | Capital | Ciudades previas | Economía y especialización adicionales |
| Renovar, prestigio local | Economía de una ciudad | Imperio y legado definido | Recuperación rápida o regla local nueva |
| Reorganizar imperio, opcional | Economías según reglas explícitas | Colecciones y legado definido | Cambio importante de escala |

No añadir reinicios solo porque sean habituales. Cada uno necesita una función.

### 6.1 Soluciones al conflicto actual

**A. Prestigio local con métrica local.** Recompensa basada en progreso de la ciudad sacrificada. Puede otorgar especialización local o recompensa global limitada. Registrar cuánto de esa métrica ya se reclamó.

**B. Prestigio global con sacrificio global.** Reputación calculada sobre el conjunto y reinicio de todas las ciudades. Coherente económicamente, pero puede frustrar el apego a ciudades persistentes.

**C. Recompensa global sin reinicio.** Si queremos progreso histórico sin sacrificio, llamarlo hito o investigación. No presentarlo como una decisión de prestigio.

**Preferencia para explorar:** A, por encajar con ciudades persistentes; contrastar con C para una experiencia muy tranquila. No mantener la mezcla sin decidir qué conducta se quiere premiar.

### 6.2 Beneficio real del reinicio

Fórmula actual, leída del código:

```text
objetivo_reputación = floor(sqrt(ingresos_históricos_globales / 100.000))
pendiente = max(0, objetivo_reputación - reputación_ya_reclamada)
```

Por álgebra, objetivos totales de 1, 2, 3 y 10 puntos requieren 100.000, 400.000, 900.000 y 10.000.000 históricos. Duplicar el objetivo requiere cuadruplicar ingresos requeridos; no significa cuadruplicar el tiempo de juego.

```text
mejora_relativa = (1 + 0,01 × (p + g)) / (1 + 0,01 × p) - 1
```

De 100 a 110 puntos el multiplicador directo pasa de 2,00 a 2,10: **+5 % de producción relativa**, no +10 %. Distinguir puntos ganados de aceleración efectiva.

Medir tiempo de recuperación, novedad desbloqueada y diferencia visible. Si se repiten compras a casi la misma velocidad, revisar el prestigio.

## 7. Herramientas matemáticas para el balance

Cálculos propios sobre las fórmulas del proyecto. Las referencias económicas [R1–R3, R6] sirven de contexto; estos ejemplos corresponden a MoneyClicker.

### 7.1 Compras múltiples

```text
b = coste base; r = factor de crecimiento; k = cantidad ya poseída
coste_siguiente = b × r^k
coste_de_q = b × r^k × (r^q - 1) / (r - 1), para r != 1
coste_de_q = b × q, para r = 1
```

Propuesta: comprar ×1, ×10, ×25, hasta el siguiente hito y máximo. Respetar desbloqueos y comprobar redondeos cerca del saldo exacto.

El `1,15` actual necesita evaluación dentro de esta economía. Que otros juegos lo utilicen no demuestra que sea óptimo aquí.

### 7.2 Espera y recuperación

```text
espera_aproximada = max(0, precio - saldo) / ingresos_por_segundo
beneficio_marginal = producción_total_después - producción_total_antes
recuperación_simple = precio / beneficio_marginal
```

Si el ingreso es cero y falta dinero, la espera pasiva no es finita: considerar clics, ayudas o ruta alternativa. Con beneficio marginal cero o negativo, la recuperación simple no sirve.

Recalcular toda la producción: una fábrica puede mejorar bares por sinergia; alcanzar un hito multiplica todas las unidades del tipo. No valorar siempre una compra como «añade el ingreso base de un edificio».

La recuperación simple ignora cambios futuros, pagos por ciclos y desbloqueos. Es diagnóstico, no un algoritmo universal de estrategia óptima.

### 7.3 Ejemplo reproducible: bares

Supuestos: coste base 15, ingreso base 1,5 $/s, crecimiento 1,15, hitos actuales; sin mejoras, sinergias ni bonos globales.

| Bares antes | Precio de uno más | Aumento real de $/s | Recuperación simple |
|---:|---:|---:|---:|
| 0 | 15,00 | 1,50 | 10,00 s |
| 9 | 52,77 | 16,50 | 3,20 s |
| 24 | 429,38 | 78,00 | 5,50 s |
| 49 | 14.134,66 | 306,00 | 46,19 s |

Los saltos a 10, 25 y 50 duplican el conjunto de bares. Pueden dar ritmo; mostrar el siguiente hito antes de alcanzarlo permite planificar.

### 7.4 Simular el ritmo completo

Comparar al menos cuatro comportamientos:

- Compra por recuperación marginal, contemplando hitos.
- Ahorro para siguiente edificio o ciudad.
- Juego activo moderado, con acciones por minuto limitadas explícitamente.
- Consultas espaciadas con pocas compras grandes.

Registrar saldo, producción, tiempo entre compras importantes y opciones elegidas. Usar escala logarítmica cuando el rango lo exija.

El simulador descubre bloqueos y estrategias dominantes. Después hacen falta pruebas humanas: una ruta óptima puede ser laboriosa o imposible de deducir.

## 8. Qué haría distintas a las ciudades

Especializaciones propuestas, sin coeficientes definitivos:

| Ciudad | Fantasía | Decisión principal | Diferencia visual |
|---|---|---|---|
| Comercial | Ocio y pequeños negocios | Estabilidad frente a eventos | Toldos, plazas, terrazas |
| Industrial | Fábricas y logística | Producción propia o apoyo externo | Chimeneas, almacenes, trenes |
| Universitaria | Salud e investigación | Ingresos o nuevas mejoras | Campus y laboratorios |
| Financiera | Bancos e inversión | Liquidez o retorno diferido | Centro urbano y edificios altos |
| Turística | Ocio y festivales | Encargos y estacionalidad opcional | Paseos y monumentos |

Empezar con dos especializaciones reutilizando arte y reglas. Cinco economías completas de golpe dificultarían el balance.

Las rutas comerciales pueden conectar ciudades. Precaución matemática: con `N` ciudades existen `N × (N - 1) / 2` pares; un bono completo por conexión produce una cantidad de beneficios que crece cuadráticamente. Probar pocas rutas asignables, capacidad o rendimientos decrecientes.

Automatización propuesta: una política por ciudad —ahorrar para hito, compra equilibrada o proyecto— cuyo comportamiento se explique. Debe ahorrar tareas sin decidir toda la estrategia.

## 9. Eventos y azar: decisiones que merezcan atención

### 9.1 Auditoría de eventos actuales

Cálculos propios, suponiendo ingresos constantes, sin otros efectos ni reinversiones durante el evento:

| Evento | Cálculo | Lectura de diseño |
|---|---|---|
| Inspección | Pagar pierde 10 % del saldo; arriesgar pierde en promedio `0,5 × 30 % = 15 %` | La opción segura tiene menor pérdida esperada; el riesgo puede preservar liquidez si sale bien |
| Turistas | ×2 durante 60 s aporta 60 s adicionales; cobro inmediato aporta 120 s | El cobro domina en este escenario; reinversión y cambios futuros exigen otra comparación |
| Festival | Cuesta `180 × ingreso_total`; añade `240 × ingreso_bares` | Rentable a ingreso constante si bares aportan más del 75 % del total |
| Inversor | Inversión `I`; retorno esperado `0,75 × 2I = 1,5I` | Beneficio esperado `0,5I`, con riesgo y coste de oportunidad durante dos minutos |

Fuente de los cálculos: `game_data.gd`. No equilibrar solo por esperanza matemática: importan liquidez, volatilidad, claridad y cambios que puede provocar el jugador.

### 9.2 Reglas propuestas

- Cada elección debe depender de situación, riesgo preferido u objetivos diferentes.
- Mostrar efectos y duración; distinguir información conocida de incertidumbre.
- No penalizar la ausencia con pérdidas automáticas mientras se ignora el widget.
- Resolver más tarde cuando sea posible, con límite de acumulación explicado.
- Encargos deterministas para metas largas; azar para variedad y sorpresa.
- Una moneda rara puede ser agradable sin concentrar casi todo el progreso.
- Evitar cadenas de ventanas y recompensas que exijan vigilancia constante.

Idea: turistas ofrece dinero inmediato o un festival que progresa una colección local. No hacer siempre obligatoria la opción menos rentable mediante un logro.

## 10. Clic satisfactorio sin pulsación constante

Propuestas para probar por separado:

1. Respuesta rápida, pequeña deformación de impresora y sonido configurable.
2. Mantener pulsado o ráfaga accesible, con techo definido de aportación.
3. Sustituir parte del combo de velocidad por una «tirada especial» que invite a decidir cuándo usarla.
4. Mantener utilidad del clic sin volver inútil la producción automática.
5. Automatizar operaciones cuando dejan de representar una elección.
6. No hacer de miles de pulsaciones el principal contenido de largo plazo.

Medir producción y esfuerzo de quien juega activamente frente a quien consulta poco. La diferencia deseada es una decisión del proyecto; no hay un porcentaje universal que copiar.

## 11. Descubrimiento, objetivos y progreso visible

Propuestas:

- Un objetivo próximo y una meta lejana opcional, sin lista de obligaciones.
- Siluetas, fachadas, tráfico, luces y monumentos que cambien por etapas.
- Algunas mejoras aportan reglas: automatización, especialización o espacio de ruta.
- Logros numéricos combinados con explorar sistemas y estrategias.
- Una novedad por etapa, con tiempo para aprenderla.
- Un proyecto de cierre de capítulo aunque después se permita continuar.

La entrevista a los creadores de A Dark Room explica su intención de relacionar expansión mecánica y descubrimiento narrativo [R23]. El repositorio oficial permite estudiar implementación [R22]. No necesitamos copiar tono ni estructura.

Universal Paperclips y Antimatter Dimensions quedan como estudio posterior [R24, R25], especialmente para observar cambios de escala y automatización. No se presentan sus campañas como completadas durante esta investigación.

## 12. Offline y comodidad del widget

Observación local: se paga 50 % sin conexión, 75 % con Night Owl, hasta 8 horas; umbral mínimo de 60 segundos. Las ciudades no visibles producen con el juego abierto, pero no simulan todos los eventos de la visible.

Preguntas:

- ¿Qué diferencia queremos entre dejar el programa abierto y cerrarlo?
- ¿Se puede ausentar una noche sin sentir obligación de volver?
- ¿Se explica la eficiencia antes de cerrar o solo al regresar?
- ¿Bonus temporales y pagos pendientes se liquidan coherentemente?
- ¿La automatización comprada funciona también sin conexión?

Propuestas:

- Resumen breve de vuelta, desglosable por ciudad y tiempo reconocido.
- Reglas de eficiencia y límite consultables.
- Pagos y efectos independientes del orden de navegación y modo de ventana.
- Sin castigos acumulados por no responder eventos durante ausencia.
- Probar mayor eficiencia si el 50 % incentiva mantener el ordenador encendido.
- Medir consumo con varias ciudades antes de ampliar su número indefinidamente.

No fijamos un nuevo límite: depende de la duración de ciclos que elijamos.

## 13. Documentos públicos de diseño revisados

Son ejemplos de trabajo, algunos de prototipos pequeños. Publicarlos no demuestra éxito comercial, autoría experta ni que todas sus decisiones sean buenas.

### 13.1 Pressure Works — GDD [R16]

Relaciona fantasía industrial con caudal, presión, demanda y calor. Expone pilares, bucles de distintas duraciones y etapas de contenido. Ejemplo de variables con explicación visual.

**Adaptación propuesta:** relacionar cada variable nueva con algo observable en la ciudad, sin copiar un simulador industrial completo.

### 13.2 Pressure Works — Economy & Balance [R17]

Acompaña fórmulas con objetivos de ritmo, resultados de un bot y problemas conocidos. Distingue previsión de diseño de medición del simulador.

**Hallazgo documental:** su GDD describe patentes con raíz cuadrada; el documento económico consultado usa raíz cúbica y explica el cambio. Es una divergencia entre documentos revisados. Para MoneyClicker, mantener una tabla canónica y señalar qué documento prevalece.

### 13.3 Pressure Works — Territory [R18]

Expansión persistente y ordenada, condicionada por ingresos históricos. Localizaciones que amplían clientes de una empresa común, distintas de nuestras economías independientes.

**Adaptación propuesta:** definir si una ciudad es otra economía, una ampliación o una elección estratégica antes de fijar precio.

### 13.4 Backrooms: Idle Survival — GDD [R19]

Inventario de sistemas, relaciones, problemas y plan por fases. Señala pérdida de exploración al viajar y límites offline. Afirma que todo idle exitoso necesita prestigio: esa generalización no se adopta como regla.

**Adaptación propuesta:** documentar problemas y mejora esperada. Un juego con buen cierre puede funcionar sin reinicios infinitos.

### 13.5 Esports Dynasty: Idle Manager — GDD [R20]

Explicita fantasía, monedas, escalas de sesión y progresión; se declara diseño objetivo y remite al estado de implementación. Su estrategia gira alrededor de anuncios recompensados.

**Adaptación propuesta:** separar bucles y estado previsto/implementado. No copiar incentivos publicitarios ni asumir probadas sus afirmaciones sobre retención.

## 14. Esqueleto del futuro GDD

1. Visión y público: sesiones esperadas, normal y widget.
2. Pilares: qué significa divertido aquí.
3. Arranque: primer clic, negocio, decisión y ausencia.
4. Recursos: fuentes, usos y persistencia.
5. Economía canónica: costes, ingresos, hitos, sinergias y multiplicadores.
6. Fundación: coste, requisitos, ciudad que paga y ayudas iniciales.
7. Ciudades: diferencias, automatización y rutas.
8. Prestigio: métrica, sacrificio, recompensa y cantidad ya reclamada.
9. Eventos: condiciones, opciones, probabilidades, duración y aplazamiento.
10. Progreso visual y arte necesario.
11. Offline: eficiencia, límite y tratamiento de sistemas.
12. Interfaz, accesibilidad y reducción de distracción.
13. Guardado, identificadores y migraciones.
14. Simulación, pruebas humanas y aceptación.
15. Alcance del prototipo y decisiones abiertas.

Cada sistema necesita objetivo, ejemplo, fórmula, condiciones límite, presentación, dato guardado y forma de comprobarlo.

## 15. Plan priorizado

| Fase | Trabajo propuesto | Criterio de resultado |
|---|---|---|
| 1. Coherencia | Coste de fundación, nombres/contadores y prestigio multiciudad | Sin producción gratuita ilimitada ni prestigio sin sacrificio previsto |
| 2. Decisiones | Compras múltiples, próximo hito y comparación | El jugador explica dos alternativas razonables |
| 3. Ritmo | Simular precios, expansión y reinicios | Sin bloqueos inesperados ni una compra dominante en todas las etapas |
| 4. Identidad | Dos especializaciones y evolución visual | Segunda ciudad reconocible y con decisión diferente |
| 5. Comodidad | Automatización, eventos diferibles y widget legible | Consulta breve sin repetir tareas |
| 6. Contenido | Encargos, rutas, proyectos y capítulos | Cada adición aporta decisión o descubrimiento |

No implementar todo a la vez. Primero definir qué cuesta y qué se sacrifica para poder comparar pruebas de balance.

## 16. Cómo validar diversión y balance

### 16.1 Registro de sesiones

Preferir registros locales de desarrollo. Enviar analítica a terceros sería otra decisión de producto, innecesaria para empezar.

| Dato | Pregunta que investiga |
|---|---|
| Tiempo hasta primer edificio automático | ¿El arranque entrega y comunica automatización? |
| Tiempo hasta primera decisión relevante | ¿Solo se sigue una secuencia obvia? |
| Tiempo y presupuesto hasta segunda ciudad | ¿Meta o bloqueo? |
| Mejoras elegidas y alternativas asequibles | ¿Hay estrategia dominante? |
| Ingreso activo, pasivo y aleatorio | ¿Atención o azar eclipsan la economía? |
| Recuperación tras prestigio | ¿Se siente progreso? |
| Compras y cambios de ciudad por sesión | ¿Crece demasiado la carga de gestión? |
| Offline reconocido y recompensa | ¿La vuelta es coherente y clara? |
| Objetivo que explica el jugador | ¿Los números se traducen en intención? |
| Motivo para cerrar | ¿Pausa natural, aburrimiento o confusión? |

### 16.2 Prueba cualitativa

Propuesta: grupo pequeño con experiencia variada en incrementales, incluidos usuarios que quieran un widget. Detectará comprensión y fricciones; no estimará de forma fiable retención poblacional.

Observar sin explicar cada botón:

- ¿Comprenden fuentes y gastos de dinero?
- ¿Explican qué conservan al fundar o prestigiar?
- ¿Saben qué quieren conseguir después?
- ¿Ven cambiar la ciudad?
- ¿Pueden dejar de mirar tranquilamente?
- ¿Volver resulta interesante o una lista de tareas?

Preguntar por una decisión satisfactoria y otra inútil; no solo «¿te gusta?».

### 16.3 Comprobaciones cuando se implemente el cobro

- Saldo insuficiente, exacto y superior; redondeos grandes.
- Doble pulsación, compra seguida de cierre y guardado interrumpido.
- Precio global igual desde cualquier ciudad.
- Descuento solo en la cuenta declarada y persistencia tras carga.
- Conservación de ciudades y mejoras antiguas.
- Ayudas y prestigio sin ciclos rentables no deseados.
- Estado equivalente entre modos y ciudades según reglas acordadas.
- Migración sin pérdida de partidas.

## 17. Decisiones abiertas

- ¿Financiación local o fondo común?
- ¿Fundar aporta capacidad, especialización o territorio?
- ¿Transferencias entre ciudades y con qué restricciones?
- ¿Prestigio local, global o hitos sin reinicio?
- ¿Qué ayudas iniciales recibe cada fundación?
- ¿Cuántas ciudades se gestionan antes de necesitar mapa y automatización?
- ¿Qué progreso esperamos en una sesión, una tarde y una semana?
- ¿Qué ventaja damos al juego activo?
- ¿Final de capítulo, colección completa o crecimiento indefinido?

**Orden recomendado:** resolver fundación y prestigio; simular; añadir diferencias entre ciudades. Las fuentes no pueden decidir nuestros objetivos de producto.

## 18. Bibliografía anotada y acceso

Consulta: **2026-11-08**. Las ramas `main`/`master` cambian; registrar la revisión antes de implementar fórmulas externas. Estos resúmenes no sustituyen los originales.

### Matemáticas, progresión y diseño

- **R1 — Anthony Pecorella, The Math of Idle Games, Part I (2016).** [Artículo en Game Developer](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-i). Republicación firmada del blog de Kongregate. Revisado el texto sobre costes, producción, multiplicadores y comparación de generadores. Fuente práctica, no experimento con usuarios.
- **R2 — Anthony Pecorella, The Math of Idle Games, Part II (2016).** [Artículo](https://www.gamedeveloper.com/game-platforms/the-math-of-idle-games-part-ii). Revisado el texto sobre cadenas de generadores y crecimiento alternativo. Explora sistemas que no solo producen una moneda.
- **R3 — Anthony Pecorella, The Math of Idle Games, Part III (2017).** [Artículo](https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii). Revisado el texto sobre prestigio, métricas históricas o del ciclo y ritmo de reinicios. Los ejemplos describen versiones de la época, no necesariamente fórmulas actuales.
- **R4 — Anthony Pecorella, Quest for Progress: The Math and Design of Idle Games, GDC Europe (2016).** [Diapositivas oficiales, PDF](https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf). Revisado texto extraído de las diapositivas; no se afirma haber visto la grabación. Visión de habilidades, multiplicadores y planificación.
- **R5 — Alexander King, Numbers Getting Bigger: What Are Incremental Games, and Why Are They Fun? (2015).** [Artículo](https://code.tutsplus.com/numbers-getting-bigger-what-are-incremental-games-and-why-are-they-fun--cms-23925a). Revisadas secciones de definición y motivación. Introducción al bucle de reinversión.
- **R6 — Alexander King, Numbers Getting Bigger: The Design and Math of Incremental Games (2015).** [Artículo](https://code.tutsplus.com/numbers-getting-bigger-the-design-and-math-of-incremental-games--cms-24023a). Revisado el texto sobre descubrimiento, automatización, arte y análisis económico. No tratar parámetros habituales de otros juegos como constantes universales.
- **R7 — Alexander King, Numbers Getting Even Bigger: The Growing Appeal of Incremental Games (2016).** [Artículo](https://code.tutsplus.com/numbers-getting-even-bigger--cms-26854a). Revisadas secciones de continuación y evolución del género. Contexto histórico; sus cifras de mercado no describen 2026.

### Investigación y marcos

- **R8 — Alharthi y colaboradores, Playing to Wait: A Taxonomy of Idle Games, CHI (2018).** [DOI](https://doi.org/10.1145/3173574.3174195), [PDF de los autores](https://www.researchgate.net/profile/Sultan-Alharthi-2/publication/324658906_Playing_to_Wait_A_Taxonomy_of_Idle_Games/links/61865636d7d1af224bbaeea6/Playing-to-Wait-A-Taxonomy-of-Idle-Games.pdf). Revisados resumen, método y discusión. Clasificación de artefactos, no estudio causal de una economía óptima.
- **R9 — Joe Cutting, David Gundry y Paul Cairns, Busy doing nothing? What do players do in idle games? (registro de 2018).** [Ficha, resumen y versión aceptada](https://ray.yorksj.ac.uk/id/eprint/7953/), [DOI](https://doi.org/10.1016/j.ijhcs.2018.09.006). Se usa principalmente ficha y resumen, con acceso a la versión aceptada. Encuesta de un juego y participantes concretos.
- **R10 — Sonia Fizek, Interpassivity and the Joy of Delegated Play in Idle Games (2018).** [Registro y acceso](https://rke.abertay.ac.uk/en/publications/interpassivity-and-the-joy-of-delegated-play-in-idle-games/), [DOI](https://doi.org/10.26503/todigra.v3i3.81). Se utiliza resumen y planteamiento teórico. Marco para pensar disfrute sin intervención constante.
- **R11 — Martin Pichlmair y Mads Johansen, Designing Game Feel. A Survey (preprint 2020; publicación relacionada 2021).** [Texto y PDF](https://arxiv.org/abs/2011.09201). Revisados resumen y marco de clasificación. Revisión de más de 200 fuentes sobre interacción; no exclusiva de incrementales.
- **R12 — Robin Hunicke, Marc LeBlanc y Robert Zubek, MDA: A Formal Approach to Game Design and Game Research (2004).** [PDF de los autores](https://www.cs.northwestern.edu/~hunicke/MDA.pdf). Revisado el marco de mecánicas, dinámicas y estética/experiencia. Conecta reglas, conductas y sensaciones.

### Documentación y herramientas

- **R13 — Jesse Lawson, Designing the game, Building a browser-based incremental game.** [Capítulo](https://jesselawson.dev/tutorials/clicker-game/1-designing-the-game/). Revisado: producir, gastar y automatizar. Un prototipo básico es una base para desarrollar identidad, no todo un diseño duradero.
- **R14 — Orteil, Idle Game Maker Documentation, versión antigua.** [Documentación](https://orteil.dashnet.org/experiments/idlegamemaker/help). Consultada como referencia de herramienta basada en texto para experimentar con recursos. Documentación antigua; no asumir compatibilidad con la edición actual.
- **R15 — Acamaeda / The Modding Tree, Layer Features.** [Capas](https://github.com/Acamaeda/The-Modding-Tree/blob/master/docs/layer-features.md), [portal actual](https://docs.tmt.land/). Revisadas secciones de capas, hitos, desafíos y prestigio normal/static/custom. Ejemplo de separar estado, requisitos y automatización. Rama y portal pueden corresponder a versiones distintas.

### GDD y documentos de balance públicos

- **R16 — mrwuss/idle, Pressure Works — Game Design Document.** [GDD](https://github.com/mrwuss/idle/blob/main/docs/GAME_DESIGN.md). Revisados pilares, economía, progresión, presentación y sistemas previstos. Prototipo con decisiones en evolución.
- **R17 — mrwuss/idle, Economy & Balance.** [Economía](https://github.com/mrwuss/idle/blob/main/docs/ECONOMY.md). Revisadas fórmulas, objetivos y notas de simulación. Sus tiempos de bot son afirmaciones del proyecto; no se ha ejecutado ni reproducido su simulador.
- **R18 — mrwuss/idle, Territory — locations and customer base.** [Expansión](https://github.com/mrwuss/idle/blob/main/docs/TERRITORY.md). Revisadas reglas de localizaciones y función de clientes. Relacionado con expansión persistente.
- **R19 — series-ai/backrooms-idle, Backrooms: Idle Survival — Game Design Document.** [GDD](https://github.com/series-ai/backrooms-idle/blob/master/GAME_DESIGN.md). Revisados inventario, problemas y propuestas por fases. Mezcla diagnóstico, planes y marcas de implementación; no asumir implementado todo el contenido.
- **R20 — jannkobee/idle_esports_tycoon, Esports Dynasty: Idle Manager — Game Design Document.** [GDD](https://github.com/jannkobee/idle_esports_tycoon/blob/main/docs/GAME_DESIGN_DOCUMENT.md). Revisados monedas, bucles y anuncios. Diseño objetivo, no prueba pública de monetización o retención efectiva.

### Casos y estudio posterior

- **R21 — Mister Morris Games, Rusty's Retirement.** [Descripción oficial en Steam](https://store.steampowered.com/app/2666510/Rustys_Retirement/). Revisada descripción del desarrollador sobre uso junto a otras tareas, automatización y visualización. Relevante para widget; no demuestra retención por sí sola.
- **R22 — Doublespeak Games, A Dark Room.** [Repositorio oficial](https://github.com/doublespeakgames/adarkroom). Consultados presentación y estructura. Material para futura lectura de implementación; no es un GDD completo.
- **R23 — Leigh Alexander, A Dark Room's unique journey from the web to iOS (2014).** [Entrevista a creadores](https://www.gamedeveloper.com/design/-i-a-dark-room-i-s-unique-journey-from-the-web-to-ios). Revisadas explicaciones sobre narrativa, descubrimiento y adaptación de interfaz. Testimonio contextualizado por una periodista.
- **R24 — Universal Paperclips.** [Sitio oficial](https://www.decisionproblem.com/paperclips/). Verificado como acceso oficial para estudio posterior. No se deriva aquí un balance detallado de su campaña.
- **R25 — IvarK y colaboradores, Antimatter Dimensions.** [Código oficial](https://github.com/ivark/AntimatterDimensionsSourceCode). Verificados repositorio y estructura para estudio posterior. No se ha auditado toda su economía.

### Enlaces históricos y límites

Los enlaces clásicos de Kongregate devolvieron 404 al consultarlos:

- [The Math of Idle Games, Part I, enlace histórico](https://blog.kongregate.com/the-math-of-idle-games-part-i/).
- [Part II, enlace histórico](https://blog.kongregate.com/the-math-of-idle-games-part-ii/).
- [Part III, enlace histórico](https://blog.kongregate.com/the-math-of-idle-games-part-iii/).

Se usan las republicaciones firmadas [R1–R3], que identifican su origen. No conservar solo enlaces rotos como bibliografía utilizable.

El PDF de GDC 2015 localizado superó el tamaño admitido por el lector web y un capítulo histórico alojado en Monash agotó el tiempo de consulta. No se presentan como lecturas completas ni sostienen conclusiones.

Los GDD públicos no equivalen a consenso del sector. Tampoco se aceptan como hechos explicaciones simplificadas de dopamina, adicción o porcentajes de retención sin evidencia verificable.

## 19. Primera tarea preparada para la próxima iteración

**Problema:** fundar gratis elimina el coste de oportunidad y replica ayudas iniciales.

**Resultado buscado:** fundación como compra explícita, de coste creciente, beneficio comprensible y persistencia correcta.

**Antes de programar:** elegir financiación, ayudas iniciales y solución al prestigio multiciudad. Después comparar la matriz de precios mediante simulación y una prueba breve de juego.

**Aceptación:** el jugador explica por qué prefiere fundar o mejorar, ve cuánto paga y conserva progreso anterior al comprar o cargar partidas antiguas.

## 20. Estado de implementación (10 de noviembre de 2026)

Primera iteración sobre las fases 1 (coherencia) y 2 (decisiones) del plan de la sección 15. Las cifras siguen siendo candidatos de prototipo: falta la simulación de la sección 7.4 y pruebas con jugadores.

### 20.1 Decisiones tomadas para el prototipo

| Decisión abierta (sección 17) | Elección provisional | Motivo |
|---|---|---|
| ¿Financiación local o fondo común? | Dinero local de la ciudad seleccionada | Primera opción de la tabla 5.2: simple y usa la economía actual |
| Precio de fundación | `250.000 × 5^(n − 1)`, con `n` = ciudades existentes | Candidato de la sección 5.3; constantes `FOUND_BASE_COST` y `FOUND_GROWTH` en `game.gd` |
| ¿Prestigio local, global o hitos? | **A: prestigio local con métrica local** | Preferencia de la sección 6.1; encaja con ciudades persistentes |
| Ayudas iniciales al fundar | Se mantienen Head Start y Seed Money | Su valor (5 bares, 1K $) es pequeño frente a 250K $; la ficha las muestra |

### 20.2 Qué se ha implementado

| Riesgo (sección 4.2) | Cambio |
|---|---|
| P0 — `add_city()` no cobraba | Sustituido por `request_found_city()` (ficha) y `found_city()` (cobro y fundación en un paso). Sin saldo no se cobra nada y se indica cuánto falta. El precio depende solo del número global de ciudades: igual desde cualquier ciudad, navegar no lo abarata y renovar no lo reduce |
| P0 — ayudas iniciales gratis | Fundar tiene coste; la ficha detalla las ayudas recibidas |
| P0 — prestigio con ingresos globales | Cada ciudad guarda `lifetime` (ganado desde su fundación, no se reinicia al renovar) y `claimed` (reputación ya cobrada). Pendiente = `floor(sqrt(lifetime / 100.000)) − claimed`. Una ciudad vacía ya no puede cobrar lo que generan otras |
| P1 — `cities` contaba prestigios | Renombrado a `renewals`; «Cities» muestra `city_states.size()` |
| P1 — dos acciones «fundan» | «Found City N» (comprar con `+`) frente a «Renew City N» (prestigio) |
| P1 — beneficio del reinicio poco legible | El botón y la confirmación muestran el aumento relativo real (`reputation_speedup`), p. ej. +5 % de 100 a 110 puntos |
| Sección 7.1 — compras múltiples | Modos ×1, ×10, ×25, hasta el siguiente hito y máximo, con coste geométrico exacto y corrección de redondeo cerca del saldo |
| Sección 7.2 — comparación | Cada botón muestra el aumento real de $/s (recalcula hitos y sinergias de toda la ciudad) y la recuperación simple |
| Sección 12 — resumen de vuelta | La bienvenida desglosa lo ganado por ciudad y explica eficiencia y límite, avisando si se superó |

Logro nuevo «Founder» (fundar una segunda ciudad); «New Beginnings» pasa a premiar renovar una ciudad.

### 20.3 Migración de partidas (versión de guardado 4)

- Se conservan todas las ciudades; no se cobran deudas retroactivas.
- `progress/cities` se lee como `renewals`.
- La reputación de versiones anteriores salía de ingresos globales. Para no regalar puntos ni crear deudas: cada ciudad no seleccionada recibe `lifetime = total_earned` y se marca como reclamada su reputación correspondiente; la seleccionada recibe los ingresos históricos no atribuibles a otras y `claimed = min(reputación cobrada, su reputación)`.

### 20.4 Pendiente

- ~~Simular precios de fundación y recuperación tras renovar~~: hecho, ver sección 21.
- Hipótesis a vigilar: con métrica local, la reputación total crece como la suma de raíces por ciudad, lo que incentiva fundar. El coste ×5 lo limita, pero hay que medirlo.
- Especializaciones de ciudad (sección 8), eventos diferibles y sin pérdidas por ausencia (sección 9.2), alternativa al combo de velocidad (sección 10), automatización (fase 5).
- Registro local de sesiones (sección 16.1).

## 21. Resultados de la primera simulación (10 de noviembre de 2026)

Simulador: `tools/balance_sim.gd`. Informe completo y supuestos: [SIMULACION_BALANCE.md](SIMULACION_BALANCE.md). Son bots de juego perfecto con monedas como valor esperado, sin eventos ni logros: sirven para detectar bloqueos y estrategias dominantes (sección 7.4), no para fijar tiempos reales.

### 21.1 Hallazgos

1. **Las monedas especiales eclipsan la economía.** Para el perfil Activo aportan el 91 % del dinero y multiplican por ~126 los $/s a las 24 h. Sin monedas, Activo (107M $/s) y Espaciado (99M $/s) quedan casi igual a las 24 h; con monedas, Activo produce unas 67 veces más a las 72 h. Contradice el pilar 4 («ausentarse sigue siendo válido») y la regla de la sección 9.2 sobre no concentrar el progreso en la moneda rara. Causas probables: +2 % permanente por moneda sin límite (unas 70 monedas por hora mirando) y Click Frenzy ×777 aplicado a un clic que, con Golden Touch, escala con los $/s. Falta separar cuánto aporta cada una.
2. **Renovar es casi gratis y desboca la escala.** La primera renovación llega a los 2 min y la ciudad recupera su producción en 1–4 min. Con una sola ciudad, renovar cada vez que se duplica la reputación lleva a ~6·10¹¹ puntos en 72 h (multiplicador ~6·10⁹), y lo ganado pasa de 10¹⁷ a 10²⁸ $. A ese ritmo, los sufijos de `Fmt` (hasta Dc, 10³³) se agotan en pocos días. Origen: divisor de 100K muy bajo y +1 % lineal por punto sin rendimientos decrecientes; la raíz cuadrada sola no basta.
3. **Fundar domina en todas las combinaciones de precio.** Con las 9 combinaciones de base (100K/250K/1M) y factor (3/5/8), fundar gana entre +226 % y +423 % (Activo) o entre +2.700 % y +6.000 % (Espaciado) frente a no fundar. Cada ciudad recupera su precio en 6–13 min. Se llega a 16–47 ciudades en 72 h. El precio ×5 no aguanta porque la producción crece mucho más rápido por el bucle de reputación.
4. **Se confirma la hipótesis de la sección 20.4.** Con métrica local, cada ciudad es una raíz nueva: fundar multiplica la reputación final por ~3,7. Sin renovar, fundar solo aporta +48 % (157Qa frente a 106Qa), así que la dominancia viene sobre todo de combinar fundación y prestigio por ciudad.
5. **No hay estrategia dominante de «comprar el último edificio».** Solo el 20–22 % de las compras de edificios son del más caro desbloqueado: hitos, mejoras y sinergias generan alternativas. Es un resultado deseable de la fase 2.
6. **Offline:** el perfil Sesiones obtiene el 23 % de su dinero sin conexión. Entre 9 y 12 h de ausencia produce cero (límite de 8 h), y sus $/s no cambian entre la hora 1 y la 4.

### 21.2 Orden de corrección propuesto

1. **Prestigio primero:** sin él, cualquier precio de fundación queda desbordado. Alternativas a simular: divisor de 10⁷–10⁹, raíz cúbica (el cambio que documenta Pressure Works [R17]) o bonus por punto decreciente. Objetivo candidato: primera renovación al cabo de horas, no minutos, y recuperación medible.
2. **Monedas después:** bonus permanente decreciente o con tope, y Click Frenzy independiente de Golden Touch. La diferencia aceptable entre juego activo y espaciado es una decisión del proyecto (sección 10); hoy es ~67×.
3. **Fundación al final:** repetir la matriz de precios con el prestigio corregido. Si sigue dominando, revisar si cada ciudad debe tener una raíz propia o compartir una métrica de imperio con rendimientos decrecientes.

Limitaciones: valor esperado continuo (suaviza la varianza de las monedas y adelanta las primeras compras), renovación instantánea y óptima, y Espaciado decide solo cada 30 min (de ahí las recuperaciones de «30 min»).

## 22. Alternativas de prestigio simuladas (10 de noviembre de 2026)

Suite: `tools/balance_sim.gd -- --suite=prestige`. Datos completos: [SIMULACION_PRESTIGIO.md](SIMULACION_PRESTIGIO.md). Seis fórmulas × dos perfiles × monedas actuales o corregidas (+0,5 % por moneda y Click Frenzy sin Golden Touch), con y sin fundar.

### 22.1 Lectura

| Fórmula | Monedas | Reputación 72 h (Activo / Espaciado) | Renovar × (Activo / Espaciado) | Recuperación (Activo / Espaciado) |
|---|---|---:|---:|---:|
| Actual √(ganado/100K) | actuales | 2,2·10¹² / 2,5·10⁸ | ×2,3·10¹² / ×4,7·10⁷ | 4 min / 30 min |
| √(ganado/1B) | actuales | 2,2·10⁷ / 3.340 | ×2,2·10⁶ / ×60 | 25 min / 1,5 h |
| ∛(ganado/10M) | actuales | 33.100 / 986 | ×2.000 / ×17 | 21 min / 1,5 h |
| **∛(ganado/10M)** | **corregidas** | **4.100 / 416** | **×97 / ×5,3** | **17 min / 1,5 h** |
| √(ganado/100K), +10 %·√rep | corregidas | 6,4·10⁶ / 263.000 | ×1.200 / ×150 | 9 min / 30 min |

1. **Subir el divisor no basta con raíz cuadrada:** a 1B sigue habiendo millones de puntos para el Activo. La raíz cúbica es la palanca más eficaz, como en el cambio que documenta Pressure Works [R17].
2. **Candidato recomendado: ∛(ganado / 10M) con +1 % por punto, junto con la corrección de monedas.** Renovar sigue mereciendo la pena (×5 a ×97 en 72 h), la ciudad tarda de 17 min a 1,5 h en recuperarse y la reputación queda en miles: las mejoras de Reputación (3–20 puntos) se compran pronto y conviene ampliar su catálogo.
3. **Fundar sigue dominando con todas las fórmulas** (+846 % a +13.000 %), y más aún con las monedas corregidas, porque la base es menor. La causa es estructural: con prestigio local, cada ciudad nueva empieza una raíz desde cero. Ajustar la fórmula no lo resuelve.
4. **Corregir las monedas a +0,5 % no basta para la ventaja activa:** el Activo sigue ganando entre ×250 y ×28.000 más que el Espaciado. Parte es inevitable (el Activo está presente 30 veces más tiempo y decide continuamente), pero 5.000 monedas × 0,5 % siguen dando ×26. Hace falta un tope al bonus permanente o eliminarlo.
5. La primera renovación del Activo sigue llegando en minutos con todas las fórmulas, porque el valor esperado de las monedas acelera el arranque. Con monedas reales (varianza) y sin bot perfecto será más lenta; conviene medirlo en pruebas.

### 22.2 Propuesta para la siguiente iteración

- **Prestigio:** ∛(ganado / 10M), +1 % por punto.
- **Métrica de imperio con reparto por ciudad**, para que fundar no regale raíces nuevas sin reabrir el exploit de la ciudad vacía:
  `objetivo = f(Σ ganado de todas las ciudades)`; al renovar la ciudad *i*, se obtiene `(objetivo − ya reclamado) × no_reclamado_i / Σ no_reclamado`. Una ciudad vacía no tiene nada sin reclamar, y tener muchas ciudades no multiplica raíces.
- **Monedas:** bonus permanente con tope (p. ej., +50 % en total) o sin bonus permanente; Click Frenzy sin Golden Touch.
- Volver a simular la matriz de fundación con esos tres cambios antes de tocar `game.gd`.

## 23. Reputación de imperio y tope de monedas (10 de noviembre de 2026)

Suite: `tools/balance_sim.gd -- --suite=empire`. Datos completos: [SIMULACION_IMPERIO.md](SIMULACION_IMPERIO.md). Prestigio ∛(ganado/10M) con +1 % por punto y Click Frenzy sin Golden Touch en todos los casos.

### 23.1 Lectura

| Ámbito | Monedas | Renovar × (Activo / Espaciado) | Fundar (Activo / Espaciado) | Recuperación (Activo / Espaciado) | Activo / Espaciado |
|---|---|---:|---:|---:|---:|
| Ciudad | +0,5 % sin tope | ×97 / ×5,3 | +846 % / +1.850 % | 17 min / 1,5 h | ×572 |
| Imperio | +0,5 % sin tope | ×21 / ×1,6 | +110 % / +484 % | 49 min / 2,5 h | ×423 |
| Ciudad | +2 %, tope +50 % | ×9,4 / ×3,3 | +470 % / +1.395 % | 12 min / 1,5 h | ×4,1 |
| **Imperio** | **+2 %, tope +50 %** | **×2,5 / ×1,4** | **+49 % / +528 %** | **51 min / 2 h** | **×2,5** |
| Imperio | sin bonus permanente | ×2,6 / ×1,3 | +67 % / +526 % | 1,3 h / 3 h | ×2,8 |

1. **El tope de monedas es lo que cierra la brecha activa:** de ×423–572 a ×2,5–4. Un bonus por moneda sin tope, aunque sea pequeño, sigue creciendo indefinidamente con el tiempo mirando. Con tope o sin bonus permanente, los resultados son parecidos (×2,5 frente a ×2,8); el tope conserva la sorpresa inicial de las monedas.
2. **La Reputación de imperio quita la mayor parte de la ventaja de fundar** para el jugador activo (de +470 % a +49 %) y deja la renovación en un rango razonable: ×2,5 de beneficio y ~50 min de recuperación.
3. **Para el perfil Espaciado, fundar sigue valiendo +360 % a +730 %** con cualquier precio. Ya no se debe a raíces gratis: con una sola ciudad, renovar detiene toda la producción durante horas (recuperación de 2 h y decisiones solo cada 30 min); con varias, las demás siguen produciendo. Es una ventaja legítima de expandirse y encaja con el pilar 3, pero la recuperación del precio (30–60 min, una o dos visitas) indica que la decisión sigue siendo obvia.
4. **La expansión se detiene el primer día.** Con todos los precios simulados, las ciudades a las 24 h coinciden con las de las 72 h (8 a 15 según el factor). El precio exponencial alcanza a una producción que, ya domada, crece más despacio. El factor decide cuántas ciudades habrá (3 → ~15, 5 → ~10, 8 → ~8); la base apenas influye.
5. **Renovar con métrica de imperio aporta poco al Espaciado (×1,3–1,6 en 72 h).** Si se quiere que renovar sea una decisión atractiva también para quien consulta poco, conviene probar un divisor menor (10⁶) o mejoras de Reputación que aceleren la recuperación (p. ej., ampliar Head Start).

### 23.2 Configuración recomendada para implementar

| Sistema | Valor | Motivo |
|---|---|---|
| Reputación | `∛(ganado del imperio / 10M)`, +1 % por punto | Escala contenida: cientos de puntos en 72 h |
| Reparto | Pendiente del imperio proporcional a lo ganado por la ciudad desde su última renovación | Sin exploit de ciudad vacía y sin raíces gratis por fundar |
| Monedas | +2 % por moneda con tope de +50 %; Click Frenzy sin Golden Touch | Brecha activo/espaciado ×2,5 |
| Fundación | Base 250K, factor 8 | ~8 ciudades; menor ventaja de fundar sin eliminarla |

Pendiente: dar contenido a partir del segundo día (especializaciones, sección 8; mejoras de Reputación nuevas), porque la expansión y la reputación se estabilizan pronto. También probar el divisor 10⁶ y repetir la medición con monedas aleatorias y jugadores reales.

## 24. Configuración implementada (10 de noviembre de 2026)

La configuración de la sección 23.2 está en `game.gd` (versión de guardado 5):

| Sistema | Implementación |
|---|---|
| Reputación | `reputation_for(ganado) = floor(∛(ganado / 10M))` sobre `empire_lifetime()`, la suma de lo ganado por todas las ciudades |
| Reparto | Cada ciudad guarda `claimed_life` (su `lifetime` en la última renovación). `pending_reputation()` = pendiente del imperio × lo que esta ciudad ganó desde entonces ÷ lo que ganaron todas desde entonces |
| Monedas | `golden_bonus()` = `min(2 % × monedas, 50 %)`; el HUD indica «max» al llegar al tope. Click Frenzy multiplica solo el clic base, no la parte de Golden Touch |
| Fundación | Base 250K, factor 8 (250K, 2M, 16M, 128M…) |
| Menú | La pestaña Reputation muestra lo ganado por el imperio, el siguiente punto, la reputación sin cobrar y la parte de la ciudad seleccionada |

**Migración:** las partidas v4 o anteriores conservan ciudades y puntos de Reputación, y todo lo ganado hasta ahora se marca como cobrado. No hay deudas ni puntos regalados; a cambio, una partida antigua con mucha reputación de la fórmula anterior tardará en ganar puntos nuevos.

`tools/balance_sim.gd` usa ahora estos valores por defecto. El informe base regenerado ([SIMULACION_BALANCE.md](SIMULACION_BALANCE.md)) muestra:

- Monedas: 61 % del dinero del Activo (antes 91 %) y efecto ×1,5 a las 24 h (antes ×126).
- Renovar: primera vez a los 4 min (Activo) o 1 h (Espaciado); la ciudad se recupera en 20 min o 1,5 h; 64–128 puntos en 72 h.
- **Nuevo hallazgo:** sin fundar ni renovar, una ciudad se estanca hacia las 24 h (160M $/s a las 24 h y a las 72 h). Junto con el tope de ~8 ciudades del primer día, confirma que falta contenido a partir del segundo día (sección 23.2).

Las suites `prestige` y `empire` fijan las condiciones con las que se ejecutaron (monedas originales, factor 5) para que se puedan reproducir.
