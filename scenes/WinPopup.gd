extends PopupBase
## WinPopup — diálogo de nivel superado. Muestra estrellas y monedas ganadas,
## y ofrece continuar al siguiente nivel, reintentar o volver al menú.

signal next_pressed
signal replay_pressed
signal menu_pressed

## Rellena el contenido del popup.
## @param stars        Estrellas obtenidas (0..3).
## @param coins_earned Monedas otorgadas por el nivel.
## @param has_next     Si existe un nivel siguiente al que avanzar.
func setup(stars: int, coins_earned: int, has_next: bool) -> void:
	var vb := make_panel("¡Nivel completado!")

	var filled := "⭐".repeat(clampi(stars, 0, 3))
	var empty := "☆".repeat(3 - clampi(stars, 0, 3))
	add_label(vb, filled + empty, 48)
	add_label(vb, "Monedas: +%d" % coins_earned, 30)

	if has_next:
		add_button(vb, "Siguiente ▶").pressed.connect(func() -> void: next_pressed.emit())
	add_button(vb, "Reintentar ⟳").pressed.connect(func() -> void: replay_pressed.emit())
	add_button(vb, "Menú 🏠").pressed.connect(func() -> void: menu_pressed.emit())
