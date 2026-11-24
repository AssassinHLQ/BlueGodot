@tool
extends Control

const TAB_STYLES := ["tab_selected", "tab_hovered", "tab_unselected", "tab_disabled", "tab_focus", "button_pressed", "button_highlight", "panel"]


func _ready() -> void:
	call_deferred("_apply_tabbar_theme")


func _apply_tabbar_theme() -> void:
	var tabs := find_child("PreviewTabs", true, false) as TabContainer
	if tabs == null or theme == null:
		return
	var tab_bar := tabs.get_tab_bar()
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
