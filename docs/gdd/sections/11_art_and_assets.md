# 11 占位美术与资源约定

## 占位美术策略（MVP 阶段）

- **不等待最终美术即可开发**：优先使用占位资源完成玩法和逻辑。
- 玩家、敌人、子弹等均可使用简单的几何/纯色贴图，占位后可无损替换。

## 推荐占位资源形式（Godot 4）

- 玩家飞机：`Sprite2D` 使用简易 PNG（例如 32×32 带朝上的箭头或飞船轮廓）。
- 敌人：`Sprite2D` 使用不同颜色/形状的方块或简单敌机图标。
- 子弹：`Sprite2D` 使用小圆点/短线（例如 8×8）。
- 碰撞：`CollisionShape2D` 尽量接近视觉大小，后续替换贴图时一并微调。

## 命名与目录建议

- 目录建议：
  - `res://art/placeholders/player/`
  - `res://art/placeholders/enemies/`
  - `res://art/placeholders/bullets/`
- 资源命名建议：
  - 玩家：`player_ship_placeholder.png`
  - 敌人：`enemy_basic_placeholder.png` 等
  - 子弹：`bullet_basic_placeholder.png`

> 后续有正式美术资源时，可在保持路径和节点结构基本不变的前提下替换贴图，减少代码影响。

