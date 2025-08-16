extends Node

#file
var KEY = {
	"key1": """tNVRHC*@9d!bAx"?*.9-""" #2024-12-04生成
}
var PATH = {
	"main": "user://settings/main_config.ini",
	"project": "user://settings/project.binary"
}

var main_config := ConfigFile.new()

func _ready() -> void:
	if main_config.load(PATH["main"]) != OK:
		print("主配置文件初始化")
	#region 主配置文件初始化
		main_config.set_value("audio", "bgm", AudioServer.get_bus_volume_db(1))
		main_config.save(PATH["main"])
	#endregion

func save_config_to_main(section, key, value):
	main_config.set_value(section, key, value)
	main_config.save(PATH["main"])

func get_config_in_main(section, key, value = null) -> Variant:
	return main_config.get_value(section, key, value)
