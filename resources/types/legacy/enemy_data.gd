class_name EnemyData
extends Resource

## 一种生物的全部数值。策划在这里调参即可加新敌种。

@export var id: StringName = &""
@export var display_name: String = "生物"

@export_group("生存")
@export var max_health: float = 30.0
## 受击后的僵直时间（秒），0 表示不僵直（霸体）。
@export var hit_stun: float = 0.15

@export_group("移动")
@export var move_speed: float = 2.5
## 追击时的冲刺速度（可为 0，表示不冲刺）。
@export var charge_speed: float = 0.0
@export var turn_speed: float = 6.0

@export_group("感知与攻击")
## 发现玩家的距离（米）。
@export var detect_radius: float = 12.0
## 脱离追击的距离（米），应大于 detect_radius 以避免反复横跳。
@export var lose_radius: float = 18.0
## 攻击距离（米）。
@export var attack_range: float = 1.6
@export var attack_damage: float = 8.0
## 两次攻击的间隔（秒）。
@export var attack_cooldown: float = 1.2
## 攻击前摇（秒），给玩家反应时间。
@export var attack_windup: float = 0.35

@export_group("尸体")
## 尸体的基础价值——洞据此决定涌现多少币。品质只影响价值，所以这里就是钱。
@export var corpse_value: int = 5
## 尸体存在时长（秒）。先定为可调，默认 30 秒后自动回收。
## 设为 0 或负数表示永不超时（有性能风险，慎用）。
@export var corpse_lifetime: float = 30.0
## 尸体重量——影响玩家扛着它时的移速。1.0 为基准。
@export var corpse_weight: float = 1.0

@export_group("表现占位")
## 占位胶囊体的尺寸，等美术给模型后替换。
@export var placeholder_size: Vector3 = Vector3(0.8, 1.2, 0.8)
@export var placeholder_color: Color = Color(0.6, 0.25, 0.25)
