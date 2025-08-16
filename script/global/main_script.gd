extends Node

var is_drive: Dictionary = {"is": false, "who": "", "position": Vector2(0, 0)}
var world_builder_seed: int
var world_builder_cb_count: int

var tween: Tween

## 屏幕抖动
func screen_shake(strength: float, time: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tween.tween_method(
		func(s: float):
			if not camera: return
			var offset: Vector2 = Vector2.from_angle(randf_range(0, TAU)) * s
			if not camera: return
			camera.offset = offset,
		strength,
		0.0,
		time)

## 二次贝塞尔曲线
func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
	
## 基础生态生成
func spawn_ecosystem(cb_node: Node) -> void:
	if not cb_node.tree_scene or cb_node.polygon.polygon.size() < 2:
		return
	# 清理旧树和平原/森林标记
	for child in cb_node.get_children():
		if child.name.begins_with("PlanetTree_") or child.name.begins_with("SurfaceMark_") or child.name.begins_with("WaterSource_"):
			child.queue_free()
	var points: Array = cb_node.polygon.polygon.duplicate()
	# 水源生成
	var water_indices = []
	var water_segments = []
	var original_points = points.duplicate()
	var modified_points = original_points.duplicate()
	
	# 选择水域区域
	for _i in range(cb_node.water_count):
		var start_idx = cb_node.random.randi_range(0, original_points.size() - 1)
		var length = cb_node.random.randi_range(cb_node.water_length_min, cb_node.water_length_max)
		var segment = []
		for i in range(length):
			var idx = (start_idx + i) % original_points.size()
			segment.append(idx)
		water_segments.append(segment)
		water_indices.append_array(segment)
	
	# 修改地形顶点创建凹陷
	for idx in water_indices:
		var point = original_points[idx]
		var normal = point.normalized()
		var new_radius = point.length() - cb_node.water_depth
		modified_points[idx] = normal * new_radius
	
	# 更新地形多边形和碰撞多边形
	cb_node.polygon.polygon = modified_points
	cb_node.collision_polygon.polygon = modified_points
	
	# 计算所有斑块总长度
	var patch_len = int(points.size() * cb_node.forest_patch_ratio)
	var forest_indices = []
	var patch_centers = []
	# 随机分布斑块中心点，避开水域
	for p in range(cb_node.forest_patch_count):
		var center
		while true:
			center = cb_node.random.randi_range(0, points.size()-1)
			if center not in water_indices:
				break
		patch_centers.append(center)
	# 记录每个斑块的顶点索引，排除水域
	for center in patch_centers:
		for offset in range(-patch_len / float(2), patch_len / float(2)):
			var idx = (center + offset + points.size()) % points.size()
			if idx not in water_indices:
				forest_indices.append(idx)
	var is_forest := []
	for i in range(points.size()-1):
		is_forest.append(i in forest_indices)
		if cb_node.visualization: # 可视化标记
			var mark = ColorRect.new()
			mark.name = "SurfaceMark_%d" % i
			mark.color = cb_node.forest_color if is_forest[i] else cb_node.plain_color
			mark.size = Vector2(8,8)
			mark.position = points[i] - Vector2(4,4)
			mark.z_index = -5
			cb_node.add_child(mark)
	# 树分布，按最小树间距采样森林顶点，避免太密
	var last_tree_pos = null
	var tree_id = 0
	for i in range(points.size()-1):
		if not is_forest[i]:
			continue
		var vertex = points[i]
		var normal = vertex.normalized()
		var tree_pos = vertex + normal * cb_node.tree_offset
		if last_tree_pos == null or tree_pos.distance_to(last_tree_pos) >= cb_node.base_tree_spacing:
			var tree = cb_node.tree_scene.instantiate()
			tree.name = "PlanetTree_%d" % tree_id
			tree.position = tree_pos
			tree.rotation = normal.angle() + PI/2
			cb_node.add_child(tree)
			last_tree_pos = tree_pos
			tree_id += 1
	
	# 创建水体填坑
	for segment in water_segments:
		segment.insert(0, segment[0] - 1)
		segment.append(segment[-1] + 1)
		var water_points = []
		# 获取坑的所有顶点
		for idx in segment:
			var point = original_points[idx]
			water_points.append(point) # 原始顶点
		# 添加下沉后的顶点
		var reversed_segment = segment.duplicate()
		reversed_segment.reverse()
		for i in reversed_segment:
			var point = original_points[i]
			# 计算顶点
			var square_point = point - point.normalized() * cb_node.water_depth
			water_points.append(square_point)
		# 闭合多边形
		if water_points.size() > 0:
			water_points.append(water_points[0])
			# 创建水体多边形
			var water_node = Node2D.new()
			water_node.name = "WaterSource_" + str(water_segments.find(segment))
			var water_poly = Polygon2D.new()
			water_poly.polygon = water_points
			water_poly.color = cb_node.water_color
			water_poly.z_index = 1  # 确保水体在地形之上
			water_poly.antialiased = true
			water_node.add_child(water_poly)
			cb_node.add_child(water_node)

			# 调整水体透明度以确保可见
			var adjusted_color = cb_node.water_color
			adjusted_color.a = 0.9  # 设置透明度
			water_poly.color = adjusted_color
