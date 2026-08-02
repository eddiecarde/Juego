extends Control
## LevelSelect — cuadrícula de niveles generada dinámicamente desde
## LevelManager. Los niveles bloqueados aparecen deshabilitados; los superados
## muestran sus estrellas. Es 100% data-driven: refleja los JSON existentes.

func _ready() -> void:
	_build()

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("1f2a44")
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	margin.add_child(vb)

	# Cabecera con botón de volver.
	var header := HBoxContainer.new()
	var back := Button.new()
	back.text = "‹ Menú"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: GameManager.goto_main_menu())
	header.add_child(back)
	var title := Label.new()
	title.text = "   Niveles"
	title.add_theme_font_size_override("font_size", 40)
	header.add_child(title)
	vb.add_child(header)

	# Cuadrícula desplazable de niveles.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var count := LevelManager.level_count()
	if count == 0:
		var empty := Label.new()
		empty.text = "No hay niveles en res://levels/"
		grid.add_child(empty)
		return

	for i in count:
		grid.add_child(_make_level_button(i))

## Crea el botón de un nivel con su número, estado (bloqueado) y estrellas.
func _make_level_button(index: int) -> Control:
	var unlocked := GameManager.is_level_unlocked(index)
	var stars := GameManager.get_stars(index)

	var b := Button.new()
	b.custom_minimum_size = Vector2(96, 96)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not unlocked
	if unlocked:
		var star_str := "★".repeat(stars) if stars > 0 else ""
		b.text = "%d\n%s" % [index + 1, star_str]
		b.pressed.connect(func() -> void: GameManager.play_level(index))
	else:
		b.text = "🔒"
	return b
