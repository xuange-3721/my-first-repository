extends Control

## 换弹进度条 - 白色竖条，在玩家身侧显示换弹倒计时
@export var bar_width : float = 4.0
@export var bar_height : float = 30.0
@export var bar_color : Color = Color(1, 1, 1, 0.9)
@export var bg_color : Color = Color(0.3, 0.3, 0.3, 0.3)

var progress : float = 0.0  # 0.0 ~ 1.0
var is_visible_bar : bool = false


func _ready() -> void:
	queue_redraw()


func show_bar() -> void:
	is_visible_bar = true
	queue_redraw()


func hide_bar() -> void:
	is_visible_bar = false
	queue_redraw()


func set_progress(p: float) -> void:
	progress = clamp(p, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not is_visible_bar:
		return
	
	# 背景条
	var bg_rect := Rect2(Vector2.ZERO, Vector2(bar_width, bar_height))
	draw_rect(bg_rect, bg_color)
	
	# 进度条（从下往上填充）
	var filled_height := bar_height * progress
	var fill_rect := Rect2(Vector2(0, bar_height - filled_height), Vector2(bar_width, filled_height))
	draw_rect(fill_rect, bar_color)
