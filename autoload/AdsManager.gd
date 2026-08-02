extends Node
## AdsManager (singleton autoload)
## Capa de abstracción para anuncios (AdMob). Por defecto es un STUB: no
## muestra anuncios reales, pero cumple el mismo contrato (señales + métodos)
## para que el juego funcione y esté listo para el plugin nativo.
##
## ─── Cómo conectar AdMob real ────────────────────────────────────────────
## 1. Instala el plugin oficial "Godot AdMob" (Poing Studios) para Android:
##      https://github.com/Poing-Studios/godot-admob-android
## 2. Añade tu App ID de AdMob en la configuración del plugin y tus Ad Unit IDs
##    en las constantes de abajo.
## 3. En _ready(), obtén el singleton:
##      if Engine.has_singleton("AdMob"):
##          _admob = Engine.get_singleton("AdMob")
##          _admob.initialize()
##          _connect_admob_signals()
## 4. Sustituye los cuerpos "stub" de show_* por las llamadas reales del plugin.
## El gameplay NO cambia: sigue llamando show_interstitial()/show_rewarded().

## Se emite cuando un anuncio recompensado se completó con éxito.
signal rewarded_granted
## Se emite cuando un anuncio recompensado se cerró sin recompensa.
signal rewarded_dismissed
## Se emite cuando un intersticial se cerró.
signal interstitial_closed

# --- Ad Unit IDs (usar los de PRUEBA de Google mientras desarrollas) ---
const AD_UNIT_BANNER := "ca-app-pub-3940256099942544/6300978111"
const AD_UNIT_INTERSTITIAL := "ca-app-pub-3940256099942544/1033173712"
const AD_UNIT_REWARDED := "ca-app-pub-3940256099942544/5224354917"

## true cuando corremos con el stub (sin plugin nativo).
var is_stub := true
## Referencia al singleton nativo de AdMob (null en modo stub).
var _admob: Object = null
## Callback pendiente del anuncio recompensado en curso.
var _pending_reward_cb: Callable = Callable()

func _ready() -> void:
	# TODO(AdMob): descomenta al integrar el plugin nativo.
	# if Engine.has_singleton("AdMob"):
	#     _admob = Engine.get_singleton("AdMob")
	#     is_stub = false
	#     _admob.initialize()
	if is_stub:
		print("[Ads] AdsManager en modo STUB (sin anuncios reales).")

## Muestra/oculta el banner inferior.
func show_banner() -> void:
	if is_stub:
		return
	# _admob.load_banner(AD_UNIT_BANNER); _admob.show_banner()

func hide_banner() -> void:
	if is_stub:
		return
	# _admob.hide_banner()

## Muestra un intersticial (p. ej. al perder o cada N niveles).
## En stub emite el cierre de inmediato para no bloquear el flujo.
func show_interstitial() -> void:
	AnalyticsManager.log_event("ad_interstitial_request", {"stub": is_stub})
	if is_stub:
		interstitial_closed.emit()
		return
	# _admob.load_interstitial(AD_UNIT_INTERSTITIAL); _admob.show_interstitial()

## Muestra un anuncio recompensado. Si el usuario lo completa, se ejecuta
## `on_reward` y se emite `rewarded_granted`.
## En stub concede la recompensa inmediatamente (útil para probar el flujo).
func show_rewarded(on_reward: Callable = Callable()) -> void:
	AnalyticsManager.log_event("ad_rewarded_request", {"stub": is_stub})
	_pending_reward_cb = on_reward
	if is_stub:
		_grant_reward()
		return
	# _admob.load_rewarded(AD_UNIT_REWARDED); _admob.show_rewarded()

## Uso interno / callback del plugin: concede la recompensa.
func _grant_reward() -> void:
	if _pending_reward_cb.is_valid():
		_pending_reward_cb.call()
	_pending_reward_cb = Callable()
	rewarded_granted.emit()
	AnalyticsManager.log_event("ad_rewarded_granted", {"stub": is_stub})
