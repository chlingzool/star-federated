extends Control

enum MessageType {
	INFO,
	WARNING,
	ERROR
}
var message_count: int = 0

func pop_message(message: String, type: MessageType = MessageType.INFO) -> void:
	if message_count >= 4:
		$main_margin/VBox_middle.get_child(0).queue_free()
		message_count -= 1
	var message_node := preload("res://node/ui/message/message.tscn").instantiate()
	match type:
		MessageType.INFO:
			message_node.add_theme_stylebox_override("normal", preload("res://node/ui/message/info.tres"))
		MessageType.WARNING:
			message_node.add_theme_stylebox_override("normal", preload("res://node/ui/message/warning.tres"))
		MessageType.ERROR:
			message_node.add_theme_stylebox_override("normal", preload("res://node/ui/message/error.tres"))
	message_node.text = message
	message_node.name = str(message_count)
	$main_margin/VBox_middle.add_child(message_node)
	message_count += 1

#func _process(_delta: float) -> void:
	#var message = ["hello", "world", "this is a test", "another message", "a message", "star federated"][randi() % 6]
	#var message_type = [MessageType.INFO, MessageType.WARNING, MessageType.ERROR][randi() % 3]
	#if Input.is_action_just_pressed("interact"): pop_message(message, message_type)
