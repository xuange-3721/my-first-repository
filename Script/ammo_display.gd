extends Control

@export var dot_radius : float = 3.0
@export var dot_spacing : float = 8.0
@export var dot_color_full : Color = Color(1, 0.9, 0, 1)
@export var dot_color_empty : Color = Color(0.3, 0.3, 0.3, 0.5)
@export var horizontal : bool = false  # true=水平排列, false=垂直排列

var max_ammo : int = 5
var current_ammo : int = 5


func _ready() -> void:
	queue_redraw()


func set_ammo(current: int, maximum: int) -> void:
	current_ammo = clamp(current, 0, maximum)
	max_ammo = maximum
	queue_redraw()


func _draw() -> void:
	for i in range(max_ammo):
		var pos := Vector2.ZERO
		if horizontal:
			pos = Vector2(i * dot_spacing, 0)
		else:
			pos = Vector2(0, i * dot_spacing)
		var color := dot_color_full if i < current_ammo else dot_color_empty
		draw_circle(pos, dot_radius, color)
