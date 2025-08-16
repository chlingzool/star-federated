extends Control

signal load_over

func _ready() -> void:
	var dir := DirAccess.open("user://package/")
	if !dir:
		DirAccess.open("user://").make_dir("package/")
		dir = DirAccess.open("user://package/")
		NO_INIT()
	var files = dir.get_files()
	for file in files:
		if file.get_extension() == "pck":
			ProjectSettings.load_resource_pack(file)
			print("加载数据包 | load package: ", file)
	load_over.emit()

func _on_load_over() -> void:
	SETTINGS()
	print_debug("load over")
	get_tree().call_deferred("change_scene_to_file", "res://node/start/#.tscn")

func NO_INIT():
	var a = DirAccess.open("user://")
	var dir_list = ["dlc/", "mod/", "settings/", "configs/"]
	for dir in dir_list:
		a.make_dir(dir)

func SETTINGS():
	var cf = ConfigFile.new()
	cf.load(SettingScript.PATH["main"])
	var idx = cf.get_value("screen", "size", 0)
	match idx:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2(1280, 640)); DisplayServer.window_set_position(DisplayServer.screen_get_size()/2 - DisplayServer.window_get_size()/2)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2(1440, 720)); DisplayServer.window_set_position(DisplayServer.screen_get_size()/2 - DisplayServer.window_get_size()/2)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2(1600, 900)); DisplayServer.window_set_position(DisplayServer.screen_get_size()/2 - DisplayServer.window_get_size()/2)
		3: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2(1920, 1080)); DisplayServer.window_set_position(DisplayServer.screen_get_size()/2 - DisplayServer.window_get_size()/2)
		4: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		5: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
