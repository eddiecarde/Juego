extends PopupBase
## PausePopup — diálogo de pausa. Permite reanudar, silenciar el audio,
## reiniciar el nivel o volver al menú.

signal resume_pressed
signal restart_pressed
signal menu_pressed

var _mute_btn: Button

func setup() -> void:
	var vb := make_panel("Pausa")

	add_button(vb, "Reanudar ▶").pressed.connect(func() -> void: resume_pressed.emit())

	_mute_btn = add_button(vb, "")
	_update_mute_text()
	_mute_btn.pressed.connect(_on_mute)

	add_button(vb, "Reiniciar ⟳").pressed.connect(func() -> void: restart_pressed.emit())
	add_button(vb, "Menú 🏠").pressed.connect(func() -> void: menu_pressed.emit())

func _on_mute() -> void:
	AudioManager.toggle_mute()
	_update_mute_text()

func _update_mute_text() -> void:
	_mute_btn.text = "Sonido: OFF 🔇" if AudioManager.is_muted() else "Sonido: ON 🔊"
