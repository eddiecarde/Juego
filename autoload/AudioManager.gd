extends Node
## AudioManager (singleton autoload)
## Reproduce efectos de sonido (SFX) y música. Crea los buses "Music" y "SFX"
## en tiempo de ejecución para no depender de un default_bus_layout.tres.
##
## Es tolerante a assets faltantes: si un .wav/.ogg no existe, simplemente no
## suena (el juego no se rompe). Respeta el mute persistido en SaveManager.

## Número de voces SFX simultáneas (pool round-robin).
const SFX_VOICES := 6

## Pool de reproductores de efectos.
var _sfx_players: Array[AudioStreamPlayer] = []
## Reproductor de música de fondo.
var _music_player: AudioStreamPlayer
## Índice del próximo reproductor SFX a usar.
var _next_sfx := 0
## Streams de efectos cargados por nombre.
var _sfx: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_setup_players()
	_load_sfx()
	set_muted(bool(SaveManager.data.get("muted", false)))

## Crea los buses de audio si aún no existen.
func _setup_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

## Instancia el pool de reproductores.
func _setup_players() -> void:
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

## Precarga los efectos de sonido.
func _load_sfx() -> void:
	_sfx = {
		"tap": _try_load("res://assets/audio/tap.wav"),
		"match": _try_load("res://assets/audio/match.wav"),
		"win": _try_load("res://assets/audio/win.wav"),
		"lose": _try_load("res://assets/audio/lose.wav"),
		"coin": _try_load("res://assets/audio/coin.wav"),
	}

func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

## Reproduce un efecto por nombre ("tap", "match", "win", "lose", "coin").
func play_sfx(sfx_name: String) -> void:
	var stream: AudioStream = _sfx.get(sfx_name, null)
	if stream == null:
		return
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.play()

## Reproduce música de fondo en bucle.
func play_music(path: String) -> void:
	var stream := _try_load(path)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

## ¿Está silenciado el audio (bus Master)?
func is_muted() -> bool:
	return AudioServer.is_bus_mute(0)

## Silencia o reactiva todo el audio y persiste la preferencia.
func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted) # bus 0 = Master
	SaveManager.data["muted"] = muted
	SaveManager.save_game()

## Alterna el mute y devuelve el nuevo estado.
func toggle_mute() -> bool:
	set_muted(not is_muted())
	return is_muted()
