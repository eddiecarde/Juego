extends Node
## AnalyticsManager (singleton autoload)
## Capa de abstracción para analítica. Por defecto es un STUB que solo imprime
## los eventos en consola, para que el juego funcione sin dependencias nativas.
##
## ─── Cómo conectar Firebase Analytics real ───────────────────────────────
## 1. Instala un plugin de Android para Firebase, por ejemplo:
##      https://github.com/godotengine/godot-google-play-services
##    o el plugin comunitario "godot-firebase".
## 2. Coloca google-services.json en la carpeta android/ del build de Gradle.
## 3. En _ready(), obtén el singleton nativo:
##      if Engine.has_singleton("FirebaseAnalytics"):
##          _backend = Engine.get_singleton("FirebaseAnalytics")
## 4. En log_event(), reenvía al backend:
##      _backend.logEvent(name, params)
## El resto del juego NO cambia: sigue llamando AnalyticsManager.log_event().

## Backend nativo real (null mientras se use el stub).
var _backend: Object = null
## Activa/desactiva el volcado por consola del stub.
@export var debug_print := true

func _ready() -> void:
	# TODO(Firebase): descomenta al integrar el plugin nativo.
	# if Engine.has_singleton("FirebaseAnalytics"):
	#     _backend = Engine.get_singleton("FirebaseAnalytics")
	log_event("app_open", {})

## Registra un evento de analítica.
## @param name  Nombre del evento (snake_case, estilo Firebase).
## @param params Parámetros adicionales.
func log_event(name: String, params: Dictionary = {}) -> void:
	if _backend != null and _backend.has_method("logEvent"):
		_backend.logEvent(name, params)
	elif debug_print:
		print("[Analytics] %s %s" % [name, JSON.stringify(params)])

## Fija una propiedad de usuario (p. ej. nivel máximo alcanzado).
func set_user_property(key: String, value: String) -> void:
	if _backend != null and _backend.has_method("setUserProperty"):
		_backend.setUserProperty(key, value)
	elif debug_print:
		print("[Analytics] user_property %s=%s" % [key, value])
