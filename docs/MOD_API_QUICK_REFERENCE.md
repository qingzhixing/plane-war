# Plane War Mod API 速查（当前实现）

面向 Mod 作者的快速参考文档。  
本页聚焦当前项目实际可用的扩展点：事件、注册接口、字段约束与最小模板。

---

## 1. 快速上手

在 `mod_main.gd` 中预加载桥接脚本：

```gdscript
extends Node

const ModExtensionBridge = preload("res://scripts/systems/mod_extension_bridge.gd")
```

常见初始化入口：

```gdscript
func _init() -> void:
    # 在这里注册事件/敌人/升级/效果处理器
    pass
```

---

## 2. 事件总览

支持事件（`event_name`）：

- `before_enemy_select`
- `after_enemy_select`
- `before_main_shot`
- `after_main_shot`
- `process_mod_weapons`
- `collect_upgrade_entries`
- `before_apply_upgrade`
- `after_apply_upgrade`
- `before_apply_main_upgrade`
- `after_apply_main_upgrade`

注册方式：

```gdscript
ModExtensionBridge.register_event_handler("before_main_shot", _before_main_shot)
```

回调签名建议统一为：

```gdscript
func _handler(payload: Dictionary) -> Dictionary:
    var out := payload
    # 修改 out
    return out
```

> 回调返回 `Dictionary` 时会 merge 到 payload；返回其他类型会被忽略。

---

## 3. 事件 Payload 约定

### 3.1 `before_enemy_select`

触发点：敌人选择前。  
输入字段（游戏侧提供）：

- `wave: int`
- `effective_wave: int`
- `threat_tier: int`
- `extension_index: int`
- `enemy_id: String`
- `scene: PackedScene`
- `cancel_spawn: bool`

可改字段：

- `scene`（替换敌人场景）
- `enemy_id`（替换 ID）
- `cancel_spawn = true`（取消本次生成）

---

### 3.2 `after_enemy_select`

触发点：敌人最终实例化前。  
字段同 `before_enemy_select`，可继续覆盖 `scene` / `enemy_id` / `cancel_spawn`。

---

### 3.3 `before_main_shot`

触发点：玩家主武器发射前。  
输入字段：

- `player: Node`
- `weapon_mode: String`
- `cancel_default: bool`

常用输出字段：

- `weapon_mode`：改为 `"arrow"` 可走箭矢分支；其他值走默认主弹分支。
- `cancel_default = true`：取消默认发射，只执行你的附加请求。
- `spawn_requests: Array[Dictionary]`：追加子弹生成请求。

`spawn_requests` 每项常用键：

- `scene: PackedScene`（必填）
- `dir: Vector2`（默认 `Vector2.UP`）
- `damage_bonus: float`（默认 `0.0`）
- `speed_mult: float`（默认 `1.0`）
- `penetration: int`（默认 `0`）
- `visual_type: String`（默认 `"bullet"`）
- `motion_mode: String`（默认 `"straight"`）
- `side_offset: Vector2`（默认 `Vector2.ZERO`）

---

### 3.4 `after_main_shot`

触发点：主武器发射后。  
输入字段：

- `player: Node`
- `weapon_mode: String`
- `used_default: bool`

主要用于统计、特效或后处理；当前主流程不读取回写字段。

---

### 3.5 `process_mod_weapons`

触发点：`Player._process(delta)` 每帧。  
输入字段：

- `player: Node`
- `delta: float`

用于驱动自定义副武器/持续效果。  
当前主流程不读取回写字段。

---

### 3.6 `collect_upgrade_entries`

触发点：升级池收集阶段（`UpgradeService.get_all_upgrades()` 内）。  
输入字段：

- `upgrades: Array[Dictionary]`

可返回：

- `upgrades`（数组）用于覆盖/追加最终候选集合。

每个升级条目最低要求：

- `id`（非空字符串）
- `name`
- `desc`

---

### 3.7 `before_apply_upgrade`

触发点：玩家升级应用前。  
输入字段：

- `player: Node`
- `upgrade_id: String`
- `cancel: bool`

常用输出字段：

- `upgrade_id`：可改写为另一个升级 ID（升级重定向）。
- `cancel = true`：取消本次升级应用（不会执行内建效果或 Mod 效果处理器）。

---

### 3.8 `after_apply_upgrade`

触发点：玩家升级处理后。  
输入字段：

- `player: Node`
- `original_upgrade_id: String`
- `resolved_upgrade_id: String`
- `applied: bool`
- `cancelled: bool`

用于统计、日志、成就、联动后处理。

---

### 3.9 `before_apply_main_upgrade`

触发点：Main 侧升级应用前。  
输入字段：

- `main: Node`
- `upgrade_id: String`
- `cancel: bool`

常用输出字段：

- `upgrade_id`：可重定向升级 ID。
- `cancel = true`：取消本次 Main 侧升级应用。

---

### 3.10 `after_apply_main_upgrade`

触发点：Main 侧升级处理后。  
输入字段：

- `main: Node`
- `original_upgrade_id: String`
- `resolved_upgrade_id: String`
- `applied: bool`
- `cancelled: bool`

---

## 4. 注册接口速查

### 4.1 注册敌人

