extends RefCounted
class_name LevelData
## LevelData
## Representa un nivel parseado desde un archivo JSON de res://levels/.
##
## Todos los campos tienen valores por defecto sensatos, de modo que un JSON
## mínimo (por ejemplo solo {"id": 1, "name": "Nivel 1"}) siga siendo jugable.
## Esto es clave para el requisito "agregar niveles sin modificar código":
## un diseñador solo edita números en un JSON.

## Identificador único y orden del nivel.
var id: int = 0
## Nombre visible del nivel.
var name: String = "Nivel"
## Tipos de mercancía que aparecen (ids de Goods.DEFS). Vacío = todos.
var goods: PackedStringArray = PackedStringArray()
## Número de tríos completos. total_items() = triples * 3 → siempre resoluble.
var triples: int = 6
## Cantidad de estantes (filas).
var shelves: int = 3
## Columnas por estante.
var columns: int = 4
## Capas apiladas por columna (profundidad). >1 oculta objetos = más difícil.
var depth: int = 1
## Ranuras de la bandeja de recolección. Si se llena sin match, se pierde.
var tray_slots: int = 7
## Límite de tiempo en segundos. 0 = sin temporizador (temporizador opcional).
var time_limit: float = 0.0
## Coste en monedas de usar una pista.
var hint_cost: int = 50
## Monedas otorgadas al completar el nivel.
var reward_coins: int = 100
## Nivel de dificultad (informativo / para analytics y estrellas).
var difficulty: int = 1

## Construye un LevelData a partir del diccionario parseado del JSON.
## Aplica valores por defecto y saneamiento para tolerar JSON incompletos.
static func from_dict(d: Dictionary) -> LevelData:
	var l := LevelData.new()
	l.id = int(d.get("id", 0))
	l.name = String(d.get("name", "Nivel %d" % l.id))

	# Tipos de mercancía: filtra los desconocidos; si queda vacío usa todos.
	var raw_goods = d.get("goods", [])
	var valid := PackedStringArray()
	if typeof(raw_goods) == TYPE_ARRAY:
		for item in raw_goods:
			var gid := String(item)
			if Goods.has_good(gid):
				valid.append(gid)
	l.goods = valid if not valid.is_empty() else Goods.default_ids()

	l.triples = maxi(1, int(d.get("triples", 6)))
	l.shelves = maxi(1, int(d.get("shelves", 3)))
	l.columns = maxi(1, int(d.get("columns", 4)))
	l.depth = maxi(1, int(d.get("depth", 1)))
	l.tray_slots = maxi(3, int(d.get("tray_slots", 7)))
	l.time_limit = maxf(0.0, float(d.get("time_limit", 0.0)))
	l.hint_cost = maxi(0, int(d.get("hint_cost", 50)))
	l.reward_coins = maxi(0, int(d.get("reward_coins", 100)))
	l.difficulty = maxi(1, int(d.get("difficulty", 1)))
	return l

## Capacidad física del tablero (celdas totales considerando profundidad).
func capacity() -> int:
	return shelves * columns * depth

## Número de tríos que caben realmente en el tablero (respeta la capacidad).
func effective_triples() -> int:
	return maxi(1, mini(triples, int(capacity() / 3.0)))

## Número total de fichas del nivel (siempre múltiplo de 3 → resoluble).
func total_items() -> int:
	return effective_triples() * 3

## ¿Este nivel usa temporizador?
func has_timer() -> bool:
	return time_limit > 0.0
