# NirnSteelUI — Dirección visual y sistema de diseño

Versión 0.1 · 8 de septiembre de 2026 · Propuesta de referencia para evolución del addon.

## 1. Identidad

**Una interfaz de fantasía forjada en acero: oscura, precisa y legible, con oro reservado para orientación, relevancia y recompensa.**

El HUD debe sentirse integrado en Elder Scrolls Online. Sus piezas comparten materiales y acabados, mientras su ornamentación responde a la función. El combate exige lectura inmediata; los logros admiten una expresión más ceremonial.

Esta guía se basa en los controles, valores y texturas del repositorio actual. No es una validación visual dentro de ESO. Las reglas de normalización siguientes son propuestas; este documento no cambia los ajustes ni la apariencia instalada.

## 2. Referencias actuales

| Referencia | Rasgos que conservar | Papel en el sistema |
| --- | --- | --- |
| `modules/minimap.lua` | Acero oscuro, bisel plateado, acentos dorados, contornos definidos | Referencia principal de materiales y navegación |
| `modules/bar_visuals.lua`, `resource_bars.lua`, `target_frame.lua`, `group_frames.lua` | Rellenos semánticos, sombras, brillo contenido, texto protegido por contorno | Familia de información de combate; aprovechar la base compartida existente |
| `modules/action_bar_frames.lua`, `synergy_alert.lua` | Marcos e iconos nativos de ESO, respuesta al uso | Familia de acciones disponibles |
| `modules/experience_tracker.lua` | Panel compacto, ribetes de acero, jerarquía entre nivel y progreso | Familia de progreso |
| `modules/pvp.lua`, `damage_numbers.lua` | Emblemas facetados, alas segmentadas, impacto y transformación por hitos | Familia de celebraciones |
| `ui/loot_history.xml` | Fondo oscuro cálido, filo dorado y acentos de rareza | Familia de recompensas y notificaciones |

Ya existen variaciones: el marfil es más cálido en recursos que en PvP; el minimapa usa una base fría y el loot una cálida; tamaños, sombras y colores se definen en varios lugares. Son puntos de partida para normalizar, no motivos para rehacer todos los módulos.

## 3. Principios

1. **La información manda.** Recurso, objetivo y acción disponible se reconocen antes que el adorno.
2. **Material común.** Fondos oscuros, bordes metálicos finos y luz localizada conectan los módulos.
3. **Ornamento proporcional.** La interfaz persistente permanece tranquila; las celebraciones concentran el espectáculo.
4. **Color con significado.** Salud, magicka, stamina, rareza, clase y alianza conservan su semántica.
5. **Centro despejado.** Evitar que paneles y efectos oculten al personaje, la retícula o las señales del combate.
6. **Personalización con una base coherente.** Los valores predeterminados deben funcionar juntos; las preferencias individuales se conservan.

## 4. Paleta y materiales

Valores RGB sin opacidad. Los hexadecimales son aproximaciones redondeadas de las referencias actuales. Los nombres son tokens propuestos, todavía no implementados.

| Token | Color | Referencia / uso propuesto |
| --- | --- | --- |
| `surface.steel` | `#06090C` | Base del minimapa; fondo frío principal |
| `surface.warm` | `#181510` | Fondo actual de loot; variante de recompensa |
| `edge.shadow` | `#0B1114` | Contorno exterior del minimapa |
| `edge.inner` | `#213038` | Bisel interior del minimapa |
| `edge.muted` | `#3D4D57` | Acero discreto del tracker de experiencia |
| `edge.default` | `#A3B8C4` | Plata del minimapa y PvP; aplicar con opacidad según jerarquía |
| `accent.gold` | `#E6BD66` | Acento del minimapa; orientación y énfasis |
| `text.primary` | `#F5EBD1` | Marfil de recursos y objetivo; referencia común propuesta |
| `text.secondary` | `#D9E3E8` | Texto frío del minimapa; metadatos secundarios |
| `status.shield` | `#F29954` | Escudos de recursos, objetivo y grupo |

