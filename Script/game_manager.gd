extends CanvasLayer

@export var viewport_size : Vector2 = Vector2(480, 270)
@export var bad_scene : PackedScene

var game_over_ui : Control
var player_node : Node2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("game_manager")
	_rng.randomize()
	player_node = get_tree().get_first_node_in_group("player")
	
	# 创建 Game Over UI（初始隐藏）
	_create_game_over_ui()


func _create_game_over_ui() -> void:
	game_over_ui = Control.new()
	game_over_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_ui.hide()
	# 确保暂停时 UI 仍然能处理输入
	game_over_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 半透明黑色背景
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_ui.add_child(bg)
	
	# "GAME OVER" 文字
	var label := Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.RED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -150.0
	label.offset_top = -80.0
	label.offset_right = 150.0
	label.offset_bottom = -20.0
	game_over_ui.add_child(label)
	
	# 重新开始按钮
	var button := Button.new()
	button.text = "重新开始"
	button.add_theme_font_size_override("font_size", 24)
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = -75.0
	button.offset_top = 10.0
	button.offset_right = 75.0
	button.offset_bottom = 60.0
	button.pressed.connect(_on_restart_pressed)
	game_over_ui.add_child(button)
	
	add_child(game_over_ui)


func show_game_over() -> void:
	game_over_ui.show()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	# 先取消暂停，再重新加载场景
	get_tree().paused = false
	# 延迟一帧确保暂停状态已恢复
	await get_tree().process_frame
	get_tree().reload_current_scene()


func spawn_bad_at_random_edge() -> void:
	if not bad_scene:
		return
	
	var bad := bad_scene.instantiate()
	
	# 随机选择屏幕四条边之一
	var edge := _rng.randi_range(0, 3)
	var margin := 20.0
	var pos := Vector2.ZERO
	
	match edge:
		0:  # 上边
			pos = Vector2(_rng.randf_range(0, viewport_size.x), -margin)
		1:  # 下边
			pos = Vector2(_rng.randf_range(0, viewport_size.x), viewport_size.y + margin)
		2:  # 左边
			pos = Vector2(-margin, _rng.randf_range(0, viewport_size.y))
		3:  # 右边
			pos = Vector2(viewport_size.x + margin, _rng.randf_range(0, viewport_size.y))
	
	bad.position = pos
	
	# 添加到玩家所在的父节点下（Camera2D 下）
	if player_node:
		player_node.get_parent().add_child(bad)
	else:
		get_tree().current_scene.add_child(bad)
