extends Control
## Game — orquestador de la partida. Construye el tablero a partir del LevelData
## activo, conecta estantes y bandeja, y gestiona todo el bucle de juego:
## selección de fichas, coincidencias, temporizador opcional, pistas, pausa,
## victoria y derrota. No conoce los detalles de dibujo de los componentes;
## se comunica con ellos por señales.

const HUDScene := preload("res://scenes/HUD.tscn")
const ShelfScene := preload("res://scenes/Shelf.tscn")
const TrayScene := preload("res://scenes/CollectionTray.tscn")
const WinScene := preload("res://scenes/WinPopup.tscn")
const LoseScene := preload("res://scenes/LosePopup.tscn")
const PauseScene := preload("res://scenes/PausePopup.tscn")

var level: LevelData
## board[shelf][column] = Array de ids (la última es la ficha frontal).
var board: Array = []

var _hud: HUD
var _tray: CollectionTray
var _shelves: Array[Shelf] = []

var _remaining: int = 0          # fichas que faltan por agrupar
var _time_left: float = 0.0
var _timer_running: bool = false
var _ended: bool = false         # evita disparar win/lose dos veces
var _current_popup: Control = null

func _ready() -> void:
	level = LevelManager.get_level(GameManager.current_level_index)
	if level == null:
		push_warning("Game: no hay nivel en el índice %d" % GameManager.current_level_index)
		GameManager.goto_main_menu()
		return

	board = LevelManager.build_board(level)
	_remaining = _count_items()
	_build_ui()

	if level.has_timer():
		_time_left = level.time_limit
		_timer_running = true
		_hud.set_timer_visible(true)
		_hud.set_time(_time_left)
	else:
		_hud.set_timer_visible(false)

	AdsManager.show_banner()

func _process(delta: float) -> void:
	if not _timer_running:
		return
	_time_left -= delta
	_hud.set_time(_time_left)
	if _time_left <= 0.0:
		_time_left = 0.0
		_lose()

# ---------------------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("2b3a55")
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	# HUD superior.
	_hud = HUDScene.instantiate() as HUD
	vb.add_child(_hud)
	_hud.set_hint_cost(level.hint_cost)
	_hud.set_remaining(_remaining)
	_hud.hint_pressed.connect(_on_hint)
	_hud.pause_pressed.connect(_pause)

	# Área central con los estantes.
	var shelves_box := VBoxContainer.new()
	shelves_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelves_box.alignment = BoxContainer.ALIGNMENT_CENTER
	shelves_box.add_theme_constant_override("separation", 12)
	vb.add_child(shelves_box)

	for s in board.size():
		var shelf := ShelfScene.instantiate() as Shelf
		shelves_box.add_child(shelf)
		shelf.setup(s, board[s])
		shelf.good_selected.connect(_on_good_selected)
		_shelves.append(shelf)

	# Bandeja inferior.
	_tray = TrayScene.instantiate() as CollectionTray
	vb.add_child(_tray)
	_tray.setup(level.tray_slots)
	_tray.matched.connect(_on_matched)
	_tray.tray_full.connect(_on_tray_full)

func _count_items() -> int:
	var n := 0
	for shelf in board:
		for col in shelf:
			n += (col as Array).size()
	return n

# ---------------------------------------------------------------------------
# Bucle de juego
# ---------------------------------------------------------------------------

## El jugador tocó la ficha frontal de un estante: pasa a la bandeja.
func _on_good_selected(shelf_index: int, column: int) -> void:
	if _ended:
		return
	var stack: Array = board[shelf_index][column]
	if stack.is_empty():
		return
	var id := String(stack.pop_back())
	AudioManager.play_sfx("tap")
	_shelves[shelf_index].update_column(column, stack)
	_tray.add_good(id)

## Se completó un trío en la bandeja.
func _on_matched(_id: String) -> void:
	_remaining -= 3
	_hud.set_remaining(maxi(0, _remaining))
	if _remaining <= 0:
		_win()

## La bandeja se llenó sin poder agrupar: derrota.
func _on_tray_full() -> void:
	_lose()

# ---------------------------------------------------------------------------
# Pistas
# ---------------------------------------------------------------------------

