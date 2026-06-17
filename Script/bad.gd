extends CharacterBody2D

@export var move_speed : float = 50.0
@export var knockback_force : float = 300.0
@export var knockback_cooldown : float = 0.5
@export var self_pushback : float = 40.0
@export var max_health : int = 5
@export var attack_damage : int = 1
@export var animator : AnimatedSprite2D

var player : Node2D
var knockback_timer : float = 0.0
var stun_timer : float = 0.0
var stun_velocity : Vector2 = Vector2.ZERO

var current_health : int
var is_dead : bool = false

@onready var health_bar : Control = $HealthBar


func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	if health_bar:
		health_bar.max_health = max_health
		health_bar.set_health(current_health)
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		player = _find_player_in_tree(get_tree().root)
	
	if player:
		print("bad 找到玩家：", player.name)
	else:
		push_warning("bad 未找到玩家角色！")


func _find_player_in_tree(node: Node) -> Node:
	if node.name == "player":
		return node
	for child in node.get_children():
		var result = _find_player_in_tree(child)
		if result:
			return result
	return null


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if knockback_timer > 0:
		knockback_timer -= delta
	
	# 自身后撤逻辑
	if stun_timer > 0:
		stun_timer -= delta
		velocity = stun_velocity
		stun_velocity = stun_velocity.move_toward(Vector2.ZERO, delta * 200.0)
		if animator:
			animator.play("idle")
		move_and_slide()
		return
	
	if not player or not is_instance_valid(player):
		velocity = Vector2.ZERO
		if animator:
			animator.play("idle")
		return
	
	var to_player := player.global_position - global_position
	var direction := to_player.normalized()
	
	velocity = direction * move_speed
	
	if direction.x != 0 and animator:
		animator.flip_h = direction.x < 0
	
	if animator:
		animator.play("walk")
	
	move_and_slide()
	
	# 检测碰撞后击退玩家
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider == player and knockback_timer <= 0:
			_apply_knockback(direction)
			# 对玩家造成伤害
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)


func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health)
	
	if current_health <= 0:
		_die()


func _die() -> void:
	is_dead = true
	hide()
	
	# 通知 GameManager 在屏幕边缘重新生成
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("spawn_bad_at_random_edge"):
		gm.spawn_bad_at_random_edge()
	
	# 延迟删除自身
	await get_tree().process_frame
	queue_free()


func _apply_knockback(direction: Vector2) -> void:
	if not player or not is_instance_valid(player):
		return
	
	if player.has_method("apply_knockback"):
		player.apply_knockback(direction, knockback_force)
	
	stun_timer = 0.15
	stun_velocity = -direction * self_pushback / 0.15
	
	knockback_timer = knockback_cooldown
