@tool
extends EditorPlugin

const THEME := preload("res://addons/blue_archive_editor_theme/resources/blue_archive_theme.tres")
const PREVIEW_SCENE := preload("res://addons/blue_archive_editor_theme/preview/theme_preview.tscn")
const TAB_STYLES := ["tab_selected", "tab_hovered", "tab_unselected", "tab_disabled", "tab_focus", "button_pressed", "button_highlight", "panel"]

var _preview: Control
var _editor_theme: Theme
var _editor_root: Control
var _editor_root_theme_backup: Theme
var _editor_settings: EditorSettings
var _tabbar_theme_backups: Dictionary = {}
var _editor_values_backup: Dictionary = {}

const FORCED_LIGHT_VALUES := {
	"interface/theme/color_preset": "Light",
	"text_editor/theme/highlighting/background_color": Color("#F8FCFF"),
	"text_editor/theme/highlighting/caret_background_color": Color("#F8FCFF"),
	"text_editor/theme/highlighting/completion_background_color": Color("#F8FCFF"),
}


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	_editor_theme = get_editor_interface().get_editor_theme()
	_editor_root = get_editor_interface().get_base_control()
	_editor_root_theme_backup = _editor_root.theme
	_editor_settings = get_editor_interface().get_editor_settings()
	_editor_settings.settings_changed.connect(_on_settings_changed)
	_apply_theme()

	_preview = PREVIEW_SCENE.instantiate()
	_preview.name = "BlueArchiveThemePreview"
	add_control_to_bottom_panel(_preview, "蔚蓝档案主题")
	_apply_theme()
	add_tool_menu_item("蔚蓝档案主题预览", _show_preview)
	print("Blue Archive Editor Theme: enabled (forced light)")


func _exit_tree() -> void:
	remove_tool_menu_item("蔚蓝档案主题预览")
	if _preview != null:
		remove_control_from_bottom_panel(_preview)
		_preview.queue_free()
		_preview = null

	if _editor_settings != null and _editor_settings.settings_changed.is_connected(_on_settings_changed):
		_editor_settings.settings_changed.disconnect(_on_settings_changed)
	if _editor_settings != null:
		_restore_editor_values()
	if _editor_root != null and _editor_root_theme_backup != null:
		_editor_root.theme = _editor_root_theme_backup
	_restore_tabbar_themes()

	_editor_theme = null
	_editor_root = null
	_editor_root_theme_backup = null
	_editor_settings = null
	_editor_values_backup.clear()
	_tabbar_theme_backups.clear()


func _on_settings_changed() -> void:
	if _editor_root != null:
		call_deferred("_apply_theme")


func _apply_theme() -> void:
	if _editor_root == null:
		return
	_force_light_editor_settings()
	_editor_theme = get_editor_interface().get_editor_theme()
	var combined := _build_theme()
	_editor_root.theme = combined
	_apply_tabbar_themes(combined)


func _force_light_editor_settings() -> void:
	for key in FORCED_LIGHT_VALUES:
		if not _editor_values_backup.has(key):
			_editor_values_backup[key] = _editor_settings.get_setting(key)
		if _editor_settings.get_setting(key) != FORCED_LIGHT_VALUES[key]:
			_editor_settings.set_setting(key, FORCED_LIGHT_VALUES[key])


func _restore_editor_values() -> void:
	for key in _editor_values_backup:
		if _editor_settings.get_setting(key) != _editor_values_backup[key]:
			_editor_settings.set_setting(key, _editor_values_backup[key])
	_editor_values_backup.clear()


func _build_theme() -> Theme:
	var combined := Theme.new()
	combined.merge_with(ThemeDB.get_default_theme())
	combined.merge_with(THEME)
	_copy_editor_data(_editor_theme, combined)
	return combined


