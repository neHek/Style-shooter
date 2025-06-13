extends Control
enum Menus {HIDDEN = -1, START_MENU = 0, HOST_MENU, SETTINGS_MENU}
var active_menu = 0


func _ready():
	show()
	active_menu = Menus.START_MENU
	update_menu()

func _on_play_pressed() -> void:
	active_menu = Menus.HOST_MENU
	update_menu()


func _on_settings_pressed() -> void:
	active_menu = Menus.SETTINGS_MENU
	update_menu()


func _on_quit_pressed() -> void:
	multiplayer.close()
	get_tree().quit()

func update_menu() -> void:
	for child in get_children(true):
		child.visible = false
	if active_menu == -1:
		hide()
		return
	get_child(active_menu).visible = true

func back_to_main():
	active_menu = Menus.START_MENU
	for child in get_children(true):
		child.visible = false
	update_menu()

func close_menu():
	active_menu = Menus.HIDDEN
	update_menu()

func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)
	if value <= -49.0:
		if !AudioServer.is_bus_mute(0):
			AudioServer.set_bus_mute(0,true)
	elif AudioServer.is_bus_mute(0):
		AudioServer.set_bus_mute(0,false)
