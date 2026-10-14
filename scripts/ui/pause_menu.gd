extends CanvasLayer

const FONT = preload("res://assets/fonts/Papernotes Sketch.ttf")
const MAP_SCENE := "res://scenes/map/LevelMap.tscn"

var overlay: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue funcionando con el juego en pausa

	# Botón de pausa (esquina superior izquierda, debajo de la barra)
	var btn = Button.new()
	btn.text = "II"
	btn.size = Vector2(44, 44)
	btn.position = Vector2(12, 92)
	btn.add_theme_stylebox_override("normal", make_style(Color("#C97B4A"), 22))
	btn.add_theme_stylebox_override("hover", make_style(Color("#E0965F"), 22))
	btn.add_theme_stylebox_override("pressed", make_style(Color("#A8623A"), 22))
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(open_menu)
	add_child(btn)

	build_overlay()


func build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)   # bloquea los clics al juego de abajo

	var screen = get_viewport().get_visible_rect().size
	var panel = Panel.new()
	panel.size = Vector2(260, 280)
	panel.position = (screen - panel.size) / 2.0
	var st = make_style(Color("#8B5A3C"), 28)
	st.set_border_width_all(4)
	st.border_color = Color("#F2B134")
	panel.add_theme_stylebox_override("panel", st)
	overlay.add_child(panel)

	var title = Label.new()
	title.text = "Pausa"
	title.size = Vector2(260, 50)
	title.position = Vector2(0, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#FFF3E0"))
	panel.add_child(title)

	add_menu_button(panel, "Continuar", 80, resume)
	add_menu_button(panel, "Reintentar", 140, restart)
	add_menu_button(panel, "Mapa", 200, go_to_map)


func add_menu_button(parent: Control, text: String, y: float, callback: Callable) -> void:
	var b = Button.new()
	b.text = text
	b.size = Vector2(200, 46)
	b.position = Vector2(30, y)
	b.add_theme_stylebox_override("normal", make_style(Color("#C97B4A"), 16))
	b.add_theme_stylebox_override("hover", make_style(Color("#E0965F"), 16))
	b.add_theme_stylebox_override("pressed", make_style(Color("#A8623A"), 16))
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.pressed.connect(callback)
	parent.add_child(b)


func open_menu() -> void:
	overlay.visible = true
	get_tree().paused = true


func resume() -> void:
	overlay.visible = false
	get_tree().paused = false


func restart() -> void:
	get_tree().paused = false   # importante: si no, la escena nueva queda en pausa
	get_tree().reload_current_scene()


func go_to_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAP_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	# Esc (o el botón atrás de Android) abre y cierra la pausa
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible:
			resume()
		else:
			open_menu()


func make_style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s
