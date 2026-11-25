extends CanvasLayer

signal exit_requested
signal start_requested(rules: Expedition.Rules, map_size: Expedition.MapSize)
signal resume_requested
signal menu_requested
signal sensitivity_changed(value: float)
signal steps_changed(value: float)
signal volume_changed(value: float)
signal language_changed(locale: String)

const Expedition := preload("res://world/expedition.gd")
const HARD_OBJECTIVE := "Найди дверь с дневным светом. Тьма за спиной отнимает здоровье, если вернуться на свой след."
const PAPER := Color("#f0e3c9")
const SECONDARY := Color("#dcceb9")
const ACCENT := Color("#dba674")
const FOCUS := Color("#f2b981")
const OBJECTIVE := "Найди дверь с дневным светом."
const LANGUAGES := {
	"en": "English", "zh_Hans": "简体中文", "ru": "Русский", "es": "Español (España)",
	"pt_BR": "Português (Brasil)", "de": "Deutsch", "ja": "日本語", "fr": "Français",
	"pl": "Polski", "ko": "한국어",
}
const GLYPH_FALLBACK := preload("res://i18n/fonts/vaults-fallback.otf")
var _serif := SystemFont.new()
var _sans := SystemFont.new()
var _root := Control.new()
var _page := Control.new()
var _entrance := Control.new()
var _pause_menu := Control.new()
var _result_title: Label
var _retry_rules := Expedition.Rules.NORMAL
var _result := Control.new()
var _hud := Control.new()
var _title: Label
var _choices := VBoxContainer.new()
var _enter: Button
var _controls: Label
var _notice: Label
var _objective: Label
var _again: Button
var _place: Label
var _resume: Button
var _veil := ColorRect.new()
var _hint_tween: Tween
var _notice_tween: Tween
var _sensitivity_slider: HSlider
var _volume_slider: HSlider
var _steps_slider: HSlider
var _map_size := OptionButton.new()
var _health_row := VBoxContainer.new()
var _health := ProgressBar.new()
var _language_row := HBoxContainer.new()
var _language := OptionButton.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_serif.font_names = PackedStringArray(["Nimbus Roman", "Liberation Serif", "Georgia", "DejaVu Serif"])
	_sans.font_names = PackedStringArray(["Ubuntu", "Segoe UI", "DejaVu Sans"])
	_serif.fallbacks = [GLYPH_FALLBACK]
	_sans.fallbacks = [GLYPH_FALLBACK]
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := Shader.new()
	shade.code = """
		shader_type canvas_item;
		uniform float pause_factor = 0.0;
		void fragment() {
			float bottom = smoothstep(0.23, 1.0, UV.y);
			float left = 1.0 - smoothstep(0.0, 0.88, UV.x);
			float alpha = bottom * (0.36 + 0.50 * left);
			alpha = mix(alpha, 0.27 + left * 0.64, pause_factor);
			COLOR = vec4(0.041, 0.043, 0.039, alpha);
		}
	"""
	var material := ShaderMaterial.new()
	material.shader = shade
	_veil.material = material
	_root.add_child(_page)
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for panel in [_entrance, _pause_menu, _result, _hud]:
		_page.add_child(panel)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label(_entrance, "НИЖНИЕ\nСВОДЫ", _serif, 70, PAPER)
	_title.add_theme_constant_override("line_spacing", -19)
	_entrance.add_child(_choices)
	_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size_row := HBoxContainer.new()
	_choices.add_child(size_row)
	size_row.alignment = BoxContainer.ALIGNMENT_END
	size_row.add_theme_constant_override("separation", 12)
	_label(size_row, "Размер карты", _sans, 16, SECONDARY)
	size_row.add_child(_map_size)
	_style_picker(_map_size)
	_map_size.add_item("Маленькая", Expedition.MapSize.SMALL)
	_map_size.add_item("Средняя", Expedition.MapSize.MEDIUM)
	_map_size.add_item("Большая", Expedition.MapSize.LARGE)
	_map_size.select(_map_size.get_item_index(Expedition.MapSize.LARGE))
	_enter = _button(_choices, "Обычный режим", 25)
	_enter.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enter.pressed.connect(func(): start_requested.emit(Expedition.Rules.NORMAL, selected_size()))
	var hard := _button(_choices, "Сложный режим", 25)
	hard.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hard.pressed.connect(func(): start_requested.emit(Expedition.Rules.HARD, selected_size()))
	var sandbox := _button(_choices, "Песочница", 20)
	sandbox.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sandbox.pressed.connect(func(): start_requested.emit(Expedition.Rules.SANDBOX, selected_size()))
	_controls = _label(_hud, "WASD  —  идти      ·      Мышь  —  осмотреться      ·      Shift  —  бег      ·      Esc  —  пауза", _sans, 15, PAPER)
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice = _label(_hud, "", _sans, 20, PAPER)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for label: Label in [_controls, _notice]:
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.035, 0.9))
		label.add_theme_constant_override("outline_size", 4)
	_controls.hide()
	_notice.hide()
	_build_health()
	_build_pause()
	_result_title = _label(_result, "Выход найден", _serif, 64, PAPER)
	_again = _button(_result, "Новая игра", 24)
	_again.position.y = 94
	_again.pressed.connect(func(): start_requested.emit(_retry_rules, selected_size()))
	var back := _button(_result, "В главное меню", 19)
	back.position.y = 144
	back.pressed.connect(menu_requested.emit)
	_build_language_picker()
	_root.resized.connect(_layout)
	_layout()
	show_entrance()


