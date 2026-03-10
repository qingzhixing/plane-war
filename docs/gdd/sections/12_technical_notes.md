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
  - 节点类型：`CharacterBody2D` 或 `Area2D` + 自定义移动逻辑
- 敌人与子弹：
  - 敌人：`res://scenes/enemies/EnemyBasic.tscn` 等
  - 子弹：`res://scenes/bullets/PlayerBullet.tscn`、`EnemyBullet.tscn`

> 后续实现脚本时，应优先遵循上述结构；如需结构调整，请先在本节更新约定，再进行实现变更。

