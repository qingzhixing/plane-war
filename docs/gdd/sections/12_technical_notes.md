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
  - 玩家子弹场景：`res://scenes/bullets/PlayerBullet.tscn`
  - 玩家子弹脚本：`res://scripts/player_bullet.gd`
- 敌人（后续补充）：
  - 敌人基础场景：`res://scenes/enemies/EnemyBasic.tscn`
  - 敌人脚本：`res://scripts/enemy_basic.gd`

## 第一阶段实现目标（代码）

- 在 `Main.tscn` 中实例化玩家：
  - 支持竖屏分辨率下的单指拖拽移动（使用 `InputEventScreenDrag` 等）
  - 自动射击玩家子弹，射速可通过导出变量调节
- 玩家子弹与敌人预留碰撞逻辑接口：
  - 玩家子弹脚本暴露伤害数值
  - 敌人脚本暴露受击与死亡处理方法（MVP 初期可先用日志或简单销毁）

> 后续实现脚本时，应优先遵循上述结构；如需结构调整，请先在本节更新约定，再进行实现变更。

