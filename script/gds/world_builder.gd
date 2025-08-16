extends Node2D

@onready var base_seed: int = MainScript.world_builder_seed # 基础种子
@onready var count: int = MainScript.world_builder_cb_count # 数量
@export var min_distance: float = 320000 # 最小距离，防止星球过近

var plants: Array = []
@export var plant: PackedScene = preload("res://node/world/module/cb.tscn")
@export var star: PackedScene = preload("res://node/world/module/star.tscn")

func _ready() -> void:
	seed(base_seed)
	found()

func found():
	for child in get_children():
		child.queue_free()
	plants.clear()
	var positions: Array = []

	# 随机生成恒星半径，保证合理范围
	var core_radius := randi_range(20000, 40000)
	# 生成中央恒星
	var star_instance = star.instantiate().duplicate()
	star_instance.radius = core_radius
	star_instance.position = Vector2(0, 0)
	star_instance.color = Color(1.0, 0.8, 0.2)
	star_instance.light_intensity = 1.0
	star_instance.light_range = 100000
	add_child(star_instance)

	var delta := 1.0 # 行星轨道间距系数(可调)
	var start_orbit := core_radius*2 * 4 # 第一颗行星从恒星2倍直径开始
	for i in range(count):
		var try_count = 0
		var max_try = 50
		var pos: Vector2
		var valid = false
		# 行星半径仅小幅波动，避免过大
		var planet_radius = randf_range(0.5, 1.2) * core_radius * 0.18
		# 类型分布
		var type_roll = float(i) / float(count-1) + randf_range(-0.15, 0.15)
		var type: String
		if type_roll < 0.22:
			type = "TP"
		elif type_roll < 0.48:
			type = "GAS"
		elif type_roll < 0.75:
			type = "ICE"
		else:
			type = "ROCK"
		# 轨道半径从恒星1.2倍半径起步
		var orbit_radius = start_orbit + i * core_radius * delta
		# 只需判定与恒星的最小距离即可
		while try_count < max_try and not valid:
			var angle = randf_range(0, 2*PI)
			pos = Vector2(cos(angle), sin(angle)) * orbit_radius
			valid = pos.length() > core_radius + min_distance * 0.5
			try_count += 1
		if not valid:
			print_debug("跳过第%d个星球，无法找到合适位置" % i)
			continue
		var plant_seed = randi()
		var plant_instance = plant.instantiate().duplicate()
		plant_instance.radius = planet_radius
		plant_instance.position = pos
		plant_instance.set_meta("planet_type", type)
		plant_instance.seed_ = plant_seed
		positions.append(pos)
		add_child(plant_instance)
		print_debug("星球 %d: 类型=%s, 半径=%.2f, 位置=%s, 种子=%d" % [i, type, planet_radius, pos, plant_seed])
		if type == "GAS":
			var fog = gen_soft_gas_fog(
				planet_radius * 1.5,
				plant_seed,
				plant_instance,
				0.16,
				96
			)
			plant_instance.add_child(fog)

func gen_soft_gas_fog(radius: float, seed_: int, plant_: Node = null, alpha: float = 0.16, segments: int = 64) -> Polygon2D:
	var base_color = Color(0.8, 0.95, 1.0)
	if plant_ and plant_.has_method("get"):
		# 自动获取plant的color属性，作为雾主色
		base_color = plant_.color
	var fog = Polygon2D.new()
	var noise = FastNoiseLite.new()
	noise.seed = seed_
	noise.frequency = 0.4
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var points = []
	var amp = 0.2 # 控制扰动幅度，让边缘变动小
	for i in range(segments):
		var t = float(i) / segments
		var angle = t * PI * 2
		var n = noise.get_noise_2d(cos(angle), sin(angle))
		var r = radius * (1.0 + amp * n)
		points.append(Vector2(r * cos(angle), r * sin(angle)))
	fog.polygon = points
	fog.color = Color(base_color.r, base_color.g, base_color.b, alpha)
	fog.z_index = -1
	return fog
	
