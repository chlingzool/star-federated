extends RigidBody2D

@export var speed: float = 4800.0 # 移动速度
@export var ground_speed: float = 120.0 # 地面移动速度
@onready var rotation_speed := 12000.0  # 每秒旋转角度

@export var ground_friction: float = 20.0 # 地面摩擦系数
@export var ground_accel: float = 1000.0 # 地面加速度

var facing_right := true # 是否面向右侧

@onready var raycast := $RayCast
var on_ground := false

func _physics_process(delta):
	if !MainScript.is_drive["is"]:
		on_ground = raycast.is_colliding()
		if on_ground:
			ground_move(delta)
			rotation = lerp_angle(rotation, raycast.get_collision_normal().angle() + PI / 2, delta*20)
		else:
			space_move(delta)
		if on_ground and Input.is_action_just_pressed("ui_accept"): # 考虑换Ui_up
			var ground_normal = raycast.get_collision_normal()
			apply_central_impulse(ground_normal * 200000)
	
	if MainScript.is_drive["is"]:
		$collision.disabled = true
		rotation = get_node(MainScript.is_drive["who"]).rotation
		position = get_node(MainScript.is_drive["who"]).position + MainScript.is_drive["position"].rotated(rotation)
	else:
		$collision.disabled = false

func ground_move(delta: float):
	var ground_normal = raycast.get_collision_normal()
	var tangent = Vector2(-ground_normal.y, ground_normal.x) # 计算切线方向

	var move_dir = 0
	if Input.is_action_pressed("ui_right"):
		move_dir += 1
	if Input.is_action_pressed("ui_left"):
		move_dir -= 1
	
	# 控制转身
		if Input.is_action_just_pressed("turn"):
			facing_right = !facing_right
			scale.x = 1 if facing_right else -1
			scale.y = 1
			set_deferred("scale", Vector2(1 if facing_right else -1, scale.y))
			print(scale)

	var target_speed = move_dir * ground_speed
	var tangential_speed = linear_velocity.dot(tangent)
	var speed_diff = target_speed - tangential_speed
	var accel = clamp(speed_diff, -ground_accel * delta, ground_accel * delta)
	linear_velocity += tangent * accel
	# 地面摩擦（没输入时逐步停下）
	if move_dir == 0:
		linear_velocity -= tangent * tangential_speed * ground_friction * delta
	# 贴地，去除法线分量
	linear_velocity -= ground_normal * linear_velocity.dot(ground_normal)

func space_move(delta: float):
	# 控制转身
	if Input.is_action_just_pressed("turn"):
		facing_right = !facing_right
		rotation_degrees += 180 if facing_right else -180
	if Input.is_action_pressed("ui_right"):
		var direction = Vector2(cos(rotation), sin(rotation))
		apply_central_impulse(direction * speed * delta)
	if Input.is_action_pressed("ui_left"):
		var direction = Vector2(cos(rotation), sin(rotation))
		apply_central_impulse(-direction * speed * delta)
	if Input.is_action_pressed("ui_down"):
		var direction = Vector2(cos(rotation + PI / 2), sin(rotation + PI / 2))
		apply_central_impulse(direction * speed * delta)
	if Input.is_action_pressed("ui_up"):
		var direction = Vector2(cos(rotation + PI / 2), sin(rotation + PI / 2))
		apply_central_impulse(-direction * speed * delta)
	if Input.is_action_pressed("roll_right"):
		apply_torque_impulse(-rotation_speed * delta)
	if Input.is_action_pressed("roll_left"):
		apply_torque_impulse(rotation_speed * delta)
