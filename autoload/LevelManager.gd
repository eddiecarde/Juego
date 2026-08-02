extends Node
## LevelManager (singleton autoload)
## Descubre y carga los niveles desde res://levels/*.json. Es la pieza que
## hace el juego DATA-DRIVEN: para añadir un nivel basta con dejar un archivo
## JSON nuevo en esa carpeta; no se toca ni una línea de código.
##
## Además genera el tablero de cada nivel de forma SOLVABLE, garantizando que
## el número de fichas de cada tipo sea múltiplo de 3 (siempre agrupables).

## Carpeta donde viven las definiciones de nivel.
const LEVELS_DIR := "res://levels"

## Lista de niveles cargados y ordenados.
var _levels: Array[LevelData] = []

func _ready() -> void:
	scan()

## Re-escanea la carpeta de niveles. Útil también para herramientas de edición.
func scan() -> void:
	_levels.clear()
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("LevelManager: no existe la carpeta %s" % LEVELS_DIR)
		return

	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		# Importante: ignorar remaps de exportación (.json.remap) y subcarpetas.
		if not dir.current_is_dir() and fname.get_extension().to_lower() == "json":
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()

	files.sort() # orden estable por nombre (level_001, level_002, ...)
	for f in files:
		var level := _load_file(LEVELS_DIR.path_join(f))
		if level != null:
			_levels.append(level)

	# Orden final por el 'id' declarado dentro del JSON.
	_levels.sort_custom(func(a: LevelData, b: LevelData) -> bool: return a.id < b.id)
	AnalyticsManager.log_event("levels_loaded", {"count": _levels.size()})

func _load_file(path: String) -> LevelData:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("LevelManager: JSON inválido en %s" % path)
		return null
	return LevelData.from_dict(parsed)

## Número de niveles disponibles.
func level_count() -> int:
	return _levels.size()

## Devuelve el nivel por índice (o null si está fuera de rango).
func get_level(index: int) -> LevelData:
	if index < 0 or index >= _levels.size():
		return null
	return _levels[index]

## Genera el reparto de fichas del nivel.
##
## Devuelve una matriz board[shelf][column] = Array de ids (una pila/capa;
## el ÚLTIMO elemento es el que está "al frente" y es seleccionable).
##
## Solvencia: se crean effective_triples() tríos (cada trío es de un solo
## tipo), por lo que cada tipo aparece un número múltiplo de 3 → siempre se
## pueden agrupar de 3 en 3.
func build_board(level: LevelData) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# 1) Bolsa de fichas: reparte los tríos entre los tipos disponibles.
	var pool: Array[String] = []
	var types := level.goods
	var n_triples := level.effective_triples()
	for i in n_triples:
		var t := types[i % types.size()]
		pool.append(t)
		pool.append(t)
		pool.append(t)

	# 2) Mezcla Fisher–Yates.
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := pool[i]
		pool[i] = pool[j]
		pool[j] = tmp

	# 3) Estructura vacía: shelves x columns, cada celda es una pila de capas.
	var board: Array = []
	for s in level.shelves:
		var shelf: Array = []
		for c in level.columns:
			shelf.append([])
		board.append(shelf)

	# 4) Rellena capa por capa para que la profundidad quede uniforme.
	var idx := 0
	for _layer in level.depth:
		for s in level.shelves:
			for c in level.columns:
				if idx >= pool.size():
					return board
				(board[s][c] as Array).append(pool[idx])
				idx += 1
	return board
