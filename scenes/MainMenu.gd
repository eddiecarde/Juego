extends Control
## MainMenu — pantalla de inicio. Punto de entrada del juego (main_scene).
## Ofrece jugar (selección de niveles), continuar en el último nivel
## desbloqueado, silenciar el audio y mostrar las monedas.

var _coins_label: Label
var _mute_btn: Button

func _ready() -> void:
	_build()
	GameManager.coins_changed.connect(_update_coins)
	_update_coins(GameManager.get_coins())

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("1f2a44")
	add_child(bg)

	# Monedas arriba a la derecha.
	_coins_label = Label.new()
	_coins_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coins_label.offset_left = -220
	_coins_label.offset_top = 16
	_coins_label.offset_right = -16
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coins_label.add_theme_font_size_override("font_size", 34)
	add_child(_coins_label)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	vb.custom_minimum_size = Vector2(460, 0)
	center.add_child(vb)

	var title := Label.new()
	title.text = "Goods Sort\nMaster"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vb.add_child(title)

	_big_button(vb, "▶  Jugar").pressed.connect(_on_play)
	_big_button(vb, "⟳  Continuar").pressed.connect(_on_continue)

	_mute_btn = _big_button(vb, "")
	_update_mute_text()
	_mute_btn.pressed.connect(_on_mute)

	# Botón discreto para reiniciar el progreso.
	var reset := Button.new()
	reset.text = "Borrar progreso"
	reset.flat = true
	reset.focus_mode = Control.FOCUS_NONE
	reset.pressed.connect(_on_reset)
	vb.add_child(reset)

func _big_button(vb: VBoxContainer, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 72)
	b.focus_mode = Control.FOCUS_NONE
	vb.add_child(b)
	return b

func _update_coins(total: int) -> void:
	if _coins_label != null:
		_coins_label.text = "🪙 %d" % total

func _on_play() -> void:
	GameManager.goto_level_select()

func _on_continue() -> void:
	GameManager.play_level(GameManager.highest_unlocked())

func _on_mute() -> void:
	AudioManager.toggle_mute()
	_update_mute_text()

func _update_mute_text() -> void:
	_mute_btn.text = "🔇  Sonido: OFF" if AudioManager.is_muted() else "🔊  Sonido: ON"

func _on_reset() -> void:
	SaveManager.reset_save()
	_update_coins(GameManager.get_coins())
	AnalyticsManager.log_event("progress_reset", {})
