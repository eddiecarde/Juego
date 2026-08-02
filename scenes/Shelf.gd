extends PanelContainer
class_name Shelf
## Shelf — un estante que contiene una fila de fichas (Good).
## Cada columna es una pila; solo la ficha frontal es seleccionable. El estante
## reenvía la selección hacia arriba mediante `good_selected`.

## Emitida al seleccionar una ficha. Incluye el índice del estante y la columna.
signal good_selected(shelf_index: int, column: int)

const GoodScene := preload("res://scenes/Good.tscn")

## Índice de este estante dentro del nivel.
var shelf_index: int = 0
## Referencias a las fichas por columna.
var _goods: Array[Good] = []

## Construye el estante a partir de sus columnas.
## @param index         Índice del estante.
## @param columns_data  Array de columnas; cada columna es un Array de ids.
func setup(index: int, columns_data: Array) -> void:
	shelf_index = index
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	for c in columns_data.size():
		var g := GoodScene.instantiate() as Good
		hbox.add_child(g)
		g.setup(c, columns_data[c])
		g.pressed_good.connect(_on_good_pressed)
		_goods.append(g)

func _on_good_pressed(column: int) -> void:
	good_selected.emit(shelf_index, column)

## Refresca la pila mostrada por una columna (tras retirar la ficha frontal).
func update_column(column: int, stack: Array) -> void:
	if column >= 0 and column < _goods.size():
		_goods[column].set_stack(stack)

## Devuelve la ficha de una columna (usado por el sistema de pistas).
func get_good(column: int) -> Good:
	return _goods[column] if column >= 0 and column < _goods.size() else null
