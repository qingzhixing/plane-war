# 12 技术栈与项目结构（Godot 4）

## 技术栈

- 引擎版本：**Godot 4.x**
- **窗口拉伸（全工程统一）**：`project.godot` → Display → Stretch **Mode = viewport**、**Aspect = keep**，基准 **720×1280**。主菜单与 `Main` 同一逻辑：拉伸/放大窗口时整画布等比缩放，避免仅战斗场景缩放而标题界面不缩放。
- 渲染管线：默认（Forward+ 或兼容的移动友好设置，视具体需求调整）
- 平台目标：Windows + Android
- 脚本语言：优先使用 **GDScript**（如需改为 C#，在本节补充说明）

## 项目结构（建议）

- 启动 / 主菜单：`res://scenes/MainMenu.tscn` → 开始游戏后进入 `res://scenes/Main.tscn`；关于页 `AboutUI` + `scripts/about_ui.gd`（`OS.shell_open` 打开 GitHub）。
- **README 截图目录** `docs/picture/` 根下放 **`.gdignore`**（空文件即可），Godot 不再扫描该夹，PNG 仅给仓库/README 用、不生成 `.import`。
- 本地成绩：`user://records.cfg`（`best_score` / `best_combo` / `best_dps`），由 `Main` 结算写入；主菜单「成绩查询」只读同一文件。
- 玩家：
  - 场景：`res://scenes/Player.tscn`
  - 节点类型：`CharacterBody2D`
  - 脚本：`res://scripts/player.gd`
- 子弹：
  - 基类脚本：`res://scripts/bullets/BulletBase.gd`（提供 `damage/speed/direction` 等通用属性与基础移动逻辑）。
  - 玩家基础子弹：场景 `res://scenes/bullets/PlayerBullet.tscn`，脚本 `res://scripts/bullets/PlayerBullet.gd`（直线向上、不穿透）。
  - 玩家弓箭子弹：场景 `res://scenes/bullets/PlayerArrow.tscn`，脚本 `res://scripts/bullets/PlayerArrow.gd`。
  - 玩家回旋镖子弹：场景 `res://scenes/bullets/PlayerBoomerang.tscn`，脚本 `res://scripts/bullets/PlayerBoomerang.gd`。
  - 符卡爆发弹幕：仍使用 `PlayerBullet.tscn` 等多向直线弹。
  - **炸弹副武器**：`PlayerBomb.gd` 第 7 帧除 AoE 外，对爆炸多边形内的 `enemy_bullet` 执行 `queue_free`。
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
  - 护盾使用独立场景 `res://scenes/vfx/PlayerShield.tscn`：`Node2D` + `ColorRect` + Shader（大圈、高亮青白光晕、时间呼吸）。
  - 玩家脚本：`set_combo_guard_shield_visible` / `play_combo_guard_pulse`；Main 在稳态护盾层数变化时同步显示。

## 调试工具（开发/自测）

- **自选升级面板**：战斗中随时打开，从完整列表里点选一项即调用 `Main.apply_upgrade(id)`，**不**经过波次升级流程（不改变 `_waiting_upgrade_choice`）。
- **入口**：仅通过 **设置 →「自选升级（调试）」** 打开；关闭按钮关面板。打开时暂停游戏（`get_tree().paused = true`），面板 `CanvasLayer` 使用 `process_mode = ALWAYS`。
- **发布策略**：可在导出版保留；若需禁用，可移除设置按钮或该节点。

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

