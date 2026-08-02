extends PanelContainer
class_name CollectionTray
## CollectionTray — la bandeja de recolección inferior.
## El jugador envía fichas aquí; cuando se juntan 3 iguales, se eliminan
## (emitiendo `matched`). Si la bandeja se llena sin poder agrupar, se pierde
## (emite `tray_full`). Las fichas iguales se agrupan visualmente.

## Emitida cuando se completa y elimina un trío del tipo `id`.
signal matched(id: String)
## Emitida cuando la bandeja se llena por completo (condición de derrota).
signal tray_full
## Emitida cuando cambia el número de fichas en la bandeja.
signal changed(count: int)

## Número de ranuras totales.
var slots: int = 7
## Fichas actualmente en la bandeja (ids).
var _items: Array[String] = []
## Vistas de cada ranura.
var _slot_views: Array[TextureRect] = []
## Contenedor de ranuras.
var _hbox: HBoxContainer

## Construye la bandeja con `slot_count` ranuras.
func setup(slot_count: int) -> void:
	slots = maxi(3, slot_count)
	_items.clear()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 6)
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_hbox)

	for i in slots:
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Marca visual de ranura vacía.
		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0, 0, 0, 0.18)
		slot.add_child(bg)
		bg.show_behind_parent = true
		_hbox.add_child(slot)
		_slot_views.append(slot)
	_refresh()

## Añade una ficha a la bandeja, resuelve tríos y comprueba la derrota.
func add_good(id: String) -> void:
	_items.append(id)
	_items.sort() # agrupa iguales de forma contigua
	_resolve_matches()
	_refresh()
	changed.emit(_items.size())
	if _items.size() >= slots:
		tray_full.emit()

## Elimina todos los tríos completos que haya en la bandeja.
func _resolve_matches() -> void:
	while true:
		var counts := {}
		for it in _items:
			counts[it] = int(counts.get(it, 0)) + 1
		var found := ""
		for k in counts:
			if int(counts[k]) >= 3:
				found = String(k)
				break
		if found == "":
			break
		# Retira exactamente 3 fichas del tipo encontrado.
		var removed := 0
		var kept: Array[String] = []
		for it in _items:
			if it == found and removed < 3:
				removed += 1
			else:
				kept.append(it)
		_items = kept
		AudioManager.play_sfx("match")
		matched.emit(found)

## Redibuja las ranuras según el contenido actual.
func _refresh() -> void:
	for i in _slot_views.size():
		var view := _slot_views[i]
		if i < _items.size():
			view.texture = Goods.texture(_items[i])
			view.modulate = Color.WHITE
		else:
			view.texture = null

## Número de fichas actualmente en la bandeja.
func count() -> int:
	return _items.size()

## Conteo de fichas por tipo actualmente en la bandeja (usado por las pistas).
func type_counts() -> Dictionary:
	var counts := {}
	for it in _items:
		counts[it] = int(counts.get(it, 0)) + 1
	return counts
