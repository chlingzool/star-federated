extends StaticBody2D

# 用于存储水坑的多边形点
var water_polygon: Array = []

# 设置水坑多边形的函数
func set_water_polygon(points: Array) -> void:
	water_polygon = points
	# 更新 Polygon2D 和 CollisionPolygon2D 的多边形点
	var water_polygon_node = $WaterPolygon
	var water_collision_node = $WaterCollision
	
	water_polygon_node.polygon = water_polygon
	water_collision_node.polygon = water_polygon
