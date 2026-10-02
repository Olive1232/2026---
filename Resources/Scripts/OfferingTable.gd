class_name OfferingTable
extends Resource

## 献祭 → 涌现 的配置表。
##
## 策划需要提供的数据形状：给定尸体的基础价值，洞应该喷出多少枚币、
## 总价值放大多少倍、币的品质如何分布。
##
## 设计尚未定稿（Q5），因此这里做成纯数据表，逻辑等 MS3 再写。
## 目前只保证：改这张表不需要改任何代码。

## 一条涌现规则。
class Rule extends Resource:
	## 尸体基础价值区间 [min, max)，命中则采用本条规则。
	@export var base_value_min: int = 0
	@export var base_value_max: int = 999999
	## 总价值倍率——喷出来的钱总和 = 尸体基础价值 × 本倍率。
	@export var value_multiplier: float = 1.5
	## 涌现的币数。
	@export var coin_count: int = 8
	## 品质权重，与 qualities 数组一一对应（权重 0 表示不出现）。
	@export var quality_weights: PackedFloat32Array = PackedFloat32Array([1.0])
	## 向外抛射的初速度范围（米/秒）。
	@export var eject_speed_min: float = 3.0
	@export var eject_speed_max: float = 7.0

## 可选品质列表，索引与 Rule.quality_weights 对应。
@export var qualities: Array[CoinQuality] = []
## 规则列表，按顺序匹配，第一条命中即用。
@export var rules: Array[Rule] = []

## 查询：给定尸体基础价值，返回应该采用的规则。找不到则返回 null。
func resolve_rule(corpse_value: int) -> Rule:
	for rule in rules:
		if corpse_value >= rule.base_value_min and corpse_value < rule.base_value_max:
			return rule
	return null
