# 12 技术栈与项目结构（Godot 4）

## 技术栈

- 引擎版本：**Godot 4.x**
- 渲染管线：默认（Forward+ 或兼容的移动友好设置，视具体需求调整）
- 平台目标：Windows + Android
- 脚本语言：优先使用 **GDScript**（如需改为 C#，在本节补充说明）

## 项目结构（建议）

- 主场景：`res://scenes/Main.tscn`
- 玩家：
  - 场景：`res://scenes/Player.tscn`
  - 节点类型：`CharacterBody2D`
  - 脚本：`res://scripts/player.gd`
- 子弹：
  - 基类脚本：`res://scripts/bullets/BulletBase.gd`（提供 `damage/speed/direction` 等通用属性与基础移动逻辑）。
  - 玩家基础子弹：场景 `res://scenes/bullets/PlayerBullet.tscn`，脚本 `res://scripts/bullets/PlayerBullet.gd`（直线向上、不穿透）。
  - 玩家弓箭子弹：场景 `res://scenes/bullets/PlayerArrow.tscn`，脚本 `res://scripts/bullets/PlayerArrow.gd`。
  - 玩家回旋镖子弹：场景 `res://scenes/bullets/PlayerBoomerang.tscn`，脚本 `res://scripts/bullets/PlayerBoomerang.gd`。
  - 技能/炸弹相关弹幕可以复用 `BulletBase`，使用单独场景（如 `PlayerBombBullet.tscn`）与脚本按需扩展。
- 敌人：
  - 基类脚本：`res://scripts/enemies/EnemyBase.gd`（提供 `max_hp/hp` 与 `apply_damage/_on_dead` 等统一接口）。
  - 基础敌人场景可继续使用如 `res://scenes/enemies/EnemyBasic01.tscn`、`EnemyBasic02.tscn` 等，脚本统一继承 `EnemyBase` 来实现各自的移动与攻击逻辑。

## 视觉反馈与 Shader 约定

- 敌人受击 Shader：
  - 统一使用 2D `CanvasItem` Shader，实现受击时的变红效果。
  - Shader 参数约定：
    - `uniform float hit_strength`：受击强度（0–1），由代码控制；0 为正常状态，1 为全红。
    - `uniform vec4 hit_tint`：受击染色颜色，默认红色（如 `vec4(1.0, 0.2, 0.2, 1.0)`）。
  - `EnemyBase` 在 `apply_damage()` 中触发一个短暂的 hit 动画（可用 Tween 或 Process 插值），不改变碰撞逻辑。

- 玩家闪烁与护盾：
  - 玩家受击后的闪烁使用简单方式实现（Shader 或 `modulate`/`visible` 控制），重点是节奏感与可读性。
  - 护盾使用独立场景（例如 `res://scenes/vfx/PlayerShield.tscn`），包含：
    - 护盾 `Sprite2D` + Shader（外圈光晕、轻微扭曲）。
    - 控制脚本暴露方法：`show_shield() / hide_shield() / play_block_effect()`。
  - 玩家脚本持有护盾节点引用，在获得护盾时显示，在护盾抵消一次伤害时调用 `play_block_effect()` 并视规则决定是否隐藏。

## 第一阶段实现目标（代码）

- 在 `Main.tscn` 中实例化玩家：
  - 支持竖屏分辨率下的单指拖拽移动（使用 `InputEventScreenDrag` 等）
  - 自动射击玩家子弹，射速可通过导出变量调节
- 玩家子弹与敌人预留碰撞逻辑接口：
  - 玩家子弹脚本暴露伤害数值
  - 敌人脚本暴露受击与死亡处理方法（MVP 初期可先用日志或简单销毁）
- 统一版实现方向（后续阶段）：
  - 所有玩家子弹脚本继承 `BulletBase`，在发射时设置 `damage/speed/direction` 等属性。
  - 所有敌人脚本继承 `EnemyBase`，实现 `apply_damage(amount)` 与 `_on_dead()`。
  - 碰撞检测触发时，玩家子弹只调用命中的敌人 `apply_damage(bullet.damage)`，不直接操作敌人 HP；敌人内部根据 HP 变化决定是否播放死亡表现并销毁。

> 后续实现脚本时，应优先遵循上述结构；如需结构调整，请先在本节更新约定，再进行实现变更。