func _apply_tabbar_themes(theme: Theme) -> void:
	for node in _editor_root.find_children("*", "TabBar", true, false):
		var tab_bar := node as TabBar
		var key := tab_bar.get_instance_id()
		if not _tabbar_theme_backups.has(key):
			_tabbar_theme_backups[key] = _capture_tabbar(tab_bar, theme)
		tab_bar.theme = theme
		for item in TAB_STYLES:
			if theme.has_stylebox(item, "TabBar"):
				tab_bar.add_theme_stylebox_override(item, theme.get_stylebox(item, "TabBar"))
		for item in theme.get_color_list("TabBar"):
			tab_bar.add_theme_color_override(item, theme.get_color(item, "TabBar"))
		for item in theme.get_font_list("TabBar"):
			tab_bar.add_theme_font_override(item, theme.get_font(item, "TabBar"))
		for item in theme.get_font_size_list("TabBar"):
			tab_bar.add_theme_font_size_override(item, theme.get_font_size(item, "TabBar"))
		for item in theme.get_constant_list("TabBar"):
			tab_bar.add_theme_constant_override(item, theme.get_constant(item, "TabBar"))


func _capture_tabbar(tab_bar: TabBar, theme: Theme) -> Dictionary:
	var data := {"theme": tab_bar.theme, "styles": {}, "colors": {}, "fonts": {}, "font_sizes": {}, "constants": {}}
	for item in TAB_STYLES:
		data["styles"][item] = {"has": tab_bar.has_theme_stylebox_override(item), "value": tab_bar.get_theme_stylebox(item)}
	for item in theme.get_color_list("TabBar"):
		data["colors"][item] = {"has": tab_bar.has_theme_color_override(item), "value": tab_bar.get_theme_color(item)}
	for item in theme.get_font_list("TabBar"):
		data["fonts"][item] = {"has": tab_bar.has_theme_font_override(item), "value": tab_bar.get_theme_font(item)}
	for item in theme.get_font_size_list("TabBar"):
		data["font_sizes"][item] = {"has": tab_bar.has_theme_font_size_override(item), "value": tab_bar.get_theme_font_size(item)}
	for item in theme.get_constant_list("TabBar"):
		data["constants"][item] = {"has": tab_bar.has_theme_constant_override(item), "value": tab_bar.get_theme_constant(item)}
	return data


func _restore_tabbar_themes() -> void:
	for key in _tabbar_theme_backups:
		var tab_bar := instance_from_id(key) as TabBar
		if tab_bar == null:
			continue
		var data: Dictionary = _tabbar_theme_backups[key]
		for item in data["styles"]:
			var entry: Dictionary = data["styles"][item]
			if entry["has"]:
				tab_bar.add_theme_stylebox_override(item, entry["value"])
			else:
				tab_bar.remove_theme_stylebox_override(item)
		for item in data["colors"]:
			var entry: Dictionary = data["colors"][item]
			if entry["has"]:
				tab_bar.add_theme_color_override(item, entry["value"])
			else:
				tab_bar.remove_theme_color_override(item)
		for item in data["fonts"]:
			var entry: Dictionary = data["fonts"][item]
			if entry["has"]:
				tab_bar.add_theme_font_override(item, entry["value"])
			else:
				tab_bar.remove_theme_font_override(item)
		for item in data["font_sizes"]:
			var entry: Dictionary = data["font_sizes"][item]
			if entry["has"]:
				tab_bar.add_theme_font_size_override(item, entry["value"])
			else:
				tab_bar.remove_theme_font_size_override(item)
		for item in data["constants"]:
			var entry: Dictionary = data["constants"][item]
			if entry["has"]:
				tab_bar.add_theme_constant_override(item, entry["value"])
			else:
				tab_bar.remove_theme_constant_override(item)
		tab_bar.theme = data["theme"]


func _copy_editor_data(source: Theme, target: Theme) -> void:
	for type_name in source.get_type_list():
		for icon_name in source.get_icon_list(type_name):
			if not target.has_icon(icon_name, type_name):
				target.set_icon(icon_name, type_name, source.get_icon(icon_name, type_name))
		for constant_name in source.get_constant_list(type_name):
			if not target.has_constant(constant_name, type_name):
				target.set_constant(constant_name, type_name, source.get_constant(constant_name, type_name))
		for size_name in source.get_font_size_list(type_name):
			if not target.has_font_size(size_name, type_name):
				target.set_font_size(size_name, type_name, source.get_font_size(size_name, type_name))


func _show_preview() -> void:
	make_bottom_panel_item_visible(_preview)
