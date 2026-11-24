@tool
extends EditorPlugin

const THEME := preload("res://addons/blue_archive_editor_theme/resources/blue_archive_theme.tres")
const PREVIEW_SCENE := preload("res://addons/blue_archive_editor_theme/preview/theme_preview.tscn")

var _preview: Control
var _editor_theme: Theme
var _editor_root: Control
var _editor_root_theme_backup: Theme


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		return

	_editor_theme = get_editor_interface().get_editor_theme()
	_editor_root = get_editor_interface().get_base_control()
	_editor_root_theme_backup = _editor_root.theme

	var combined_theme := Theme.new()
	combined_theme.merge_with(_editor_theme)
	combined_theme.merge_with(THEME)
	_editor_root.theme = combined_theme

	_preview = PREVIEW_SCENE.instantiate()
	_preview.name = "BlueArchiveThemePreview"
	add_control_to_bottom_panel(_preview, "蔚蓝档案主题")
	add_tool_menu_item("蔚蓝档案主题预览", _show_preview)
	print("Blue Archive Editor Theme: enabled")


func _exit_tree() -> void:
	remove_tool_menu_item("蔚蓝档案主题预览")
	if _preview != null:
		remove_control_from_bottom_panel(_preview)
		_preview.queue_free()
		_preview = null

	if _editor_root != null and _editor_root_theme_backup != null:
		_editor_root.theme = _editor_root_theme_backup
	_editor_theme = null
	_editor_root = null
	_editor_root_theme_backup = null


func _show_preview() -> void:
	make_bottom_panel_item_visible(_preview)