El oro ocupa detalles, indicadores o hitos. No se extiende a todos los textos y bordes. La superficie cálida es una variante deliberada de recompensa, no una nueva paleta independiente.

Salud roja, magicka azul y stamina verde mantienen sus gradientes actuales. Los colores nativos de objetivos, misiones, rarezas y alianzas tienen prioridad sobre la paleta de marca. Acompañar los estados críticos con texto, icono, valor o forma: el color por sí solo no basta.

Materiales: acero mate con bisel ligero, sombras cortas y rellenos con brillo moderado. Las barras ya ofrecen patrones; el predeterminado Molten de recursos usa un 6 % de opacidad. Mantener esa sutileza como referencia. El patrón nunca debe dificultar estimar el porcentaje restante.

## 5. Forma, espaciado y tipografía

**Forma.** Paneles y barras compactos, de geometría definida; marcos finos y esquinas poco redondeadas. Círculos para navegación o medallones; facetas y alas para emblemas. Los marcos de habilidades conservan su textura nativa. No todas las barras necesitan un borde visible: recursos actualmente usa ancho de borde cero.

**Espaciado propuesto.** Escala de 4, 8, 12, 16 y 24 unidades de UI para nuevos layouts; 8–12 de relleno en paneles, 4–8 entre elementos relacionados y 16–24 entre bloques independientes. Conservar ajustes ópticos cuando una textura lo requiera. Son referencias nuevas, no una descripción de todas las dimensiones existentes.

**Tipografía.** Usar las familias disponibles en ESO. `$(BOLD_FONT)` para datos, nombres y énfasis; `$(MEDIUM_FONT)` para información secundaria. Antique y Trajan quedan como opciones ornamentales, sin convertirlas en la fuente habitual del combate.

| Rol | Tamaño de referencia propuesto | Uso |
| --- | --- | --- |
| Microtexto | 12–14 | Metadatos que no exigen lectura urgente |
| Lectura principal | 16–18 | Nombres y valores del HUD |
| Énfasis | 20–24 | Alertas breves y contadores |
| Hito | 28–36 | Nivel o resultado destacado |

Usar contorno en cifras sobre barras o terreno y sombra suave en paneles sólidos. Evitar mayúsculas en textos largos. Mantener alineación y ancho estable de valores para evitar saltos. Las variantes de mando deben adaptar tamaño y espacio; los tamaños anteriores no sustituyen las fuentes gamepad existentes.

## 6. Familias de componentes

| Familia | Debe contener | Intensidad |
| --- | --- | --- |
| Barras de combate | Canal oscuro, relleno semántico, valor legible, escudo y estado cuando proceda | Baja; realce temporal ante cambios relevantes |
| Objetivo y grupo | Nombre, estado y recurso prioritario; iconos subordinados al dato principal | Baja, con alertas claras |
| Acciones y sinergias | Icono nativo, marco común, disponibilidad, activación y cooldown cuando proceda | Media solo cuando requieren respuesta |
| Navegación | Superficie cartográfica, marco de acero, orientación, marcadores y estado no disponible | Baja y persistente |
| Progreso | Nivel o categoría, barra, progreso y ganancia temporal | Baja; media al subir de nivel |
| Loot y avisos | Icono, nombre, cantidad si procede y semántica de rareza | Media, breve y apilable |
| Celebraciones | Emblema, contador principal, progreso de cadena y escalado por hito | Alta, temporal y configurable |

Las celebraciones de PvP y daño deben compartir construcción metálica, segmentación y respuesta de impacto. Su escala puede crecer por hitos, pero su texto principal conserva prioridad. Una nueva ventana de ajustes, si se crea, reutiliza superficies, tipografía y estados; la configuración actual permanece integrada en LibAddonMenu.

## 7. Jerarquía de pantalla

Prioridad de atención propuesta: peligro o acción inmediata → recursos y objetivo → navegación y grupo → progreso y loot → celebración decorativa.