```gdscript
ModExtensionBridge.register_enemy_entry(
    "my_enemy_id",
    {
        "scene": preload("res://mods-unpacked/planewar-enemy_system/scenes/enemies/EnemyElite01.tscn"),
        "weight": 1.0,
        "wave_min": 1,
        "extension_only": false,
    }
)
```

规则：

- `enemy_id` 不能为空，且不可重复。
- 第三个参数 `replace_existing=true` 可覆盖同 ID 旧条目。
- `scene` 必须是 `PackedScene`。
- `weight` 会参与 mod 敌人候选加权。
- `wave_min` 小于当前波次时才可参与。
- `extension_only = true` 仅在续战波次参与。

---

### 4.2 注册升级条目

```gdscript
ModExtensionBridge.register_upgrade_entry(
    {
        "id": "my_upgrade",
        "name": "我的升级",
        "desc": "效果描述",
    },
    true
)
```

第二个参数 `direct_combat` 为 `true` 时，会被标记为直接战斗类升级。
第三个参数 `replace_existing=true` 可覆盖同 ID 旧条目。

---

### 4.3 注册升级效果处理器

```gdscript
ModExtensionBridge.register_upgrade_effect_handler(_apply_upgrade)

func _apply_upgrade(player: Node, upgrade_id: String) -> bool:
    if upgrade_id != "my_upgrade":
        return false
    # 对 player 施加效果
    return true
```

返回 `true` 表示已处理该升级；返回 `false` 表示未处理。

---

### 4.4 升级别名

```gdscript
ModExtensionBridge.register_upgrade_alias("old_id", "new_id")
```

用于把旧升级 ID 映射到新 ID。

---

### 4.5 武器条目注册（已接入）

```gdscript
ModExtensionBridge.register_weapon_entry("my_weapon", {"id": "my_weapon"})
```

当前玩家主武器流程会优先读取该注册表，未命中时再回退到默认发射逻辑。
此外，玩家的副武器（`arrow` / `bomb` / `boomerang`）在自动发射阶段也同样会优先读取该注册表的 `scene` 与生成参数来实例化子弹；未命中时才会回退到内建的默认发射实现。

---

### 4.6 事件处理器管理（二期）

```gdscript
ModExtensionBridge.unregister_event_handler("before_main_shot", _before_main_shot)
ModExtensionBridge.clear_event_handlers("before_main_shot")
ModExtensionBridge.clear_event_handlers() # 清空所有事件处理器
var n := ModExtensionBridge.get_event_handler_count("before_main_shot")
```

适合热更新、切换模式、临时订阅后回收。

---

### 4.7 升级效果处理器管理（二期）

```gdscript
ModExtensionBridge.unregister_upgrade_effect_handler(_apply_upgrade)
ModExtensionBridge.clear_upgrade_effect_handlers()
var n := ModExtensionBridge.get_upgrade_effect_handler_count()
```

用于动态卸载或重新装配升级效果逻辑。

---

### 4.8 Main 升级效果处理器

```gdscript
ModExtensionBridge.register_main_upgrade_effect_handler(_apply_main_upgrade)
ModExtensionBridge.unregister_main_upgrade_effect_handler(_apply_main_upgrade)
ModExtensionBridge.clear_main_upgrade_effect_handlers()
```

处理器签名：

```gdscript
func _apply_main_upgrade(main: Node, upgrade_id: String) -> bool:
    return false
```

---

### 4.9 注册表快照与清理

```gdscript
var stats := ModExtensionBridge.get_registry_stats()
var enemies := ModExtensionBridge.get_registered_enemy_entries()
ModExtensionBridge.clear_enemy_registry()
ModExtensionBridge.clear_weapon_registry()
ModExtensionBridge.clear_upgrade_registry()
```

---

## 5. 最小可运行模板

```gdscript
extends Node

const ModExtensionBridge = preload("res://scripts/systems/mod_extension_bridge.gd")
const MY_UPGRADE_ID := "demo_plus_damage"

func _init() -> void:
    ModExtensionBridge.register_upgrade_entry(
        {
            "id": MY_UPGRADE_ID,
            "name": "改装弹头",
            "desc": "主弹伤害 +2",
        },
        true
    )
    ModExtensionBridge.register_upgrade_effect_handler(_apply_upgrade)
    ModExtensionBridge.register_event_handler("before_main_shot", _before_main_shot)

func _before_main_shot(payload: Dictionary) -> Dictionary:
    var out := payload
    var reqs: Array = out.get("spawn_requests", [])
    reqs.append(
        {
            "scene": preload("res://mods-unpacked/planewar-weapon_system/scenes/bullets/PlayerArrow.tscn"),
            "dir": Vector2(0.0, -1.0),
            "speed_mult": 1.1,
        }
    )
    out["spawn_requests"] = reqs
    return out

func _apply_upgrade(player: Node, upgrade_id: String) -> bool:
    if upgrade_id != MY_UPGRADE_ID:
        return false
    if "bullet_damage" in player:
        player.bullet_damage += 2
        return true
    return false
```

---

## 6. 常见坑位

- 事件名拼错会被拒绝（未知 event）。
- 同一 `id` 重复注册会被拒绝。
- 敌人条目缺少 `scene: PackedScene` 会被拒绝。
- 升级条目缺少 `id/name/desc` 会被拒绝。
- 只在导出版本安装 mod 时，本地 `mods` 来源按 zip 扫描。
