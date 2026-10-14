extends Control

const FONT = preload("res://assets/fonts/Papernotes Sketch.ttf")
const MAP_SCENE := "res://scenes/map/LevelMap.tscn"
const PREVIEW_SIZE := Vector2(150, 175)

var screen: Vector2
var preview: TextureRect
var coins_label: Label
var list_box: VBoxContainer


func _ready() -> void:
	screen = get_viewport_rect().size
	size = screen

	var bg = ColorRect.new()
	bg.color = Color("#FFF3E0")
	bg.size = screen
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	build_title()

	coins_label = Label.new()
	coins_label.size = Vector2(screen.x - 40, 30)
	coins_label.position = Vector2(20, 82)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_override("font", FONT)
	coins_label.add_theme_font_size_override("font_size", 18)
	coins_label.add_theme_color_override("font_color", Color("#8B5A3C"))
	add_child(coins_label)

	preview = TextureRect.new()
	preview.size = PREVIEW_SIZE
	preview.position = Vector2((screen.x - PREVIEW_SIZE.x) / 2.0, 112)
	preview.pivot_offset = Vector2(PREVIEW_SIZE.x / 2.0, PREVIEW_SIZE.y)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 300)
	scroll.size = Vector2(screen.x - 40, screen.y - 300 - 80)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)

	var back = Button.new()
	back.text = "Volver al mapa"
	back.size = Vector2(200, 50)
	back.position = Vector2((screen.x - 200) / 2.0, screen.y - 66)
	style_button(back, Color("#C97B4A"), 20, 20)
	back.pressed.connect(func(): get_tree().change_scene_to_file(MAP_SCENE))
	add_child(back)

	refresh()


func build_title() -> void:
	var panel = Panel.new()
	panel.size = Vector2(screen.x - 40, 56)
	panel.position = Vector2(20, 18)
	var st = make_style(Color("#8B5A3C"), 24)
	st.set_border_width_all(4)
	st.border_color = Color("#F2B134")
	panel.add_theme_stylebox_override("panel", st)
	add_child(panel)

	var lbl = Label.new()
	lbl.text = "Clóset de Rayitas"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", FONT)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color("#FFF3E0"))
	panel.add_child(lbl)


func refresh() -> void:
	coins_label.text = "Canelas: %d" % GameState.canelas

	for c in list_box.get_children():
		c.queue_free()
	for o in GameState.OUTFITS:
		list_box.add_child(build_row(o))

	show_outfit(GameState.get_outfit(GameState.equipped))


func build_row(o: Dictionary) -> Panel:
	var w = screen.x - 48
	var row = Panel.new()
	row.custom_minimum_size = Vector2(w, 56)
	var st = make_style(Color("#F6E3C8"), 16)
	st.set_border_width_all(3)
	st.border_color = Color("#E0A458")
	row.add_theme_stylebox_override("panel", st)

	var name_lbl = Label.new()
	name_lbl.text = o.name
	name_lbl.position = Vector2(14, 0)
	name_lbl.size = Vector2(w - 160, 56)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", FONT)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color("#5C3A21"))
	row.add_child(name_lbl)

	var btn = Button.new()
	btn.size = Vector2(124, 40)
	btn.position = Vector2(w - 136, 8)

	var owned = GameState.owned.has(o.id)
	if GameState.equipped == o.id:
		btn.text = "Puesto"
		btn.disabled = true
		style_button(btn, Color("#B9A38F"), 16, 16)
	elif owned:
		btn.text = "Ponerse"
		style_button(btn, Color("#C97B4A"), 16, 16)
		btn.pressed.connect(func():
			GameState.equip(o.id)
			refresh()
			bounce())
	else:
		btn.text = "Comprar %d" % o.price
		var afford = GameState.canelas >= o.price
		btn.disabled = not afford
		style_button(btn, Color("#F2B134") if afford else Color("#B9A38F"), 16, 16)
		btn.pressed.connect(func():
			if GameState.buy(o.id):
				GameState.equip(o.id)
				refresh()
				bounce())
	row.add_child(btn)
	return row


func show_outfit(o: Dictionary) -> void:
	var path = o.path
	var tint = Color.WHITE
	if not ResourceLoader.exists(path):
		# Aún no hay imagen de esta prenda: usa la base con un tinte
		path = GameState.OUTFITS[0].path
		tint = o.tint
	preview.texture = trimmed(load(path))
	preview.modulate = tint


func trimmed(full: Texture2D) -> Texture2D:
	var img = full.get_image()
	if img == null:
		return full
	var tex = AtlasTexture.new()
	tex.atlas = full
	tex.region = Rect2(img.get_used_rect())
	return tex


func bounce() -> void:
	var t = create_tween()
	t.tween_property(preview, "scale", Vector2(1.12, 0.9), 0.08)
	t.tween_property(preview, "scale", Vector2(0.96, 1.06), 0.1)
	t.tween_property(preview, "scale", Vector2.ONE, 0.1)


func make_style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s


func style_button(btn: Button, color: Color, radius: int, font_size: int) -> void:
	btn.add_theme_stylebox_override("normal", make_style(color, radius))
	btn.add_theme_stylebox_override("hover", make_style(color.lightened(0.12), radius))
	btn.add_theme_stylebox_override("pressed", make_style(color.darkened(0.15), radius))
	btn.add_theme_stylebox_override("disabled", make_style(color, radius))
	btn.add_theme_font_override("font", FONT)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color.WHITE)
