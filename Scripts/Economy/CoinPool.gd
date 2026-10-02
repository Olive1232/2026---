extends Node

## 钱币对象池（autoload 名：CoinPool）。
##
## 洞一次可能喷出几十上百枚币，频繁 instantiate/free 会造成卡顿与内存抖动
## （R2 风险：800 枚币要稳 60fps）。这里预生成并复用。
##
## 池的生命周期挂在场景树上，跨房间不销毁。

const COIN_SCENE := preload("res://Scenes/Pickups/Coin.tscn")

## 场上同时存在的钱币上限。超过则不再新建，复用最早的。
@export var max_active: int = 800

var _free: Array[Coin] = []
var _active: Array[Coin] = []
## 钱币的父节点（场景根）。为 null 时池自己当父节点。
var _host: Node = null


## 让钱币挂到某个节点下（通常是当前场景根），便于随场景一起释放。
func set_host(node: Node) -> void:
	_host = node


## 取一枚钱币。会自动加入场景树并激活。
func acquire() -> Coin:
	var coin: Coin
	if _free.size() > 0:
		coin = _free.pop_back()
	else:
		if _active.size() >= max_active:
			# 到上限了就强行回收最老的一枚，避免无限增长。
			coin = _active.pop_front()
			coin.reset_for_pool()
		else:
			coin = COIN_SCENE.instantiate() as Coin
			var parent := _host if _host != null else self
			parent.add_child(coin)
	coin.visible = true
	_active.append(coin)
	return coin


## 归还一枚钱币。
func release(coin: Coin) -> void:
	if coin == null:
		return
	coin.reset_for_pool()
	var idx := _active.find(coin)
	if idx >= 0:
		_active.remove_at(idx)
	if not _free.has(coin):
		_free.append(coin)


## 当前场上活跃的钱币数。
func active_count() -> int:
	return _active.size()


## 池里空闲的钱币数。
func free_count() -> int:
	return _free.size()


## 回收场上全部钱币（重开一局 / 换房间用）。
func release_all() -> void:
	for i in range(_active.size() - 1, -1, -1):
		release(_active[i])
