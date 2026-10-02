class_name Grabber
extends Node3D

## 右键抓取 / 拖拽搬运。
##
## 挂在 Player/Camera3D/Grabber 下。它自己**不持有物体**——
## 被抓的东西（尸体等）由自己负责软跟随，本节点只负责：
##   1. 射线探测准星指向的可抓取物
##   2. 右键按下 → 抓住 / 松开
##   3. 告诉玩家"现在扛着多重"，让玩家自己算移速
##
## 一次只能抓一个（策划需求：主角一次只能抓取一个物品）。

## 抓取射线长度（米）。比剑的 range 略长，让"伸手能碰到"感觉合理。
@export var grab_range: float = 2.6
## 持有点相对相机的偏移（相机空间）。
@export var hold_offset: Vector3 = Vector3(0.0, -0.35, -1.1)
## 抬起的物体是否要挡住剑（暂时不用，留作将来做"双手互斥"）。

var _current: Node3D = null
var _hold_point: Node3D = null
var _player: Node3D = null


func _ready() -> void:
	_hold_point = get_node_or_null("HoldPoint") as Node3D
	if _hold_point == null:
		_hold_point = Node3D.new()
		_hold_point.name = "HoldPoint"
		add_child(_hold_point)
	_hold_point.position = hold_offset
	# 找到玩家（沿父链向上找带搬运接口的节点）。
	_player = _find_carrier()
	if _player == null:
		push_warning("Grabber：没找到带 set_carry_weight 的玩家节点，负重伤速不会生效。")


func _find_carrier() -> Node3D:
	var node: Node = get_parent()
	while node != null:
		if node is Node3D and node.has_method("set_carry_weight"):
			return node as Node3D
		node = node.get_parent()
	return null


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("Grab"):
		if is_holding():
			drop()
		else:
			try_grab()


func _physics_process(_delta: float) -> void:
	# 持有中的物体如果被释放/销毁了，清掉引用。
	if _current != null and not is_instance_valid(_current):
		_clear_current()


# ---- 抓 / 放 -------------------------------------------------------------

## 尝试抓起准星指向的东西。返回是否成功。
func try_grab() -> bool:
	if is_holding():
		return false
	var target := _raycast_target()
	if target == null:
		return false
	if not target.has_method("grab"):
		return false
	# 有些可抓物会自己声明"现在不能被拿"（例如已被别人拿着）。
	if target.has_method("can_be_grabbed") and not target.can_be_grabbed():
		return false
	_current = target
	target.grab(_player, _hold_point)
	_apply_weight()
	return true


## 放下当前持有的东西。throw_forward = true 会向前抛。
func drop(throw_forward: bool = false) -> void:
	if _current == null:
		return
	if _current.has_method("release"):
		_current.release(throw_forward)
	_clear_current()


func is_holding() -> bool:
	return _current != null and is_instance_valid(_current)


## 当前持有的物体（可能为 null）。
func get_held() -> Node3D:
	return _current if is_holding() else null


func _clear_current() -> void:
	_current = null
	_apply_weight()


## 把负重告诉玩家。玩家自己决定移速怎么降——Grabber 不碰移速逻辑。
func _apply_weight() -> void:
	if _player == null:
		return
	var w := 0.0
	if is_holding() and "weight" in _current:
		w = float(_current.weight)
	_player.set_carry_weight(w)


## 从相机前方打一条射线，返回第一个可抓取的目标。
func _raycast_target() -> Node3D:
	var space := get_world_3d().direct_space_state
	var from := global_position
	var to := from - global_transform.basis.z * grab_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	# 只探测 PICKUP 层（尸体、钱币、锻造物品），不误抓地形和怪物。
	query.collision_mask = CollisionLayers.PICKUP
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.get("collider") as Node3D
