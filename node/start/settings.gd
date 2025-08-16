extends Control

func _input(event: InputEvent) -> void:
	if event.is_action("quit"):
		get_tree().call_deferred("change_scene_to_file", "res://node/start/#.tscn")

func _ready() -> void:
	#region BGM
	AudioServer.set_bus_volume_db(1, SettingScript.get_config_in_main("audio", "bgm", 0))
	%bgm.value = db_to_linear(AudioServer.get_bus_volume_db(1))
	#endregion

func _on_bgm_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(%bgm.value))
	SettingScript.save_config_to_main("audio", "bgm", linear_to_db(%bgm.value))
