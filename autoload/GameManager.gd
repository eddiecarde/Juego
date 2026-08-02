extends Node
## GameManager (singleton autoload)
## Orquesta el flujo global del juego: navegación entre escenas, nivel actual,
## economía de monedas y progreso. Es la fuente de verdad EN MEMORIA; la
## persistencia se delega en SaveManager y la analítica en AnalyticsManager.

## Se emite cuando cambia el total de monedas (para refrescar HUD/menús).
signal coins_changed(total: int)
## Se emite cuando se desbloquea un nivel nuevo.
signal level_unlocked(level_index: int)

const SCENE_MAIN_MENU := "res://scenes/MainMenu.tscn"
const SCENE_LEVEL_SELECT := "res://scenes/LevelSelect.tscn"
const SCENE_GAME := "res://scenes/Game.tscn"

## Índice (base 0) del nivel que se está por jugar / jugando.
var current_level_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# ---------------------------------------------------------------------------
# Navegación entre escenas
# ---------------------------------------------------------------------------

## Cambia de escena de forma segura (deferida para evitar problemas si se
## invoca durante una señal de la escena saliente).
func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)

func goto_main_menu() -> void:
	goto_scene(SCENE_MAIN_MENU)

func goto_level_select() -> void:
	goto_scene(SCENE_LEVEL_SELECT)

## Inicia un nivel por índice y navega a la escena de juego.
func play_level(level_index: int) -> void:
	current_level_index = clampi(level_index, 0, maxi(0, LevelManager.level_count() - 1))
	AnalyticsManager.log_event("level_start", {"level": current_level_index + 1})
	goto_scene(SCENE_GAME)

## Reinicia el nivel actual (reconstruye el tablero).
func restart_level() -> void:
	AnalyticsManager.log_event("level_retry", {"level": current_level_index + 1})
	get_tree().reload_current_scene()

## Avanza al siguiente nivel si existe; si no, vuelve a la selección.
func next_level() -> void:
	if current_level_index + 1 < LevelManager.level_count():
		play_level(current_level_index + 1)
	else:
		goto_level_select()

# ---------------------------------------------------------------------------
# Economía de monedas
# ---------------------------------------------------------------------------

func get_coins() -> int:
	return int(SaveManager.data.get("coins", 0))

## Suma (o resta, si amount < 0) monedas, persiste y notifica.
func add_coins(amount: int) -> void:
	if amount == 0:
		return
	SaveManager.data["coins"] = maxi(0, get_coins() + amount)
	SaveManager.save_game()
	coins_changed.emit(get_coins())
	if amount > 0:
		AudioManager.play_sfx("coin")

## Intenta gastar monedas. Devuelve true si había saldo suficiente.
func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_coins() < amount:
		return false
	add_coins(-amount)
	return true

# ---------------------------------------------------------------------------
# Progreso y estrellas
# ---------------------------------------------------------------------------

func highest_unlocked() -> int:
	return int(SaveManager.data.get("highest_unlocked", 0))

func is_level_unlocked(level_index: int) -> bool:
	return level_index <= highest_unlocked()

## Estrellas obtenidas en un nivel (0 si no se ha superado).
func get_stars(level_index: int) -> int:
	var stars: Dictionary = SaveManager.data.get("stars", {})
	return int(stars.get(str(level_index), 0))

## Marca un nivel como superado: guarda estrellas (si mejoran) y desbloquea
## el siguiente. Otorga las monedas de recompensa.
func complete_level(level_index: int, stars: int, reward_coins: int) -> void:
	var stars_dict: Dictionary = SaveManager.data.get("stars", {})
	var key := str(level_index)
	if stars > int(stars_dict.get(key, 0)):
		stars_dict[key] = stars
	SaveManager.data["stars"] = stars_dict

	var next_index := level_index + 1
	if next_index > highest_unlocked() and next_index < LevelManager.level_count():
		SaveManager.data["highest_unlocked"] = next_index
		level_unlocked.emit(next_index)

	SaveManager.save_game()
	if reward_coins > 0:
		add_coins(reward_coins)
	AnalyticsManager.log_event("level_complete", {
		"level": level_index + 1, "stars": stars, "reward": reward_coins,
	})
