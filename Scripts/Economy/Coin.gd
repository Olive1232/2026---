class_name Coin
extends Area3D

## 一枚钱币。
##
## 生命周期：喷出（抛物线）→ 吸附（飞向玩家）→ 被收起（回池）。
##
## 为什么不用 RigidBody3D：洞一次会喷出几十上百枚币，每个都挂刚体的话
## 物理开销和节点数都太浪费。这里手动算速度即可，配合对象池复用。
##
## 钱币是 Area3D 而非物理体——它不需要和任何东西发生物理碰撞。

enum Phase {
	EJECT,   ## 从洞里喷出，走抛物线
	SEEK,    ## 飞向玩家
	COLLECTED, ## 已收进钱包，等待回池
}

## 单枚价值。由洞在喷出时按品质设置。
var value: int = 1
## 喷出初速度。
var eject_velocity: Vector3 = Vector3.ZERO
## 吸附阶段的目标（玩家的胸口位置）。
var seek_target: Node3D = null
## 吸附加速度。
var seek_accel: float = 34.0
## 吸附最大速度。
var seek_max_speed: float = 22.0

var _phase: Phase = Phase.EJECT
var _velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
## 抛射阶段的最短时长，之后才允许转入吸附。
var _eject_min_time: float = 0.28
var _seek_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0


## 由对象池/洞调用：重置状态并喷出。
func launch(p_value: int, p_color: Color, p_velocity: Vector3, p_eject_min_time: float = 0.28) -> void:
	value = p_value
	eject_velocity = p_velocity
	_eject_min_time = p_eject_min_time
	_phase = Phase.EJECT
	_velocity = p_velocity
	_seek_velocity = Vector3.ZERO
	_age = 0.0
	visible = true
	set_process(true)
	_apply_color(p_color)


func _apply_color(color: Color) -> void:
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh == null:
		return
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.material_override = mat
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5


func _process(delta: float) -> void:
	match _phase:
		Phase.EJECT:
			_tick_eject(delta)
		Phase.SEEK:
			_tick_seek(delta)
		Phase.COLLECTED:
			pass


func _tick_eject(delta: float) -> void:
	_age += delta
	_velocity.y -= 9.8 * delta
	global_position += _velocity * delta
	# 落在地上就停住并原地打转（简化：直接贴地）。
	if global_position.y < 0.08:
		global_position.y = 0.08
		_velocity.y = 0.0
		_velocity.x = move_toward(_velocity.x, 0.0, 6.0 * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, 6.0 * delta)
	# 过了最短抛射时间就转入吸附。
	if _age >= _eject_min_time:
		_phase = Phase.SEEK


func _tick_seek(delta: float) -> void:
	if seek_target == null or not is_instance_valid(seek_target):
		# 没有目标就原地待着，等洞重新指派。
		return
	var to_target := seek_target.global_position - global_position
	var dist := to_target.length()
	if dist < 0.6:
		_collect()
		return
	_seek_velocity += to_target.normalized() * seek_accel * delta
	_seek_velocity = _seek_velocity.limit_length(seek_max_speed)
	global_position += _seek_velocity * delta


func _collect() -> void:
	if _phase == Phase.COLLECTED:
		return
	_phase = Phase.COLLECTED
	Wallet.add(value)
	EventBus.coin_collected.emit(value)
	# 由池负责回收。
	if CoinPool != null:
		CoinPool.release(self)
	else:
		queue_free()


## 池回收时调用：彻底停下，等下次 launch。
func reset_for_pool() -> void:
	_phase = Phase.COLLECTED
	_velocity = Vector3.ZERO
	_seek_velocity = Vector3.ZERO
	seek_target = null
	visible = false
	set_process(false)


## 是否还在喷出阶段（尚未被吸附）。
func is_ejecting() -> bool:
	return _phase == Phase.EJECT


## 是否已被收走（等待回池）。
func is_collected() -> bool:
	return _phase == Phase.COLLECTED
