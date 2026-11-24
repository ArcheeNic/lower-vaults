extends CanvasLayer

signal exit_requested
signal enter_requested
signal sensitivity_changed(value: float)
signal steps_changed(value: float)
signal volume_changed(value: float)

const PAPER := Color("#f0e3c9")
const SECONDARY := Color("#dcceb9")
const ACCENT := Color("#dba674")
const FOCUS := Color("#f2b981")
var _serif := SystemFont.new()
var _sans := SystemFont.new()
var _root := Control.new()
var _page := Control.new()
var _entrance := Control.new()
var _pause_menu := Control.new()
var _title: Label
var _enter: Button
var _controls: Label
var _place: Label
var _resume: Button
var _veil := ColorRect.new()
var _hint_tween: Tween
var _sensitivity_slider: HSlider
var _volume_slider: HSlider
var _steps_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_serif.font_names = PackedStringArray(["Nimbus Roman", "Liberation Serif", "Georgia", "DejaVu Serif"])
	_sans.font_names = PackedStringArray(["Ubuntu", "Segoe UI", "DejaVu Sans"])
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
	for panel in [_entrance, _pause_menu]:
		_page.add_child(panel)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label(_entrance, "НИЖНИЕ\nСВОДЫ", _serif, 70, PAPER)
	_title.add_theme_constant_override("line_spacing", -19)
	_enter = _button(_entrance, "Войти    ↵", 24)
	_enter.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enter.pressed.connect(func(): enter_requested.emit())
	_controls = _label(_page, "WASD  —  идти      ·      Мышь  —  осмотреться      ·      Shift  —  бег      ·      Esc  —  пауза", _sans, 15, PAPER)
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls.add_theme_color_override("font_shadow_color", Color(0.04, 0.04, 0.035, 0.95))
	_controls.add_theme_constant_override("shadow_offset_x", 1)
	_controls.add_theme_constant_override("shadow_offset_y", 2)
	_controls.hide()
	_build_pause()
	_pause_menu.hide()
	_root.resized.connect(_layout)
	_layout()


func configure(sensitivity: float, volume: float, steps: float) -> void:
	_sensitivity_slider.value = sensitivity
	_volume_slider.value = volume
	_steps_slider.value = steps


func set_place(title: String) -> void:
	if _place.text != title:
		_place.text = title


func _build_pause() -> void:
	_place = _label(_pause_menu, "", _sans, 15, SECONDARY)
	_place.position = Vector2(1,-22)
	var heading := _label(_pause_menu, "Пауза", _serif, 65, PAPER)
	heading.position = Vector2(0, 0)
	_resume = _button(_pause_menu, "Продолжить", 23)
	_resume.position = Vector2(0, 90)
	_resume.pressed.connect(func(): enter_requested.emit())
	_sensitivity_slider = _slider("Чувствительность мыши", 161, 0.25, 3.0, 0.05)
	_sensitivity_slider.value_changed.connect(func(v: float): sensitivity_changed.emit(v))
	_volume_slider = _slider("Громкость", 223, 0, 1.0, 0.025)
	_volume_slider.value_changed.connect(func(v: float): volume_changed.emit(v))
	_steps_slider = _slider("Свои шаги", 285, 0, 1.0, 0.025)
	_steps_slider.value_changed.connect(func(v: float): steps_changed.emit(v))
	var leave := _button(_pause_menu, "Выйти из игры", 18)
	leave.position = Vector2(0, 365)
	leave.pressed.connect(exit_requested.emit)


func _slider(caption: String, y: float, min_value: float, max_value: float, step: float) -> HSlider:
	var label := _label(_pause_menu, caption, _sans, 16, SECONDARY)
	label.position = Vector2(0, y)
	var slider := HSlider.new()
	slider.accessibility_name = caption
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
	_title.position = Vector2(inset, bounds.y - 184.0)
	_enter.size = Vector2(155, 42)
	_enter.position = Vector2(bounds.x - inset - _enter.size.x, bounds.y - 86.0)
	_pause_menu.position = Vector2(inset, (bounds.y - 419.0) * 0.5)
	_controls.size = Vector2(bounds.x, 28)
	_controls.position = Vector2(0, bounds.y - 52)


func show_walk(first_entry: bool) -> void:
	_veil.hide()
	_pause_menu.hide()
	_entrance.hide()
	if first_entry:
		_controls.modulate.a = 0.0
		_controls.show()
		_hint_tween = create_tween()
		_hint_tween.tween_property(_controls, "modulate:a", 1.0, 0.35)
		_hint_tween.tween_interval(5.0)
		_hint_tween.tween_property(_controls, "modulate:a", 0.0, 1.1)
		_hint_tween.tween_callback(_controls.hide)


func show_pause() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_controls.hide()
	_entrance.hide()
	_veil.show()
	(_veil.material as ShaderMaterial).set_shader_parameter("pause_factor", 1.0)
	_pause_menu.show()
	_resume.grab_focus()
