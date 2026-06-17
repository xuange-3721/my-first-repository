extends Area2D

@export var speed : float = 400.0
@export var damage : int = 1

var direction : Vector2 = Vector2.RIGHT


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	# 2 秒后自动销毁
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