func configure(sensitivity: float, volume: float, steps: float) -> void:
	_sensitivity_slider.value = sensitivity
	_volume_slider.value = volume
	_steps_slider.value = steps


func set_place(title: String) -> void:
	if _place.text != title:
		_place.text = title


func _build_language_picker() -> void:
	_page.add_child(_language_row)
	_language_row.add_theme_constant_override("separation", 12)
	var caption := _label(_language_row, "Язык", _sans, 16, PAPER)
	caption.add_theme_constant_override("outline_size", 4)
	caption.add_theme_color_override("font_outline_color", Color("#282621"))
	_language_row.add_child(_language)
	_style_picker(_language)
	for locale: String in LANGUAGES:
		_language.add_item(LANGUAGES[locale])
		var index := _language.item_count - 1
		_language.set_item_metadata(index, locale)
		if locale == TranslationServer.get_locale():
			_language.select(index)
	_language.item_selected.connect(func(index: int):
		language_changed.emit(_language.get_item_metadata(index))
		_update_accessibility_names()
		_layout.call_deferred())
	_update_accessibility_names()


func selected_size() -> Expedition.MapSize:
	return _map_size.get_selected_id() as Expedition.MapSize


func _style_picker(picker: OptionButton) -> void:
	picker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	picker.add_theme_font_override("font", _sans)
	picker.add_theme_font_size_override("font_size", 18)
	var popup_theme := Theme.new()
	popup_theme.set_font("font", "PopupMenu", _sans)
	picker.get_popup().theme = popup_theme
	picker.get_popup().force_native = true


func _build_health() -> void:
	_hud.add_child(_health_row)
	_health_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := _label(_health_row, "Здоровье", _sans, 16, PAPER)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color("#211b1b"))
	_health_row.add_child(_health)
	_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_health.show_percentage = false
	_health.step = 0.
	_health.custom_minimum_size = Vector2(180, 9)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#382c2d")
	track.set_border_width_all(1)
	track.border_color = SECONDARY.darkened(.4)
	_health.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	_health.add_theme_stylebox_override("fill", fill)


func set_health(value: float) -> void:
	_health.value = value


func _update_accessibility_names() -> void:
	_map_size.accessibility_name = tr("Размер карты")
	_health.accessibility_name = tr("Здоровье")
	_language.accessibility_name = tr("Язык")
	_sensitivity_slider.accessibility_name = tr("Чувствительность мыши")
	_volume_slider.accessibility_name = tr("Громкость")
	_steps_slider.accessibility_name = tr("Свои шаги")


func _build_pause() -> void:
	_place = _label(_pause_menu, "", _sans, 15, SECONDARY)
	_place.position = Vector2(1,-22)
	var heading := _label(_pause_menu, "Пауза", _serif, 65, PAPER)
	heading.position = Vector2(0, 0)
	_resume = _button(_pause_menu, "Продолжить", 23)
	_resume.position = Vector2(0, 90)
	_resume.pressed.connect(resume_requested.emit)
	_objective = _label(_pause_menu, "", _sans, 18, PAPER)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.position = Vector2(340, 100)
	_objective.size = Vector2(365, 0)
	_objective.text = OBJECTIVE
	_sensitivity_slider = _slider("Чувствительность мыши", 161, 0.25, 3.0, 0.05)
	_sensitivity_slider.value_changed.connect(func(v: float): sensitivity_changed.emit(v))
	_volume_slider = _slider("Громкость", 223, 0, 1.0, 0.025)
	_volume_slider.value_changed.connect(func(v: float): volume_changed.emit(v))
	_steps_slider = _slider("Свои шаги", 285, 0, 1.0, 0.025)
	_steps_slider.value_changed.connect(func(v: float): steps_changed.emit(v))
	var menu := _button(_pause_menu, "Завершить и выйти в меню", 18)
	menu.position = Vector2(0, 350)
	menu.pressed.connect(menu_requested.emit)
	var leave := _button(_pause_menu, "Выйти из игры", 18)
	leave.position = Vector2(0, 390)
	leave.pressed.connect(exit_requested.emit)


