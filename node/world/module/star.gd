@tool
extends StaticBody2D

@export var radius: float = 128000 # 恒星半径
@export var color: Color = Color(1.0, 0.8, 0.2) # 恒星颜色
@export var light_intensity: float = 1.0 # 光照强度
@export var light_range: float = 100000 # 光照范围

func _ready():
	# 光照
	var light = get_node("light")
	light.color = color
	light.energy = light_intensity
	light.texture_scale = radius * 128
	# 实体
	var polygon = get_node("polygon")
	#生成圆形
	var points = []
	var count = 64  # 分段数
	for i in range(count):
		var angle = TAU * i / count
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon.set("polygon", points)
