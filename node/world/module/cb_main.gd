@tool
extends StaticBody2D

@onready var polygon: Polygon2D = $polygon
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon
@onready var light_occluder: LightOccluder2D = $LightOccluder
@onready var random: RandomNumberGenerator = RandomNumberGenerator.new()

# 可调节参数
@export var color: Color = Color(1, 1, 1)  # 基础颜色
@export var radius: float = 500.0  # 基础半径
@export var seed_: int = 42  # 随机种子
@export var frequency: float = 1.0  # 噪声频率
@export var density: float = 1.0  # 密度
@export var count: int = 1024 # 细致度

var gravity: float = 0.0  # 重力
var mass: float = 0.0  # 质量

@export var visualization := false #可视化

@export_subgroup("forest") # 森林分布参数
var tree_scene: PackedScene = preload("res://node/res/tree/tree.tscn") # 用于实例化树的场景
@export var forest_ratio: float = 0.12 # 森林占表面比例
@export var base_tree_density: float = 0.002 # 每单位周长的树密度（可调节）
@export var tree_offset: float = 120.0 # 树浮在表面距离
@export var plain_color: Color = Color(1, 1, 0.9) # 平原区域色
@export var forest_color: Color = Color(0.8, 1.0, 0.86) # 森林区域色
@export var forest_patch_count: int = 2 # 森林斑块数量
@export var forest_patch_ratio: float = 0.08 # 每个斑块占周长比例
@export var base_tree_spacing: float = 80.0 # 最小树间距

@export_subgroup("water")
@export var water_count: int = 2 # 水源数量
@export var water_length_min: int = 20 # 水源最小长度（顶点数）
@export var water_length_max: int = 80 # 水源最大长度（顶点数）
@export var water_color: Color = Color(0.5, 0.8, 1.0)
@export var water_offset: float = 100.0 # 水面离表面距离
@export var water_depth: float = 60.0 # 水坑深度
var plain_indices: Array = [] # 平原顶点索引

@export var debug_mode: bool =false # 调试模式

func _ready() -> void:
	found()

func found() -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 0.05
	noise.fractal_gain = 0.5
	updata_for_noise(noise)
	mass = (density / 720) * 4/3 * PI * (radius ** 3)
	gravity = mass / (radius ** 2)
	$cb_area/CollisionShape.shape.radius = radius * gravity
	$cb_area.gravity_point_unit_distance = gravity
	$cb_area.gravity = gravity
	match get_meta("planet_type"):
		"TP":
			var _color = [Color.FOREST_GREEN, Color.GREEN_YELLOW, Color.LIME_GREEN, Color.DARK_SEA_GREEN][randi() % 4]
			color = _color
			MainScript.spawn_ecosystem(self)
		"GAS":
			var _color = [Color.GOLD - Color(0, 0, 0, 0.5), Color.DARK_SALMON - Color(0, 0, 0, 0.5), Color.ORANGE - Color(0, 0, 0, 0.5), Color.KHAKI - Color(0, 0, 0, 0.5)][randi() % 4]
			color = _color
			$CollisionPolygon.polygon = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
			$LightOccluder.occluder.set_polygon(PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
		"ICE":
			var _color = [Color.POWDER_BLUE, Color.DEEP_SKY_BLUE, Color.ALICE_BLUE, Color.CORNFLOWER_BLUE][randi() % 4]
			color = _color
		"ROCK":
			var _color = [Color.CHOCOLATE, Color.DARK_GOLDENROD, Color.GOLDENROD, Color.PERU, Color.FIREBRICK][randi() % 5]
			color = _color
	$polygon.color = color

func updata_for_noise(noise: FastNoiseLite):
	var points: Array = []
	for i in range(count):
		var t = float(i) / count
		var noise_value = noise.get_noise_2d(cos(t * 2 * PI), sin(t * 2 * PI)) # 2D环形采样
		var percent = 0.2
		var current_radius = radius * (1.0 + percent * noise_value)
		var angle = t * 2 * PI
		var x = current_radius * cos(angle)
		var y = current_radius * sin(angle)
		points.append(Vector2(x, y))
	points.append(points[0]) # 闭合
	# 更新多边形
	polygon.set("polygon", points)
	polygon.set("color", color)
	collision_polygon.set("polygon", points)
	light_occluder.occluder.set_polygon(points)

#func _draw():
	## 获取遮罩的多边形顶点
	#var occluder_shape = light_occluder.occluder
	#var vertices = occluder_shape.polygon
	## 绘制多边形
	#draw_colored_polygon(vertices, Color(1, 0, 0, 0.5))  # 半透明红色
