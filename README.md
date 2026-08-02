# 🛒 Goods Sort Master

Juego casual de **ordenar mercancías** (mecánica *triple-match* de bandeja) hecho
en **Godot 4** con **GDScript**, optimizado para **Android**.

El jugador toca los objetos de los estantes para enviarlos a una **bandeja**. Al
reunir **3 objetos iguales**, desaparecen. Si la bandeja se llena sin poder
agrupar, se pierde. Incluye **50 niveles** con dificultad progresiva, temporizador
opcional, monedas, pistas, reintentos y guardado automático.

> **Requisitos:** Godot **4.3 o superior** (rama estable de Godot 4).

---

## 🚀 Cómo abrir y jugar

1. Instala [Godot 4.3+](https://godotengine.org/download).
2. Abre Godot → **Importar** → selecciona el archivo `project.godot` de esta carpeta.
3. Godot importará automáticamente los SVG y los WAV la primera vez (puede tardar
   unos segundos).
4. Pulsa **F5** (o el botón ▶ *Reproducir*) para jugar en el escritorio. El ratón
   emula el toque táctil.

La escena principal es `scenes/MainMenu.tscn`.

---

## 🏗️ Arquitectura

El proyecto sigue una arquitectura **modular y desacoplada**:

- **Singletons (autoloads)** para los servicios globales (estado, guardado,
  audio, niveles, anuncios, analítica). Se configuran en `project.godot`.
- **Escenas independientes** para cada pantalla y componente. Se comunican por
  **señales**, nunca por referencias directas rígidas.
- **Datos separados del código**: los niveles son archivos JSON; añadir uno nuevo
  no requiere tocar ningún script.

```
project.godot          → Configuración global + autoloads + ajustes móviles
export_presets.cfg     → Preset de exportación Android
icon.svg               → Ícono de la app

autoload/              → Singletons (servicios globales)
  GameManager.gd       → Flujo del juego: navegación, nivel actual, monedas, progreso
  SaveManager.gd       → Guardado automático en user://savegame.json
  AudioManager.gd      → SFX y música; crea buses en runtime; respeta el mute
  LevelManager.gd      → Descubre niveles JSON y GENERA el tablero solvable
  AdsManager.gd        → Capa AdMob (STUB, listo para el plugin nativo)
  AnalyticsManager.gd  → Capa Firebase Analytics (STUB, listo para el plugin)

data/                  → Clases de datos y registro de contenido
  Goods.gd             → (autoload) Registro de tipos de mercancía (id→ícono/color)
  LevelData.gd         → Clase tipada que parsea un JSON de nivel

scenes/                → Escenas (.tscn) y sus scripts (.gd)
  MainMenu             → Menú principal
  LevelSelect          → Cuadrícula de niveles (generada desde LevelManager)
  Game                 → Orquestador de la partida (bucle de juego completo)
  Shelf                → Un estante (fila de fichas)
  Good                 → Una mercancía seleccionable
  CollectionTray       → La bandeja de recolección (triple-match)
  HUD                  → Barra superior (monedas, tiempo, pistas, pausa)
  WinPopup / LosePopup / PausePopup → Diálogos
  PopupBase.gd         → Base reutilizable para los diálogos

ui/theme.tres          → Tema global (tamaño de fuente cómodo para el toque)

assets/goods/*.svg     → Íconos cartoon vectoriales de mercancías (placeholders)
assets/audio/*.wav     → Efectos de sonido (placeholders generados)

levels/level_XXX.json  → Definiciones de nivel (DATA-DRIVEN)
```

---

## 🎮 Mecánicas implementadas

| Requisito | Dónde vive |
|---|---|
| Estante con objetos | `scenes/Shelf.gd`, `scenes/Good.gd` |
| Seleccionar objetos | `Good` → `Shelf` → `Game` (por señales) |
| Reunir 3 iguales → desaparecen | `scenes/CollectionTray.gd` |
| Sistema de niveles | `autoload/LevelManager.gd` + `levels/*.json` |
| Dificultad progresiva | Parámetros crecientes en cada `level_XXX.json` |
| Temporizador opcional | `time_limit` del nivel (0 = sin reloj) — `Game._process` |
| Sistema de monedas | `GameManager.add_coins/spend_coins` |
| Pistas | `Game._on_hint` (resalta la mejor ficha, cuesta monedas) |
| Reintentos | `GameManager.restart_level`, popups |
| Guardado automático | `SaveManager` (en cambios y al pausar/cerrar la app) |
| Sonidos y animaciones | `AudioManager` + `Tween` en `Good`/`CollectionTray` |
| Preparado para AdMob | `autoload/AdsManager.gd` |
| Preparado para Firebase | `autoload/AnalyticsManager.gd` |
| Agregar niveles sin código | Soltar un JSON en `levels/` |

---

## ➕ Cómo agregar un nivel nuevo (¡sin tocar código!)

> El juego trae **50 niveles** (`level_001.json` … `level_050.json`). Los niveles
> 11–50 se generaron con `tools/gen_levels.py` (curva de dificultad + solvencia
> garantizada); puedes editarlos a mano o regenerarlos con ese script.

1. Copia cualquier archivo de `levels/`, por ejemplo `level_050.json`, y renómbralo
   a `level_051.json`.
2. Ajusta sus valores:

```json
{
    "id": 11,
    "name": "Mi nivel nuevo",
    "goods": ["apple", "banana", "grapes", "cheese"],
    "triples": 8,
    "shelves": 4,
    "columns": 5,
    "depth": 2,
    "tray_slots": 7,
    "time_limit": 90,
    "hint_cost": 60,
    "reward_coins": 180,
    "difficulty": 4
}
```

3. ¡Listo! Aparecerá automáticamente en la pantalla de selección de niveles.

### Parámetros del nivel

| Campo | Significado |
|---|---|
| `id` | Identificador y orden del nivel. |
| `name` | Nombre visible. |
| `goods` | Tipos de mercancía usados (ids de `data/Goods.gd`). Vacío = todos. |
| `triples` | Nº de tríos. El total de fichas es `triples × 3` (siempre resoluble). |
| `shelves` / `columns` / `depth` | Tamaño del tablero. `depth > 1` apila fichas ocultas. |
| `tray_slots` | Ranuras de la bandeja. Menos ranuras = más difícil. |
| `time_limit` | Segundos de temporizador. `0` = sin temporizador. |
| `hint_cost` | Coste en monedas de una pista. |
| `reward_coins` | Monedas al completar. |
| `difficulty` | Etiqueta de dificultad (informativa / analítica). |

> **Solvencia garantizada:** `LevelManager.build_board()` reparte cada tipo en
> cantidades múltiplo de 3 y respeta la capacidad del tablero, así que el nivel
> siempre se puede resolver.

### Cómo agregar un tipo de mercancía nuevo

1. Coloca su ícono en `assets/goods/<id>.svg`.
2. Añade una entrada a `DEFS` en `data/Goods.gd` con ese mismo `id`.

No hay que tocar nada más.

---

## 📱 Exportar a Android

1. En Godot: **Editor → Gestionar plantillas de exportación** → *Descargar e instalar*.
2. **Editor → Configuración del editor → Export → Android**: configura el
   *Android SDK*, el *JDK* y el *Debug Keystore*.
3. **Proyecto → Exportar**: ya existe el preset **Android** (ver `export_presets.cfg`).
   Cambia `package/unique_name` por tu propio identificador (p. ej.
   `com.tuempresa.goodssortmaster`).
4. Exporta a APK/AAB.

El proyecto ya está configurado para **retrato**, escalado `canvas_items` y
*low-processor mode* (ahorro de batería).

---

## 💰 Conectar AdMob real

Todo el juego llama a `AdsManager`; solo hay que reemplazar el *stub* por el
plugin nativo (el resto del código no cambia):

1. Instala el plugin [godot-admob-android](https://github.com/Poing-Studios/godot-admob-android).
2. Pon tu *App ID* y tus *Ad Unit IDs* (constantes en `autoload/AdsManager.gd`).
3. Descomenta el bloque `Engine.has_singleton("AdMob")` en `_ready()` y sustituye
   los cuerpos *stub* de `show_banner/show_interstitial/show_rewarded` por las
   llamadas del plugin.

Los anuncios recompensados ya están cableados al **reintento gratis** del
`LosePopup`.

---

## 📊 Conectar Firebase Analytics real

1. Instala un plugin de Firebase/Google Play Services para Godot Android.
2. Coloca `google-services.json` en el build de Gradle.
3. En `autoload/AnalyticsManager.gd`, descomenta el bloque
   `Engine.has_singleton("FirebaseAnalytics")` y reenvía `log_event()` al backend.

El juego ya emite eventos útiles: `level_start`, `level_complete`, `level_fail`,
`hint_used`, `coins_changed`, `ad_*`, etc.

---

## 🎨 Reemplazar los recursos placeholder

- **Arte:** sustituye los SVG de `assets/goods/` por tu arte final (mismo nombre de
  archivo). También puedes usar PNG actualizando las rutas en `data/Goods.gd`.
- **Sonido:** sustituye los WAV de `assets/audio/`. Puedes añadir música de fondo
  llamando `AudioManager.play_music("res://assets/audio/mi_musica.ogg")`.

Los WAV placeholder se generaron con el script `tools/gen_sfx.py` y los niveles
11–50 con `tools/gen_levels.py` (ambos incluidos como referencia; requieren solo
Python 3).

---

## 🧩 Notas de diseño

- La UI de las escenas se construye **por código** en `_ready()` a partir de un
  `.tscn` mínimo (raíz + script). Esto la hace robusta, versionable y fácil de
  revisar en *diffs*, sin depender del editor visual.
- El árbol se **pausa** durante los diálogos; los popups usan
  `PROCESS_MODE_ALWAYS` para seguir respondiendo.
- El código es tolerante a **assets faltantes**: si un SVG o WAV no está, el juego
  no se rompe (usa un respaldo de color o silencio).
