# Plan para Claude Code — Rediseño Liquid Glass del Himnario Adventista

> **Cómo usar este archivo:** colócalo en la raíz de tu copia (fork) del repo y dile a Claude Code:
> *"Lee `PLAN_LIQUID_GLASS.md` y ejecuta la Fase 1. Detente al terminarla y muéstrame el resultado."*
> Avanza fase por fase. No pidas todo de una vez.

---

## 0. Contexto

- **Proyecto original:** [GoGoShift/Hymnal-Flutter](https://github.com/GoGoShift/Hymnal-Flutter), creado por **Isaac R.** Es una app Flutter (v5.0.2) con himnarios en español, inglés, portugués y ruso, audio en segundo plano, partituras, favoritos e historial.
- **Objetivo:** rediseñar la interfaz con estilo **Liquid Glass "Clear"** de Apple (refracción en el borde, casi sin desenfoque) para **Android primero**, con diseños adaptados a **celular, tableta horizontal, tableta vertical y pantalla dividida**.
- **Diseño aprobado:** lienzo "Himnario Adventista — Rediseño Liquid Glass" (10 pantallas). Este documento resume todo lo que Claude Code necesita de ese lienzo, porque no puede abrirlo.

### Reglas para Claude Code (obligatorias)

1. Trabaja en la rama `feat/liquid-glass`. No hagas commits en `main`.
2. Un commit por fase (o por subfase grande), con mensajes en español y formato `tipo(alcance): descripción`.
3. **No elimines funciones existentes:** búsqueda, historial, favoritos con reordenamiento, cambio de himnario, audio instrumental y cantado, reproducción continua, partituras, compartir, pantalla siempre encendida y los 4 idiomas.
4. Al cerrar cada fase ejecuta `fvm flutter analyze` y `fvm flutter test`; ambos deben pasar.
5. Todo texto visible nuevo va en los 4 archivos ARB (`lib/l10n/app_es.arb`, `app_en.arb`, `app_pt.arb`, `app_ru.arb`). Después ejecuta `fvm flutter gen-l10n`.
6. Si una API del paquete no coincide con lo descrito aquí, **lee el código fuente del paquete** en `~/.pub-cache` y adáptate. No inventes parámetros.
7. Antes de borrar archivos o cambiar algo irreversible (por ejemplo, convertir los 47 MB de partituras), pregunta.

---

## 1. Requisitos técnicos

| Elemento | Valor |
|---|---|
| Flutter | **3.47.x** (el paquete exige `>=3.47.0`; su app de ejemplo usa 3.47.1) |
| Dart SDK | 3.13.x (el paquete declara `sdk: ">=3.13.0 <3.14.0"`) |
| Paquete de cristal | `liquid_glass_renderer: 1.0.0-dev.2`, **versión fija**, porque es una prerelease |
| Motor | Impeller + Flutter GPU (vista previa) |

### 1.1 Pasos

1. Actualiza `.fvmrc` a `{"flutter": "3.47.1"}` y corrige la versión que aparece en `AGENTS.md` (hoy dice 3.38.9).
2. En `pubspec.yaml`:
   - `environment: sdk: ">=3.13.0 <4.0.0"`
   - agrega `liquid_glass_renderer: 1.0.0-dev.2`
3. En `android/app/src/main/AndroidManifest.xml`, dentro de `<application>`:
   ```xml
   <meta-data android:name="io.flutter.embedding.android.EnableImpeller" android:value="true" />
   <meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />
   ```
4. En iOS, para más adelante, agrega `FLTEnableFlutterGPU = true` en `ios/Runner/Info.plist`. No es prioridad ahora.
5. En `main.dart`, antes de `runApp`, ejecuta `await LiquidGlass.precache();`. Es opcional y retrasa un poco el arranque; déjalo detrás de una constante para poder medir con y sin él.
6. Para probar: `fvm flutter run --enable-impeller --enable-flutter-gpu` y, para medir rendimiento, `fvm flutter run --profile`.

---

## 2. Fase 1 — Prototipo (laboratorio de cristal)

**Objetivo:** confirmar en un celular Android real que el cristal Clear se ve bien y va fluido, **antes** de rediseñar la app.

Crea `lib/layers/screens/glass_lab/glass_lab_screen.dart`, accesible desde Ajustes solo en modo debug (`kDebugMode`).

**Contenido:**
- **Fondo:** `assets/background_image.png` a pantalla completa (`BoxFit.cover`).
- **Una barra de pestañas flotante** (cápsula de 64 dp de alto) con 4 pestañas (Inicio, Listas, Favoritos, Ajustes) y, al lado, un **botón circular de búsqueda** de 64 dp. Ambos van en **un solo** `LiquidGlassLayer` dentro de un `LiquidGlassBlendGroup` (con `blend: 20`), para que se fundan como gotas al acercarse.
- **Un botón circular de reproducir** de 64 dp con tinte azul `#1F4FD1`.
- **Un mini reproductor** (cápsula de 60 dp) con número, título y botón de pausa.
- **Controles de prueba:**
  - Deslizador `tintAmount` de 0 a 1 (0 = Clear, 1 = Tintado).
  - Interruptor "Forzar FakeGlass" (`fake: true` en el layer).
  - Interruptor "Fondo animado": desplaza el fondo lentamente para ver la refracción en movimiento.
  - Interruptor para `showPerformanceOverlay`.

**Configuración del cristal:**
```dart
LiquidGlassLayer(
  settings: LiquidGlassSettings.ios27Clear(tintAmount: tint),
  defaultAppearance: const LiquidGlassAppearance.ios27Clear(),
  fake: forceFake,
  child: LiquidGlassBlendGroup(
    blend: 20,
    child: /* fila con LiquidGlass.grouped(...) */,
  ),
)
```
- **Formas:** `LiquidRoundedSuperellipse(borderRadius: 32)` para las cápsulas y `LiquidOval()` para los círculos.
- **Pestaña activa:** una píldora interior **sin** cristal propio (fondo blanco al 55 %), para no apilar cristal sobre cristal.

**Criterios de aceptación:**
- [ ] La refracción del borde es visible al mover el fondo.
- [ ] Con `tintAmount = 0` se ve Clear y con `1` se ve tintado.
- [ ] Mantiene 60 fps en modo `--profile` en el celular de prueba (anota el modelo).
- [ ] FakeGlass se activa solo cuando se fuerza, o cuando el dispositivo no soporta Flutter GPU.
- [ ] El laboratorio no aparece en compilaciones de release.

**Al terminar:** detente, haz commit y pide al usuario que lo pruebe en su celular antes de seguir.

---

## 3. Fase 2 — Sistema de diseño de cristal

Crea `lib/styles/glass/` con:

### 3.1 Tokens (`glass_tokens.dart`)

| Token | Claro | Oscuro |
|---|---|---|
| Texto principal | `#0E1A2B` | `#F2F5FA` |
| Texto secundario | `#26344A` | `#C5CEDD` |
| Acento (texto e íconos activos) | `#1F4FD1` | `#A9C1FF` |
| Tinte de botones principales | `#1F4FD1` al 84 % | `#4A72EC` al 82 % |
| Favorito activo | `#C2410C` | `#FDBA74` |
| Pestaña o opción seleccionada | blanco al 58 % | blanco al 16 % |

**Radios:** las cápsulas usan la mitad de su altura; tarjetas de 28 dp; tarjeta de letra de 32 dp (34 en tableta); miniaturas de 18 dp.

**Espaciado:** márgenes de pantalla de 20 dp en celular y 24 dp en tableta; separaciones de 10, 12, 14 y 16 dp.

**Áreas táctiles:** mínimo 48 dp.

### 3.2 Tipografía (`glass_typography.dart`, con `google_fonts`)

- **Inter** para la interfaz:
  - título de pantalla 34/700 (-2 % de interletra)
  - filas de lista 16/500 (600 si está seleccionada)
  - etiquetas de sección 13/700 en MAYÚSCULAS
  - etiquetas de pestañas 11
- **Literata** para el contenido del himno:
  - título del himno 28/600 en celular, 30 en tableta horizontal, 34 en tableta vertical
  - letra 19 con interlineado 1.6 en celular, 18/1.55 en tableta horizontal, 22/1.6 en tableta vertical
- El tamaño de letra que el usuario elige en Ajustes multiplica la escala de la letra, no la de la interfaz.

### 3.3 Componentes (`lib/widgets/glass/`)

Todos aceptan `semanticLabel` y respetan las áreas táctiles mínimas:

| Componente | Uso |
|---|---|
| `GlassScope` | Lee `tintAmount` y el brillo desde `SettingsService` y expone la configuración (`LiquidGlassSettings.ios27Clear(tintAmount:)`) a sus hijos. |
| `GlassIconButton` | Círculo de 48 dp (64 en barras). |
| `GlassPill` | Contenedor cápsula con hijos (grupo de acciones del encabezado). |
| `GlassSegmented` | Control segmentado (Numérico/Alfabético/Temático, Instrumental/Cantado, Claro/Oscuro/Sistema). |
| `GlassSwitch` y `GlassSlider` | Interruptor y deslizador. |
| `GlassTabBar` | Barra inferior más botón de búsqueda separado. |
| `GlassNavigationRail` | Barra lateral para tableta (84 dp de ancho, cápsula vertical). |
| `GlassMiniPlayer` | Mini reproductor flotante, conectado a `AudioService`. |
| `LyricsCard` | Tarjeta de letra **tintada**; ver la regla de legibilidad abajo. |

### 3.4 Reglas de cristal (importantes)

- **Un `LiquidGlassLayer` por zona de pantalla** (barra inferior, encabezado y mini reproductor pueden compartir uno si están juntos). Cada layer copia el fondo y esa copia es lo caro. **Máximo 16 formas por layer.**
- **No pongas cristal sobre cristal.** Si hace falta (por ejemplo, el indicador sobre la barra de pestañas), usa `LiquidGlassCapture`.
- **Legibilidad:** los controles usan Clear según el deslizador, pero la `LyricsCard` usa siempre un tinte alto (`tintAmount` mínimo de 0.85, o una superficie translúcida con desenfoque de unos 30). La letra debe leerse bien sobre cualquier paisaje, con contraste de al menos 4.5:1.
- **Accesibilidad:** si el sistema pide reducir transparencia o alto contraste (`MediaQuery.highContrastOf`), fuerza `tintAmount = 1`.
- **No animes la geometría** de un `LiquidGlassBlendGroup` en cada cuadro, salvo en transiciones cortas.

### 3.5 Ajuste "Cristal"

- En `SettingsService` y `SettingsRepository`, agrega `glassTint` (`double` de 0 a 1, por defecto 0.1), guardado en `SharedPreferences`.
- En Ajustes > Apariencia, agrega un deslizador **"Cristal: Transparente ↔ Tintado"**.

---

## 4. Fase 3 — Diseño adaptable (celular, tableta y pantalla dividida)

Decide el diseño en `MainTabsScreen` con `LayoutBuilder`, según el **ancho disponible de la ventana**. Así la pantalla dividida se resuelve sola.

| Clase | Condición | Navegación | Contenido |
|---|---|---|---|
| **Compacta** | ancho < 600 | `GlassTabBar` abajo | Una columna (celular y pantalla dividida) |
| **Mediana** | 600 ≤ ancho < 840, o alto < 600 | `GlassNavigationRail` | Una columna centrada, máximo 600 dp de ancho |
| **Expandida** | ancho ≥ 840 y alto ≥ 600 | `GlassNavigationRail` | **Lista y detalle a la vez:** lista de 380 dp a la izquierda y himno a la derecha (máximo 640 dp, centrado) |

**Detalles:**
- **En la vista expandida:** al tocar un himno de la lista, el detalle se actualiza **sin navegar a otra pantalla**. Guarda el himno seleccionado en un `ValueNotifier` del controlador de listas.
- **Al rotar o cambiar de tamaño:** conserva el himno abierto. Si pasas de expandida a compacta con un himno seleccionado, ábrelo como pantalla normal.
- **Barra lateral, de arriba a abajo:** insignia del himnario (por ejemplo "ES"), Inicio, Listas, Favoritos, Historial, Ajustes y, al fondo, Buscar.
- **Mini reproductor:** en compacta va encima de la barra inferior; en mediana y expandida, abajo y centrado sobre el área de detalle (máximo 640 dp de ancho).
- **Reemplaza `playerBottomOffset: 56.0`,** que hoy está fijo en el código, por un valor calculado según el diseño.

---

## 5. Fase 4 — Pantallas (especificación del lienzo)

Todas las pantallas tienen el paisaje de fondo (Fase 5) y los controles de cristal encima.

### 5.1 Inicio
- **Encabezado:** "Himnario Adventista" (13/600) sobre "Inicio" (34/700), y un botón circular de Historial a la derecha.
- **Selector de himnario:** cápsula de 60 dp con insignia tintada "ES", nombre ("Nueva Versión 2009"), detalle ("Español · 614 himnos") y una flecha. Abre la lista de himnarios.
- **Tarjeta del número:**
  - Etiqueta "Número del himno".
  - Número grande en Literata 64/600.
  - **Vista previa del título en tiempo real** con un check: si el número existe se muestra el título; si no, el mensaje "No existe" en un color de aviso.
  - **Teclado numérico de cristal** de 3 columnas: 1–9, "Borrar", 0 y retroceso. Teclas de 52 dp.
- **Botón tintado "Abrir himno"** de 56 dp, desactivado si el número no existe.
- **Abajo:** la barra de pestañas.
- **Teclado del sistema:** no lo muestres en celular porque el teclado propio lo reemplaza. En tableta horizontal puede usarse el teclado físico.

### 5.2 Listas
- Encabezado con el himnario (13/600) sobre "Listas".
- `GlassSegmented`: Numérico / Alfabético / Temático.
- **Numérico y Alfabético:** una tarjeta de cristal que continúa por debajo del mini reproductor y la barra (el contenido se desplaza detrás del cristal). Cada fila mide 54 dp, con una insignia circular de 36 dp que lleva el número y el título. Si el himno está sonando, la insignia va tintada y aparece un ícono de ecualizador.
- **Índice lateral:** una cápsula de 34 dp a la derecha (1, 100, 200 … 600). Reemplaza el índice de `azlistview` o dale estilo de cristal.
- **Temático:** acordeones por tema ("El culto · 5 secciones · himnos 1–52"). Al expandir, muestra una **grilla de secciones** (2 columnas en pantalla dividida y tableta, 1 en celular) con nombre y rango de himnos.

### 5.3 Himno
- **Encabezado:** botón Volver a la izquierda; a la derecha, una `GlassPill` con tamaño de letra (Aa), favorito, partitura (solo si existe) y compartir.
- **`LyricsCard`:**
  - etiqueta "Himno 1 · Adoración y alabanza" (12/600, en MAYÚSCULAS, color de acento)
  - título en Literata
  - autores (12, texto secundario)
  - estrofas con una **insignia circular tintada de 28 dp** que lleva el número de estrofa; quita la línea "1." del texto al mostrarla
- **Abajo:** `GlassSegmented` Instrumental/Cantado (con íconos) y un botón circular tintado de reproducir de 64 dp.
- **Cambio de himno:** mantén el `PageView` para deslizar entre himnos y muestra a los costados el borde de las tarjetas vecinas como pista visual.
- **En tableta:** encabezado con "‹ Himno 1 de 614 ›". En la vertical, debajo de la letra va una tarjeta "Siguiente himno".

### 5.4 Reproductor
- Fondo: el paisaje actual con desenfoque fuerte (unos 18).
- **Encabezado:** cerrar (flecha hacia abajo), "Reproduciendo" y compartir.
- **"Portada":** cuadrado de cristal de 272 dp con el número en Literata 132 y el nombre del himnario.
- **Información:** título (Literata 25/600) y "Sección · Instrumental".
- **Barra de progreso de cristal:** la parte avanzada en color de acento y una perilla de cristal; tiempo transcurrido y tiempo restante en números de ancho fijo.
- **Controles:** anterior (círculo de 56), retroceder 10 s, **pausa/reproducir tintado de 84**, adelantar 10 s y siguiente (círculo de 56).
- **Fila inferior:** Instrumental/Cantado y una cápsula "Continua" (activa o inactiva).
- **Tarjeta "A continuación":** muestra el siguiente himno con un botón "Ver letra".

### 5.5 Ajustes
- **Fondo:**
  - galería de 4 miniaturas de 92 dp de alto; la elegida lleva un anillo de acento y un check
  - interruptor "Cambiar fondo automáticamente"
  - control segmentado de frecuencia: "Al abrir" / "Cada himno" / "5 min"
- **Apariencia:** tema (Claro/Oscuro/Sistema), tamaño de letra (A pequeña – A grande) y **Cristal (Transparente ↔ Tintado)**.
- **Himnario:** fila con el himnario actual.
- **Comportamiento:** pantalla siempre encendida.
- **Datos:** borrar historial y borrar favoritos.
- **Acerca de:** sitio web, contacto, repositorio, versión, licencias y **créditos** (ver sección 9).

### 5.6 Favoritos, Historial y Búsqueda
- Usan los mismos componentes que Listas. Favoritos conserva el reordenamiento por arrastre.
- La búsqueda se abre desde el botón circular de la barra, con un campo de cristal ("Título, letra o número").

### 5.7 Partitura (ver Fase 6)
- **Encabezado:** Volver, una cápsula "PARTITURA · HIMNO 1 / Cantad alegres al Señor" y un botón "Cambiar paisaje".
- **Celular:** abajo, una cápsula con reproducir, tipo de audio y progreso, más un botón "Letra".
- **Tableta:** cápsula de zoom (− 100 % +) e indicador "Página 1 de N".

---

## 6. Fase 5 — Fondos de paisajes con transición suave

1. **Carpeta de imágenes:** crea `assets/backgrounds/`. El usuario aportará las fotos, que deben ser **propias o con licencia libre** (Unsplash o Pexels) y **nunca** imágenes con marca de agua o de terceros sin permiso.
   - Formato WebP de unos 1600 px de lado mayor, calidad 80.
   - Mientras no estén, usa `background_image.png` más 3 variantes de color generadas con un script de Python (atardecer, noche y niebla), solo como marcadores temporales.
2. **Catálogo:** crea `assets/backgrounds/backgrounds.json` con `id`, archivo, nombre en los 4 idiomas, variante clara u oscura y crédito del autor.
3. **`BackgroundService`:**
   - Lee el catálogo.
   - Guarda en `SharedPreferences`: fondo elegido, modo automático y frecuencia (`onOpen`, `perHymn`, `every5min`).
   - Precarga la siguiente imagen con `precacheImage`.
4. **`AppBackground`:** un solo widget en la raíz (debajo de todo el cristal) que usa `AnimatedSwitcher` con fundido de **1200 ms** (`Curves.easeInOut`) y un leve zoom de 1.03 a 1.0.
   - En modo oscuro, aplica una capa oscura encima o elige automáticamente variantes nocturnas.
5. **Ajuste existente:** respeta `showBackgroundImage`. Si está apagado, usa un degradado neutro suave para que el cristal tenga algo que refractar.

---

## 7. Fase 6 — Partituras transparentes sobre el paisaje

Idea aprobada: las notas se ven directamente sobre el paisaje; el cielo queda detrás de los pentagramas y el paisaje se ve abajo.

1. **Script `tool/convert_sheets.py`** (Python con Pillow), que **no se empaqueta** con la app:
   - Convierte cada `assets/musicSheets/*.png` a escala de grises.
   - Calcula `alpha = 255 − luminancia` y pinta las notas en `#141824`.
   - Guarda como WebP con transparencia en `assets/musicSheets_webp/`.
   - Muestra un informe del tamaño total antes y después (hoy pesan unos 47 MB).
   - **Pregunta antes** de reemplazar la carpeta original.
2. **Datos:** actualiza `hymnsSheetsFileName` en `assets/info_constants.json` (de `.png` a `.webp`) y las rutas en `pubspec.yaml`.
3. **Comprobar si una partitura existe:** reemplaza `_assetExists`, que hoy carga la imagen completa hasta 7 veces, por una consulta al índice de recursos (`AssetManifest.loadFromAssetBundle(rootBundle)`) hecha **una sola vez** y guardada en memoria.
4. **`SheetsScreen`:**
   - **Fondo:** cielo claro en la parte superior que se funde con el paisaje en la mitad inferior. Componlo con un `ShaderMask` o un degradado sobre la imagen del paisaje.
   - **Legibilidad:** detrás de cada imagen de partitura dibuja una copia en blanco desenfocada (`ColorFiltered` en blanco + `ImageFiltered` con desenfoque de 1.5) que hace de halo.
   - **Modo oscuro:** notas en blanco (invierte el color) y halo oscuro, sobre un paisaje nocturno.
   - **Varias páginas** (`_1`, `_2`, …): desplazamiento vertical en celular. En tableta horizontal, dos páginas lado a lado si caben.
   - **Zoom:** conserva el de `photo_view`.

---

## 8. Fase 7 — Arreglos pendientes de la revisión del repo

Hazlos en commits separados (`fix(...)`):

1. **`opencode.jsonc`** contiene una API key de Context7 a la vista. Quítala del archivo y agrégalo a `.gitignore`. **Avisa al usuario** de que la key debe revocarse. Esto no lo puede hacer Claude Code.
2. **Notificación de audio:** en `audio_handler.dart`, agrega `MediaControl.skipToPrevious` y `MediaControl.skipToNext` a los controles para que funcionen desde la notificación y los auriculares.
3. **Barra del reproductor colgada:** cuando se detiene el audio desde la notificación (estado `idle` después de reproducir), `AudioService` debe pasar por `stop()` y `finalizeDismiss()`.
4. **Doble salto:** evita que `completed` dispare `skipNext()` dos veces seguidas; guarda una bandera hasta que cargue el siguiente himno.
5. **Cierres inesperados:** cambia los `firstWhere` sin `orElse` (en `hymn_controller`, `history_controller`, `favorites_controller`, `settings_service.selectHymnal` y `hymnal_repository`) por `firstWhereOrNull` o por un manejo con mensaje de error.
6. **Pantalla encendida:** el wakelock debe manejarse con un contador de referencias, no desactivarse en cada `dispose`.
7. **Favoritos:** usa la lista `_favorites` en memoria para `isFavorite`, en lugar de decodificar SharedPreferences en cada consulta.
8. **Dependencias sin usar:** quita `get`, `get_it_mixin`, `dartz`, `flutter_secure_storage`, `cached_network_image`, `logger`, `flutter_svg`, `path_provider`, `json_annotation` y `json_serializable`, comprobando primero con `grep` que no se usan. Fija `intl` a una versión concreta.

---

## 9. Créditos y licencia (antes de publicar)

- **El repo original no tiene archivo LICENSE.** Legalmente eso significa "todos los derechos reservados". **Antes de publicar** esta versión en la Play Store o en un repo público, el usuario debe **pedir permiso a Isaac R. (GoGoShift)** o proponerle el rediseño como Pull Request. Recuérdaselo al usuario al terminar la Fase 4.
- **Créditos en `README.md`:** agrega una sección "Créditos": *"Basado en [Hymnal-Flutter](https://github.com/GoGoShift/Hymnal-Flutter) de Isaac R. (GoGoShift). Rediseño Liquid Glass por <nombre del usuario>."*
- **Créditos en la app:** Ajustes > Acerca de > "Créditos", con el mismo texto y los créditos de cada foto de fondo (sacados de `backgrounds.json`).
- **Paquetes de terceros:** `liquid_glass_renderer` usa licencia MIT. Asegúrate de que aparezca en la pantalla de licencias (`showLicensePage`).

---

## 10. Pruebas y control de calidad

**Dispositivos o emuladores:**
- [ ] Celular Android de gama media (real)
- [ ] Celular Android de gama baja o emulador con poca GPU (comprueba que cae a FakeGlass sin errores)
- [ ] Tableta de 10" en horizontal y en vertical
- [ ] Pantalla dividida al 50 % y al 33 %
- [ ] Celular en horizontal

**Comportamiento:**
- [ ] Modo claro, oscuro y sistema; deslizador de cristal en 0, 0.5 y 1
- [ ] Tamaño de letra del sistema al 200 % (`textScaler`): nada se corta
- [ ] Lector de pantalla (TalkBack): todos los botones de solo ícono tienen etiqueta
- [ ] Sin conexión: la app abre y el audio se oculta sin errores
- [ ] Rendimiento: en `--profile`, sin tirones al desplazar listas largas con la barra de cristal encima

**Pruebas automáticas:**
- [ ] Widget tests: `GlassSegmented`, el teclado de Inicio (vista previa del título, número inexistente) y el cambio de diseño compacta/mediana/expandida con `tester.view.physicalSize`.
- [ ] Unit tests: `BackgroundService` (frecuencias) y la búsqueda de partituras con `AssetManifest`.

---

## 11. Orden de entrega

| Fase | Entregable | Detenerse y mostrar al usuario |
|---|---|---|
| 1 | Laboratorio de cristal | **Sí:** el usuario lo prueba en su celular |
| 2 | Sistema de diseño y componentes | Sí: capturas del catálogo de componentes |
| 3 | Diseño adaptable | Sí: capturas en celular, tableta y pantalla dividida |
| 4 | Pantallas rediseñadas | Sí |
| 5 | Fondos con transición | Sí |
| 6 | Partituras transparentes | Sí: **preguntar antes** de reemplazar los PNG |
| 7 | Arreglos de la revisión | Sí |
| — | Créditos, licencia y pruebas finales | Recordar el tema de la licencia |
