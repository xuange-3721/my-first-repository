extends Control

@export var max_health : int = 10
@export var bar_color : Color = Color.RED
@export var bg_color : Color = Color(0.2, 0.2, 0.2, 0.8)
@export var bar_width : float = 50.0
@export var bar_height : float = 6.0

var current_health : int


func _ready() -> void:
	current_health = max_health
	queue_redraw()


func set_health(new_health: int) -> void:
	current_health = clamp(new_health, 0, max_health)
	queue_redraw()


func _draw() -> void:
	# 背景
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), bg_color, true)
	# 血量
	var fill_width := bar_width * (float(current_health) / float(max_health))
	draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, bar_height)), bar_color, true)