func _slider(caption: String, y: float, min_value: float, max_value: float, step: float) -> HSlider:
	var label := _label(_pause_menu, caption, _sans, 16, SECONDARY)
	label.position = Vector2(0, y)
	var slider := HSlider.new()
	_pause_menu.add_child(slider)
	slider.position = Vector2(0, y + 24)
	slider.size = Vector2(265, 21)
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.40, 0.37, 0.32)
	track.content_margin_top = 1.5
	track.content_margin_bottom = 1.5
	slider.add_theme_stylebox_override("slider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = ACCENT
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_stylebox_override("focus", _focus_style())
	return slider


func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = FOCUS
	style.border_width_bottom = 1
	style.expand_margin_bottom = 1
	return style


func _button(parent: Control, caption: String, font_size: int) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = caption
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _sans)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", FOCUS)
	button.add_theme_color_override("font_focus_color", FOCUS)
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", _focus_style())
	button.custom_minimum_size.y = 37
	return button


func _label(parent: Control, caption: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.text = caption
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _layout() -> void:
	var canvas := _root.size
	var factor := clampf(minf(canvas.x / 1120.0, canvas.y / 630.0), 0.23, 2.3)
	var bounds := canvas / factor
	var inset := minf(68.0, bounds.x * 0.06)
	_page.scale = Vector2.ONE * factor
	_page.size = bounds
	_entrance.size = bounds
	_language_row.size = _language_row.get_combined_minimum_size()
	_language_row.position = Vector2(bounds.x - inset - _language_row.size.x, 28)
	_title.position = Vector2(inset, bounds.y - 184.0)
	_choices.size = Vector2(maxf(220, _choices.get_combined_minimum_size().x), 0)
	_choices.position = Vector2(bounds.x - inset - _choices.size.x, bounds.y - 55.0 - _choices.size.y)
	_pause_menu.position = Vector2(inset, (bounds.y - 435.0) * 0.5)
	_result.position = Vector2(inset, (bounds.y - 190.0) * 0.5)
	_health_row.position = Vector2(inset, 32.)
	_controls.size = Vector2(bounds.x, 28)
	_controls.position = Vector2(0, bounds.y - 52)
	_notice.size.x = bounds.x - 2 * inset
	_notice.position = Vector2(inset, bounds.y - 138)


func show_entrance() -> void:
	_hud.hide()
	_notice.hide()
	_pause_menu.hide()
	_result.hide()
	_entrance.show()
	_veil.show()
	(_veil.material as ShaderMaterial).set_shader_parameter("pause_factor", 0.0)
	_language_row.show()
	_enter.grab_focus()


func show_walk(first_entry: bool, rules: Expedition.Rules) -> void:
	_language_row.hide()
	_veil.hide()
	_pause_menu.hide()
	_result.hide()
	_entrance.hide()
	_hud.show()
	_health_row.visible = rules == Expedition.Rules.HARD
	if first_entry:
		set_health(_health.max_value)
		_notice.hide()
		if rules != Expedition.Rules.SANDBOX:
			show_notice(HARD_OBJECTIVE if rules == Expedition.Rules.HARD else OBJECTIVE, 8.0)
		_controls.modulate.a = 0.0
		_controls.show()
		_hint_tween = create_tween()
		_hint_tween.tween_property(_controls, "modulate:a", 1.0, 0.35)
		_hint_tween.tween_interval(5.0)
		_hint_tween.tween_property(_controls, "modulate:a", 0.0, 1.1)
		_hint_tween.tween_callback(_controls.hide)


func show_notice(message: String, seconds := 4.0) -> void:
	if _notice_tween and _notice_tween.is_valid():
		_notice_tween.kill()
	_notice.text = message
	_notice.modulate.a = 1.0
	_notice.show()
	_notice_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_notice_tween.tween_interval(seconds)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.65)
	_notice_tween.tween_callback(_notice.hide)


func _show_overlay() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_controls.hide()
	_hud.hide()
	_language_row.show()
	_entrance.hide()
	_veil.show()
	(_veil.material as ShaderMaterial).set_shader_parameter("pause_factor", 1.0)


func show_pause(rules: Expedition.Rules) -> void:
	_show_overlay()
	_objective.visible = rules != Expedition.Rules.SANDBOX
	_objective.text = HARD_OBJECTIVE if rules == Expedition.Rules.HARD else OBJECTIVE
	_pause_menu.show()
	_resume.grab_focus()


func show_result(won: bool, rules: Expedition.Rules) -> void:
	_retry_rules = rules
	_result_title.text = "Выход найден" if won else "Тьма поглотила тебя"
	_show_overlay()
	_pause_menu.hide()
	_result.show()
	_again.grab_focus()
