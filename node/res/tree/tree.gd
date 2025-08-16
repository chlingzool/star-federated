extends Node2D
# 单棵美观树组件，可作为预制体复用，无美术素材

@export var trunk_height: float = 120.0         # 树干高度
@export var trunk_width: float = 18.0           # 树干宽度
@export var crown_radius: float = 48.0          # 树冠半径
@export var crown_segments: int = 64            # 树冠圆润度
@export var seed_: int              # 随机种子
@export var trunk_color: Color = Color(0.44, 0.29, 0.15)
@export var crown_color: Color = Color(0.25, 0.76, 0.32)

var random := RandomNumberGenerator.new()

signal tree_tapped(tree: Node2D)
var tap_count = 0 # 点击次数

func _ready():
	update_tree()

func update_tree():
	if not seed_:
		seed_ = randi()  # 如果没有设置种子，则随机生成
	random.seed = seed_
	# 树干
	var trunk = ColorRect.new()
	trunk.color = trunk_color
	trunk.size = Vector2(trunk_width, trunk_height)
	trunk.position = Vector2(-trunk_width/2, 0)
	add_child(trunk)

	# 树冠（加入噪声扰动让边缘更自然）
	var crown = Polygon2D.new()
	var points = []
	var amp = 0.08 # 控制扰动幅度
	for i in range(crown_segments):
		var t = float(i) / crown_segments
		var angle = t * PI * 2
		# 利用随机和正弦混合让树冠更自然
		var noise = sin(angle * random.randf_range(1.2, 2.7) + random.randf()*PI) * amp * random.randf_range(0.6, 1.0)
		var r = crown_radius * (1.0 + noise)
		points.append(Vector2(r * cos(angle), r * sin(angle) - crown_radius * 0.3))
	crown.polygon = points
	crown.color = crown_color
	crown.position = Vector2(0, 0)
	crown.z_index = 1
	add_child(crown)

	# 可选：加一层淡绿色半透明的外冠来丰富层次
	var crown2 = Polygon2D.new()
	var points2 = []
	for i in range(crown_segments):
		var t = float(i) / crown_segments
		var angle = t * PI * 2
		var noise = sin(angle * random.randf_range(1.5, 2.3) + random.randf()*PI) * amp * random.randf_range(0.4, 0.8)
		var r = crown_radius * 1.22 * (1.0 + noise * 0.7)
		points2.append(Vector2(r * cos(angle), r * sin(angle) - crown_radius * 0.25))
	crown2.polygon = points2
	var lerped_color = crown_color.lerp(Color(0.6, 1, 0.46), 0.35)
	crown2.color = Color(lerped_color.r, lerped_color.g, lerped_color.b, 0.20)
	crown2.position = Vector2(0,0)
	crown2.z_index = 0
	add_child(crown2)

func _on_areatree_area_entered(area: Area2D) -> void:
	if area.name == "area-player": $tap.visible = true

func _on_areatree_area_exited(area: Area2D) -> void:
	if area.name == "area-player": $tap.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not MainScript.is_drive["is"] and $tap.visible:
		emit_signal("tree_tapped", self)

func _on_tree_tapped(_tree: Node2D) -> void:
	var wood = preload("res://node/res/tree/wood.tscn").instantiate().duplicate()
	wood.position = global_position + Vector2(0, trunk_height * 0.5) # 放在树干上
	wood.rotation = randf_range(0, TAU) # 随机旋转
	wood.name = "Wood_%d" % rand_from_seed(seed_)[0]
	tap_count += 1
	get_tree().get_nodes_in_group("res")[0].add_child(wood)
	if tap_count >= 3:
		queue_free()
