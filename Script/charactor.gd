extends CharacterBody2D


@export var move_speed : float = 200.0
@export var jump_height : float = 50.0
@export var jump_duration : float = 0.4
@export var knockback_duration : float = 0.2
@export var knockback_force : float = 1000.0
@export var max_health : int = 10
@export var animator : AnimatedSprite2D

## 武器系统
@export var bullet_scene : PackedScene
@export var fire_rate : float = 0.3  # 射击间隔（秒），测试阶段可调节
@export var mag_size : int = 5  # 弹夹容量
@export var reload_time : float = 2.0  # 换弹时间（秒），可在引擎中调节

var is_jumping : bool = false
var jump_time : float = 0.0
var jump_direction : int = 1
var knockback_velocity : Vector2 = Vector2.ZERO
var knockback_timer : float = 0.0
var is_invincible : bool = false

var current_health : int
var fire_timer : float = 0.0
var is_dead : bool = false

## 弹夹系统
var current_ammo : int
var is_reloading : bool = false
var reload_timer : float = 0.0

@onready var health_bar : Control = $HealthBar
@onready var ammo_display : Control = $AmmoDisplay
@onready var reload_bar : Control = $ReloadBar


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	current_ammo = mag_size
	
	if health_bar:
		health_bar.max_health = max_health
		health_bar.set_health(current_health)
	
	if ammo_display:
		ammo_display.set_ammo(current_ammo, mag_size)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# 换弹逻辑
	if is_reloading:
		reload_timer -= delta
		var prog := 1.0 - (reload_timer / reload_time)
		if reload_bar:
			reload_bar.set_progress(prog)
		if reload_timer <= 0:
			_finish_reload()
	
	# 更新射击计时器
	if fire_timer > 0:
		fire_timer -= delta
	
	# 自动换弹：子弹打光时开始换弹
	if current_ammo <= 0 and not is_reloading:
		_start_reload()
	
	# 手动换弹：按 R 键
	if Input.is_action_just_pressed("reload") and not is_reloading and current_ammo < mag_size:
		_start_reload()
	
	# 射击：鼠标左键（换弹时不能射击）
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_timer <= 0 and current_ammo > 0 and not is_reloading:
		_shoot()
	
	# 如果正在被击退
	if knockback_timer > 0:
		knockback_timer -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, delta * 500.0)
		if animator:
			animator.play("jump")
		move_and_slide()
		return
	
	# WASD 全方向移动
	var input_vector := Input.get_vector("left", "right", "up", "down")
	velocity = input_vector * move_speed

	# 跳跃处理
	if Input.is_action_just_pressed("jump") and not is_jumping:
		start_jump()

	if is_jumping:
		update_jump(delta)

	# 动画播放
	if is_jumping:
		animator.play("jump")
	elif input_vector != Vector2.ZERO:
		animator.play("run")
	else:
		animator.play("idle")

	move_and_slide()


func _start_reload() -> void:
	is_reloading = true
	reload_timer = reload_time
	if reload_bar:
		reload_bar.show_bar()


func _finish_reload() -> void:
	is_reloading = false
	current_ammo = mag_size
	if reload_bar:
		reload_bar.hide_bar()
	if ammo_display:
		ammo_display.set_ammo(current_ammo, mag_size)


func _shoot() -> void:
	if not bullet_scene or current_ammo <= 0:
		return
	
	var bullet := bullet_scene.instantiate()
	bullet.position = global_position
	
	var mouse_pos := get_global_mouse_position()
	bullet.direction = (mouse_pos - global_position).normalized()
	
	get_parent().add_child(bullet)
	fire_timer = fire_rate
	
	# 消耗一颗子弹
	current_ammo -= 1
	if ammo_display:
		ammo_display.set_ammo(current_ammo, mag_size)


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
	
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("show_game_over"):
		gm.show_game_over()


func apply_knockback(direction: Vector2, force: float) -> void:
	if is_invincible or is_dead:
		return
	
	var offset := direction * (force * 0.03)
	global_position += offset
	
	knockback_velocity = direction * force * 0.5
	knockback_timer = knockback_duration
	is_invincible = true
	
	await get_tree().create_timer(knockback_duration + 0.1).timeout
	is_invincible = false


func start_jump() -> void:
	is_jumping = true
	jump_time = 0.0
	jump_direction = 1
	_disable_enemy_collision(true)


func update_jump(delta: float) -> void:
	var half_duration := jump_duration / 2.0
	jump_time += delta * jump_direction

	var progress := jump_time / half_duration
	var offset_y := -sin(progress * PI / 2.0) * jump_height
	animator.position.y = offset_y

	if jump_direction == 1 and jump_time >= half_duration:
		jump_direction = -1
	elif jump_direction == -1 and jump_time <= 0.0:
		animator.position.y = 0.0
		is_jumping = false
		_disable_enemy_collision(false)


func _disable_enemy_collision(disabled: bool) -> void:
	for bad in get_tree().get_nodes_in_group("enemy"):
		if bad is CharacterBody2D:
			if disabled:
				add_collision_exception_with(bad)
			else:
				remove_collision_exception_with(bad)
