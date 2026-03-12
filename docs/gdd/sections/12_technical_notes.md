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
  - 玩家基础子弹：场景 `res://scenes/bullets/PlayerBulletBasic.tscn`，脚本 `res://scripts/bullets/player_bullet_basic.gd`（直线向上、不穿透）。
  - 玩家弓箭子弹：场景 `res://scenes/bullets/PlayerArrowBullet.tscn`，脚本 `res://scripts/bullets/player_arrow_bullet.gd`（在基类基础上加入轻微追踪逻辑）。
  - 玩家回旋镖子弹：场景 `res://scenes/bullets/PlayerBoomerangBullet.tscn`，脚本 `res://scripts/bullets/player_boomerang_bullet.gd`（在基类基础上加入往返与穿透逻辑，并在实现层面限制场上同屏仅 1 发）。
  - 技能/炸弹相关弹幕可以复用 `BulletBase`，使用单独场景（如 `PlayerBombBullet.tscn`）与脚本按需扩展。
- 敌人：
  - 基类脚本：`res://scripts/enemies/EnemyBase.gd`（提供 `max_hp/hp` 与 `apply_damage/_on_dead` 等统一接口）。
  - 基础敌人场景可继续使用如 `res://scenes/enemies/EnemyBasic01.tscn`、`EnemyBasic02.tscn` 等，脚本统一继承 `EnemyBase` 来实现各自的移动与攻击逻辑。

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

