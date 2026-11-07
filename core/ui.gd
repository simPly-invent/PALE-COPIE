## Style visuel partagé : police, cadres blancs façon Undertale.
class_name UI
extends RefCounted

static var _font: Font
static var _theme: Theme

static func font() -> Font:
	if _font:
		return _font
	if ResourceLoader.exists("res://assets/fonts/main.ttf"):
		var f: FontFile = load("res://assets/fonts/main.ttf")
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font = f
	else:
		var sf = SystemFont.new()
		sf.font_names = PackedStringArray(["Courier New", "Courier", "Menlo", "DejaVu Sans Mono", "monospace"])
		sf.font_weight = 700
		sf.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sf.hinting = TextServer.HINTING_NONE
		sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font = sf
	return _font

static func theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font()
	_theme.default_font_size = 20
	return _theme

static func label(text := "", size := 20, color := Color.WHITE) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func frame_style(border := 3, bg := Color.BLACK, fg := Color.WHITE) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = fg
	sb.set_border_width_all(border)
	sb.anti_aliasing = false
	return sb

static func panel(rect: Rect2, border := 3) -> Panel:
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", frame_style(border))
	return p

static func sprite_rect(tex_name: String, scale := 1.0) -> TextureRect:
	var t = TextureRect.new()
	t.texture = Assets.tex(tex_name)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if t.texture:
		t.size = t.texture.get_size() * scale
		t.custom_minimum_size = t.size
	return t
