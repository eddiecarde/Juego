extends Control
class_name HUD
## HUD — barra superior de la partida. Muestra monedas, temporizador (opcional),
## fichas restantes y botones de pista y pausa. No contiene lógica de juego:
## solo emite señales que el orquestador (Game) atiende.

## Emitida al pulsar el botón de pista.
signal hint_pressed
## Emitida al pulsar el botón de pausa.
signal pause_pressed

var _coins_label: Label
var _timer_label: Label
var _remaining_label: Label
var _hint_btn: Button
var _pause_btn: Button

func _ready() -> void:
	custom_minimum_size = Vector2(0, 64)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()
	# Mantener las monedas sincronizadas con la economía global.
	GameManager.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameManager.get_coins())

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	_coins_label = _make_label("🪙 0")
	hbox.add_child(_coins_label)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer1)

	_timer_label = _make_label("⏱ 0:00")
	_timer_label.visible = false
	hbox.add_child(_timer_label)

	_remaining_label = _make_label("📦 0")
	hbox.add_child(_remaining_label)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	_hint_btn = Button.new()
	_hint_btn.text = "💡"
	_hint_btn.focus_mode = Control.FOCUS_NONE
	_hint_btn.pressed.connect(func() -> void: hint_pressed.emit())
	hbox.add_child(_hint_btn)

	_pause_btn = Button.new()
	_pause_btn.text = "⏸"
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
	hbox.add_child(_pause_btn)

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _on_coins_changed(total: int) -> void:
	if _coins_label != null:
		_coins_label.text = "🪙 %d" % total

## Muestra u oculta el temporizador (temporizador opcional por nivel).
func set_timer_visible(v: bool) -> void:
	if _timer_label != null:
		_timer_label.visible = v

## Actualiza el temporizador con segundos restantes (formato m:ss).
func set_time(seconds: float) -> void:
	if _timer_label == null:
		return
	var s := maxi(0, int(ceil(seconds)))
	_timer_label.text = "⏱ %d:%02d" % [s / 60, s % 60]

## Actualiza el contador de fichas restantes.
func set_remaining(n: int) -> void:
	if _remaining_label != null:
		_remaining_label.text = "📦 %d" % n

## Refleja el coste de la pista en el botón.
func set_hint_cost(cost: int) -> void:
	if _hint_btn != null:
		_hint_btn.text = "💡 %d" % cost
