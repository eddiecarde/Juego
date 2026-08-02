extends PopupBase
## LosePopup — diálogo de derrota (la bandeja se llenó o se acabó el tiempo).
## Ofrece reintentar, reintentar gratis viendo un anuncio recompensado
## (vía AdsManager) o volver al menú.

signal retry_pressed
signal watch_ad_pressed
signal menu_pressed

func setup() -> void:
	var vb := make_panel("¡Se acabó!")
	add_label(vb, "La bandeja se llenó.\n¿Quieres intentarlo de nuevo?", 28)

	add_button(vb, "Reintentar ⟳").pressed.connect(func() -> void: retry_pressed.emit())
	add_button(vb, "Reintento gratis 🎬").pressed.connect(func() -> void: watch_ad_pressed.emit())
	add_button(vb, "Menú 🏠").pressed.connect(func() -> void: menu_pressed.emit())
