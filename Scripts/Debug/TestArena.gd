extends Node3D

## 测试场地控制器。只服务于"M2 剑"的验证，不是正式关卡。
##
## 快捷键：
##   R  重新加载场地
##   T  在准星方向生成一个新靶子
##   F1 切换调试信息

const DUMMY_SCENE := preload("res://Scenes/Debug/TargetDummy.tscn")

## 生成新靶子时距玩家的距离。
@export var spawn_distance: float = 6.0

var _spawn_count: int = 0
var _label: Label


func _ready() -> void:
	_label = get_node_or_null("HUD/Info") as Label
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				get_tree().reload_current_scene()
			KEY_T:
				_spawn_dummy_ahead()
			KEY_F1:
				if _label:
					_label.visible = not _label.visible


func _spawn_dummy_ahead() -> void:
	var player := _find_player()
	if player == null:
		return
	var dummy := DUMMY_SCENE.instantiate() as Node3D
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	dummy.position = player.global_position + forward * spawn_distance
	dummy.position.y = 0.0
	add_child(dummy)
	_spawn_count += 1
	_update_label()


func _find_player() -> Node3D:
	for child in get_children():
		if child is Node3D and child.has_method("set_carry_weight"):
			return child
	return null


func _update_label() -> void:
	if _label == null:
		return
	_label.text = "测试场地（M2 剑）\nR 重载   T 生成靶子   F1 隐藏本提示\n左键挥砍 · WASD 移动 · 空格跳跃 · Esc 释放鼠标\n已生成靶子：%d" % _spawn_count
