extends CharacterBody2D

@export_group("spaceship")
@export var spaceship_name: String = "kat3"
@export var offset: Vector2 = Vector2(200, -20)

@export_group("")
@export var speed: float = 50000 # 水平移动速度
@export var force: float = 10000 # 起降推力
@onready var rotation_speed: float = 1  # 每秒旋转角速度

var in_self: bool = false  # 是否在自己的飞船内
var facing_right: bool = true # 是否面向右侧

func _physics_process(delta: float) -> void:
	if in_self and !MainScript.is_drive["is"]:
		if Input.is_action_just_pressed("interact"):
			MainScript.is_drive["is"] = true
			MainScript.is_drive["who"] = "../../spaceship/" + spaceship_name
			MainScript.is_drive["position"] = offset
			await get_tree().create_timer(0.1).timeout
	if Input.is_action_just_pressed("interact") and MainScript.is_drive["is"]:
		MainScript.is_drive["is"] = false
		MainScript.is_drive["who"] = ""
		await get_tree().create_timer(0.1).timeout
	
	if MainScript.is_drive["is"]:
		$back_door.disabled = false
		$"GPUParticles-1".emitting = true
		$"GPUParticles-2".emitting = true
	else:
		$back_door.disabled = true
		$"GPUParticles-1".emitting = false
		$"GPUParticles-2".emitting = false
		velocity = Vector2.ZERO

	if MainScript.is_drive["is"]:
		MainScript.screen_shake(1, 0.1)

		# 控制转身
		if Input.is_action_just_pressed("turn"):
			facing_right = !facing_right
			set_deferred("scale", Vector2(1 if facing_right else -1, scale.y))

		# 旋转
		if Input.is_action_pressed("roll_right"):
			rotation -= rotation_speed * delta
		elif Input.is_action_pressed("roll_left"):
			rotation += rotation_speed * delta

		var move_direction := Vector2.ZERO

		# 水平推进
		if Input.is_action_pressed("ui_right"):
			move_direction += Vector2(cos(rotation), sin(rotation))
		if Input.is_action_pressed("ui_left"):
			move_direction -= Vector2(cos(rotation), sin(rotation)) / 1.2

		# 起降推力
		if Input.is_action_pressed("ui_up"):
			move_direction += Vector2(sin(rotation), -cos(rotation)) / 1.2 # 向上（本地Y-）
		if Input.is_action_pressed("ui_down"):
			move_direction -= Vector2(sin(rotation), -cos(rotation)) # 向下（本地Y+）

		if move_direction != Vector2.ZERO:
			move_direction = move_direction.normalized()
			var horizontal = Vector2(cos(rotation), sin(rotation)).dot(move_direction)
			var vertical = Vector2(sin(rotation), -cos(rotation)).dot(move_direction)
			velocity = Vector2.ZERO
			velocity += Vector2(cos(rotation), sin(rotation)) * speed * horizontal * delta
			velocity += Vector2(sin(rotation), -cos(rotation)) * force * vertical * delta
		else:
			velocity = Vector2.ZERO
		move_and_slide()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "area-player":
		in_self = true

func _on_area_exited(area: Area2D) -> void:
	if area.name == "area-player":
		in_self = false
