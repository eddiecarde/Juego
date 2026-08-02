extends Control
class_name Good
## Good — una mercancía seleccionable dentro de un estante.
## Muestra la ficha que está "al frente" de su pila (el último elemento) y,
## si hay más objetos ocultos debajo, un contador de profundidad. Al tocarlo
## emite `pressed_good` con su columna. Es tolerante a assets faltantes:
## si el SVG no existe, dibuja un respaldo de color con la inicial del tipo.

## Emitida al tocar una ficha no vacía. `column` es la columna del estante.
signal pressed_good(column: int)

## Columna que ocupa esta ficha dentro de su estante.
var column: int = 0
## Pila de ids (el último es la ficha frontal/visible y seleccionable).
var _stack: Array = []
var _built := false

var _bg: ColorRect
var _tex: TextureRect
var _label: Label
var _badge: Label
var _btn: Button

func _ready() -> void:
	_ensure_built()

## Construye los nodos hijos una sola vez (puede llamarse desde setup()).
func _ensure_built() -> void:
	if _built:
		return
	_built = true
	custom_minimum_size = Vector2(88, 88)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = false

	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(1, 1, 1, 0.06)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_tex = TextureRect.new()
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex)

	# Texto de respaldo (solo visible si no hay textura para el tipo).
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# Contador de profundidad (esquina superior derecha).
	_badge = Label.new()
	_badge.anchor_left = 1.0
	_badge.anchor_right = 1.0
	_badge.offset_left = -36.0
	_badge.offset_top = 2.0
	_badge.offset_right = -2.0
	_badge.offset_bottom = 30.0
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.add_theme_font_size_override("font_size", 20)
	_badge.add_theme_color_override("font_color", Color.WHITE)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_badge)

	# Botón transparente por encima para capturar el toque.
	_btn = Button.new()
	_btn.flat = true
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	_btn.pressed.connect(_on_pressed)
	add_child(_btn)

## Inicializa columna y contenido. Debe llamarse tras add_child(this).
func setup(col: int, stack: Array) -> void:
	_ensure_built()
	column = col
	set_stack(stack)

## Actualiza la pila mostrada (p. ej. al retirar la ficha frontal).
func set_stack(stack: Array) -> void:
	_ensure_built()
	_stack = stack.duplicate()
	var empty := _stack.is_empty()
	_btn.disabled = empty
	_bg.visible = not empty
	_tex.visible = not empty
	if empty:
		_label.text = ""
		_badge.text = ""
		return

	var front := String(_stack.back())
	var tex := Goods.texture(front)
	if tex != null:
		_tex.texture = tex
		_tex.visible = true
		_label.text = ""
	else:
		# Respaldo visual si falta el SVG.
		_tex.visible = false
		_bg.color = Goods.color(front)
		_label.text = Goods.label(front).substr(0, 1)
	# Contador de objetos ocultos debajo del frontal.
	_badge.text = ("x%d" % _stack.size()) if _stack.size() > 1 else ""

## ¿Hay una ficha seleccionable al frente?
func has_front() -> bool:
	return not _stack.is_empty()

## Id del tipo frontal (o cadena vacía si está vacía).
func front_id() -> String:
	return String(_stack.back()) if not _stack.is_empty() else ""

func _on_pressed() -> void:
	if _stack.is_empty():
		return
	_bounce()
	pressed_good.emit(column)

## Pequeña animación de rebote al seleccionar.
func _bounce() -> void:
	pivot_offset = size * 0.5
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.86, 0.86), 0.06)
	t.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Resalta la ficha (usado por el sistema de pistas).
func play_hint() -> void:
	pivot_offset = size * 0.5
	var t := create_tween()
	t.set_loops(3)
	t.tween_property(self, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
