extends Control
class_name PopupBase
## PopupBase — base reutilizable para diálogos superpuestos (victoria, derrota,
## pausa). Aporta el fondo oscurecido, un panel centrado y helpers para crear
## título y botones. Los popups concretos heredan de aquí para no repetir UI.
##
## Funciona con el árbol pausado: process_mode = ALWAYS.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_dim()

## Fondo semitransparente que bloquea el toque sobre el juego.
func _build_dim() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	add_child(dim)

## Crea un panel centrado con un título y devuelve el VBox para el contenido.
func make_panel(title: String) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	margin.add_child(vb)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 46)
	vb.add_child(t)
	return vb

## Crea un botón grande (cómodo para el toque) dentro del VBox dado.
func add_button(vb: VBoxContainer, text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 66)
	b.focus_mode = Control.FOCUS_NONE
	vb.add_child(b)
	return b

## Añade una etiqueta centrada de apoyo.
func add_label(vb: VBoxContainer, text: String, font_size := 30) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	vb.add_child(l)
	return l