## Busca una ficha útil que resaltar y cobra el coste en monedas.
func _on_hint() -> void:
	if _ended:
		return
	var good := _find_hint()
	if good == null:
		_toast("No hay pistas disponibles")
		return
	if not GameManager.spend_coins(level.hint_cost):
		_toast("Monedas insuficientes")
		return
	good.play_hint()
	AnalyticsManager.log_event("hint_used", {"level": level.id})

## Elige la mejor ficha frontal para sugerir: prioriza completar tríos que ya
## están a medias en la bandeja; si no, el tipo con más fichas disponibles.
func _find_hint() -> Good:
	var tray_counts := _tray.type_counts()
	var fronts_by_id := {}  # id -> Array[Good]
	for shelf in _shelves:
		for c in level.columns:
			var g := shelf.get_good(c)
			if g != null and g.has_front():
				var id := g.front_id()
				if not fronts_by_id.has(id):
					fronts_by_id[id] = []
				fronts_by_id[id].append(g)

	# 1) Tipos que ya están en la bandeja (1 o 2): completarlos es lo más útil.
	var best: Good = null
	var best_score := -1
	for id in fronts_by_id.keys():
		var in_tray := int(tray_counts.get(id, 0))
		var available := (fronts_by_id[id] as Array).size()
		# Puntuación: prioriza los que ayudan a cerrar un trío pronto.
		var score := in_tray * 10 + available
		if score > best_score:
			best_score = score
			best = fronts_by_id[id][0]
	return best

# ---------------------------------------------------------------------------
# Pausa
# ---------------------------------------------------------------------------

func _pause() -> void:
	if _ended or _current_popup != null:
		return
	get_tree().paused = true
	var p := PauseScene.instantiate() as PausePopup
	_current_popup = p
	add_child(p)
	p.setup()
	p.resume_pressed.connect(_resume)
	p.restart_pressed.connect(_action_restart)
	p.menu_pressed.connect(_action_menu)

func _resume() -> void:
	_clear_popup()
	get_tree().paused = false

# Acciones compartidas por los popups (evitan lambdas multilínea frágiles).
func _action_restart() -> void:
	get_tree().paused = false
	GameManager.restart_level()

func _action_menu() -> void:
	get_tree().paused = false
	GameManager.goto_main_menu()

func _action_next() -> void:
	get_tree().paused = false
	GameManager.next_level()

func _action_watch_ad() -> void:
	AdsManager.show_rewarded(_action_restart)

# ---------------------------------------------------------------------------
# Fin de partida
# ---------------------------------------------------------------------------

func _win() -> void:
	if _ended:
		return
	_ended = true
	_timer_running = false
	AudioManager.play_sfx("win")
	var stars := _calc_stars()
	GameManager.complete_level(GameManager.current_level_index, stars, level.reward_coins)

	get_tree().paused = true
	var p := WinScene.instantiate() as WinPopup
	_current_popup = p
	add_child(p)
	var has_next := GameManager.current_level_index + 1 < LevelManager.level_count()
	p.setup(stars, level.reward_coins, has_next)
	p.next_pressed.connect(_action_next)
	p.replay_pressed.connect(_action_restart)
	p.menu_pressed.connect(_action_menu)

func _lose() -> void:
	if _ended:
		return
	_ended = true
	_timer_running = false
	AudioManager.play_sfx("lose")
	AnalyticsManager.log_event("level_fail", {"level": level.id})
	AdsManager.show_interstitial()  # stub: no bloquea el flujo

	get_tree().paused = true
	var p := LoseScene.instantiate() as LosePopup
	_current_popup = p
	add_child(p)
	p.setup()
	p.retry_pressed.connect(_action_restart)
	p.watch_ad_pressed.connect(_action_watch_ad)
	p.menu_pressed.connect(_action_menu)

## Calcula estrellas: 3 si no hay temporizador o sobra tiempo; menos si se
## apuró el reloj.
func _calc_stars() -> int:
	if not level.has_timer():
		return 3
	var ratio := _time_left / level.time_limit
	if ratio > 0.5:
		return 3
	elif ratio > 0.2:
		return 2
	return 1

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _clear_popup() -> void:
	if _current_popup != null:
		_current_popup.queue_free()
		_current_popup = null

## Muestra un mensaje efímero centrado en la parte superior.
func _toast(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = 90
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", Color("ffd166"))
	add_child(l)
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)
