extends Node
## SaveManager (singleton autoload)
## Guardado automático de la partida en user://savegame.json.
##
## Mantiene un diccionario `data` en memoria con monedas, progreso, estrellas
## y ajustes. Persiste ante cada cambio importante y también cuando la app
## pasa a segundo plano o se cierra (crucial en móvil, donde el sistema puede
## matar el proceso en cualquier momento).

## Ruta del archivo de guardado (user:// es privado y persistente en Android).
const SAVE_PATH := "user://savegame.json"

## Estructura por defecto de una partida nueva.
const DEFAULT_DATA := {
	"coins": 100,           # monedas iniciales de regalo
	"highest_unlocked": 0,  # índice del último nivel desbloqueado
	"stars": {},            # { "0": 3, "1": 2, ... } estrellas por nivel
	"muted": false,         # audio silenciado
	"version": 1,           # versión del esquema de guardado
}

## Estado actual de la partida en memoria.
var data: Dictionary = {}

func _ready() -> void:
	# El guardado debe funcionar incluso con el juego pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()

## Carga la partida desde disco (o inicializa una nueva si no existe).
func load_game() -> void:
	data = DEFAULT_DATA.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("SaveManager: no se pudo leer %s" % SAVE_PATH)
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		# Fusiona sobre los valores por defecto para tolerar saves antiguos
		# a los que les falten claves nuevas.
		for k in parsed.keys():
			data[k] = parsed[k]

## Escribe la partida en disco (JSON legible).
func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: no se pudo escribir %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

## Reinicia el progreso (para un botón "Borrar datos" en ajustes).
func reset_save() -> void:
	data = DEFAULT_DATA.duplicate(true)
	save_game()

func _notification(what: int) -> void:
	# Guarda cuando la app se minimiza, pierde el foco o se cierra.
	match what:
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_GO_BACK_REQUEST, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
