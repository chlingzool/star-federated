extends Control

@onready var version = $PanelContainer/MarginContainer/HBoxContainer/version
@export var branch_and_unit := "4A"
@export var offering := "beta2"
@export var patch : int

func _ready() -> void:
	show()
	version.text = "v" + ProjectSettings.get_setting("application/config/version") + "." + str(patch) + " " + offering + " (" + branch_and_unit + ")"

func _input(event: InputEvent) -> void:
	if event.is_action("quit"):
		MainScript.is_drive["is"] = false
		MainScript.is_drive["who"] = ""
		if MainScript.tween: MainScript.tween.kill()
		await get_tree().create_timer(0.1).timeout
		get_tree().call_deferred("change_scene_to_file", "res://node/start/#.tscn")
		StartAudio.stream_paused = false