Mantener recursos y lanzamiento como un conjunto en la zona inferior central. Situar información periférica donde no compita con ese conjunto. El minimapa parte actualmente de abajo a la derecha; cualquier variante superior debe dejar espacio al quest tracker. Reservar separación entre sinergias, emblemas y retícula.

Las posiciones son configurables. La coherencia exige comprobar el conjunto con todos los módulos visibles, además de cada pieza aislada: combate, grupo, loot, minimapa y celebración simultáneos.

## 8. Estados, movimiento y sonido

Todo componente nuevo debe definir los estados que le correspondan: normal, cambio de valor, urgente, no disponible, oculto y vista previa. Los controles interactivos añaden hover, pulsado y deshabilitado, con foco legible cuando admitan navegación por mando.

Movimiento propuesto: entradas de 130–180 ms, salidas de 220–360 ms y respuestas breves al uso. Se inspira en los tiempos actuales de experiencia, lanzamiento y habilidades; no obliga a igualar animaciones con funciones distintas. El dato real se actualiza inmediatamente aunque exista una estela decorativa.

Brillo continuo solo cuando comunica un estado sostenido. Impactos, chispas y transformaciones se reservan para eventos. Con intensidad cero deben mantenerse los valores y estados mediante una representación estática o un fundido simple. Esta regla debe verificarse por módulo antes de considerarla implementada globalmente.

El sonido refuerza la imagen. Los eventos frecuentes necesitan agrupación o límite de repetición; los hitos pueden tener mayor presencia. Separar opciones de sonido e intensidad visual cuando proceda.

## 9. Contrato de un módulo nuevo

Cada módulo debe documentar:

- Su propósito, dato principal, familia visual y prioridad de atención.
- Anatomía, tamaños, anclaje, escala y convivencia con otros módulos.
- Tokens usados y excepciones justificadas por semántica o legibilidad.
- Estados, visibilidad en combate/menús y comportamiento sin datos.
- Animaciones, sonidos y comportamiento con intensidad reducida.
- Ajustes aplicables: activar, posición, escala, opacidad, preview y reset del módulo.
- Textos largos/localización y variante teclado/mando cuando sea compatible.

Reutilizar `BarVisuals` para barras compatibles. Como siguiente paso técnico, extraer colores, fuentes y medidas repetidas a un tema compartido y migrar por familias. No existe todavía un tema global: no asumir que estos tokens ya son una API. La migración debe conservar los ajustes guardados y no reiniciarlos de forma silenciosa.

## 10. Criterios de aceptación visual

- Se identifica el dato principal de un vistazo, también sobre terreno claro y con efectos de combate.
- Material, tipografía y bordes pertenecen a la familia existente.
- El oro y los efectos tienen un motivo concreto.
- El estado se entiende sin depender únicamente del color o el sonido.
- No hay recortes, solapamientos ni cambios molestos de posición al variar valores o nombres.
- Escala mínima/máxima, textos largos y teclado/mando se verifican donde corresponda.
- La vista previa representa estados útiles y no altera datos reales.
- Ocultar, desactivar o restaurar un módulo deja la interfaz en un estado correcto.
- La apariencia final se comprueba en ESO: las reproducciones fuera del cliente no certifican sus fuentes, texturas ni shaders.

## 11. Orden de consolidación

1. Usar esta dirección como referencia de diseño y ajustar sus decisiones al revisar capturas reales del conjunto.
2. Normalizar marfil, ribetes, tipografía y espaciado en las familias persistentes.
3. Consolidar emblemas de PvP y daño como variantes de una misma familia ceremonial.
4. Extraer tokens compartidos y preparar una escena de preview conjunta para detectar desajustes.
5. Añadir capturas de referencia por familia, con versión, escala de UI y modo de entrada registrados.

Una nueva función encaja en NirnSteelUI cuando conserva esta identidad y ocupa el nivel de atención que necesita su información.
