@tool
extends Node2D

@export var base_seed: int # 基础种子
@export var count: int = 8 # 数量
@export var planet_radius: float = 10000 # 行星半径
@export var planet_radius_var: float = 4 # 行星半径变化
@export var arm_count: int = 4 # 旋臂数量
@export var arm_spread: float = 0.4 # 旋臂分布
@export var arm_tightness: float = 200 # 旋臂紧密度
@export var core_radius: float = 40000 # 核心半径
@export var galaxy_radius: float = 60000000 # 银河半径
@export var min_distance: float = 100000 # 最小距离，防止星球过近

enum PlantType {
	TP, # 类地行星
	GAS, # 气态行星
	ICE, # 冰态行星
	ROCK, # 岩石行星
}

var plants: Array = []

var plant: PackedScene = preload("res://node/world/module/cb.tscn")

func match_type(plant_: Node, type: PlantType) -> void:
	if plant_ is not Node: return
	match type:
		PlantType.TP:
			plant_.set_meta("plant_type", "tp")
		PlantType.GAS:
			plant_.set_meta("plant_type", "gas")
		PlantType.ICE:
			plant_.set_meta("plant_type", "ice")
		PlantType.ROCK:
			plant_.set_meta("plant_type", "rock")

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

func _ready() -> void:
	found()

func found():
	for child in get_children():
		child.queue_free()
	plants.clear() # 清空星球信息
	var positions: Array = [] # 用于记录已生成的星球坐标

	for i in range(count):
		var try_count = 0
		var max_try = 50 # 最多尝试次数，防止死循环
		var pos: Vector2
		var valid = false
		while try_count < max_try and not valid:
			# 生成坐标
			var t = randf()
			var arm = i % arm_count
			var angle = t * PI * 2 * arm_count / arm_count + arm * 2 * PI / arm_count
			var arm_offset = randfn(0, arm_spread)
			var r = core_radius + (galaxy_radius - core_radius) * pow(t, 0.8)
			var theta = angle + arm_offset + r * arm_tightness * 0.001
			pos = Vector2(cos(theta), sin(theta)) * r
			valid = true
			for prev_pos in positions:
				if pos.distance_to(prev_pos) < min_distance:
					valid = false
					break
			try_count += 1
		if not valid:
			# 如果超过最大尝试次数仍然无法找到合适位置，则跳过本次星球生成
			print_debug("跳过第%d个星球，无法找到合适位置" % i)
			continue

		var plant_instance = plant.instantiate().duplicate()
		# 半径
		var planet_r = planet_radius * randf_range(1.0 - planet_radius_var, 1.0 + planet_radius_var)
		plant_instance.radius = planet_r
		plant_instance.position = pos
		positions.append(pos) # 记录坐标

		# 类型
		var type
		match randi() % 4:
			0: type = PlantType.TP
			1: type = PlantType.GAS
			2: type = PlantType.ICE
			3: type = PlantType.ROCK
		match_type(plant_instance, type)
		var cb_seed = randi()
		plant_instance.seed_ = cb_seed
		plants.append([plant_instance.name, cb_seed, type])
		add_child(plant_instance)
		if type == PlantType.GAS:
		# 用气态行星自身颜色生成迷雾
			var base_fog_r = planet_r * randf_range(1.7, 2.1)
			for layer in range(2):
				var fog = gen_soft_gas_fog(
					base_fog_r * (1.0 + layer * 0.18),
					cb_seed + layer * 77,
					plant_instance, # 传递当前星球实例
					0.10 if layer == 0 else 0.16,
					96
				)
				plant_instance.add_child(fog)

	print_debug(plants)
	print("生成成功")
