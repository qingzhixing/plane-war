# 11 美术资源与目录约定

## 应用图标

- 工程图标：`res://icon.svg`（128×128 矢量，竖屏飞机 + 弹幕尾焰；`project.godot` → Application → Icon）。Android 等导出若单独指定 launcher 图标，可与该图一致或再导 PNG。

## 使用正式像素美术

- 本项目 **不再使用占位几何图形作为长期方案**，而是直接使用正式的像素风美术资源。
- 玩家、敌人、子弹等关键元素都需要有清晰的朝向与轮廓，方便阅读弹幕和躲避。

## UI 字体与文本风格

- 默认 UI 字体：使用项目内字体文件 `res://assets/font/JetBrainsMono[wght].ttf` 作为全局 UI 默认字体（通过 `Theme` 资源统一指定）。
- 适用范围：
  - 主菜单、局内 HUD、设置面板、结算界面等所有基于 `Control` 的 UI（无玩家死亡界面）。
  - 动态创建的 UI 控件（例如设置面板中的滑条与按钮）应继承同一 `Theme`，保持字体一致。
- 字号建议：
  - 普通 HUD 文本（分数/连击/DPS 等）：24–32 号。
  - 重要标题与结算信息（例如 Game Over 标题、结算总分）：32–48 号。
  - 按钮文字：不少于 24 号，手机竖屏优先使用 28–32 号，保证触控可读性。

## 资源导入与规格（建议）

- 分辨率：优先使用 16×16 / 32×32 / 48×48 等常见像素尺寸，保持一致的像素密度。
- 朝向约定：玩家与敌人默认朝上或朝下，保持统一（推荐玩家朝上，敌人朝下）。
- 碰撞：`CollisionShape2D` 尽量贴合实际图形大小，可略小于视觉边界以提高手感。
- 可读性：玩家机体在竖屏上高度约占屏幕高度的 **4–6%**，玩家子弹在屏幕上视觉大小约为敌机宽度的 **1/4–1/3**，保证容易看见和命中。

## 命名与目录建议

- 目录建议：
  - `res://assets/sprites/player/`
  - `res://assets/sprites/enemies/`
  - `res://assets/sprites/bullets/`
  - `res://assets/SFX/player/`
  - `res://assets/font/`
- 资源命名建议：
  - 玩家：`player_ship_base.png`
  - 敌人：`enemy_basic_01.png` 等
  - 子弹：`bullet_basic_01.png`

## 本轮新增资源接入约定（MVP）

- 子弹贴图：
  - 玩家子弹优先使用 `res://assets/sprites/bullets/bullet_player_basic.png`
  - 符卡弹幕贴图：`res://assets/sprites/bullets/spell_bullet.png`（与主武器弹区分）
  - 敌方基础子弹优先使用 `res://assets/sprites/bullets/bullet_enemy_basic.png`
  - 符卡/炸弹 UI 默认使用文字或独立单帧图，不直接使用多帧 sprite sheet
- 玩家反馈音效：
  - 开火：`res://assets/SFX/player/Shoot.wav`
  - 受击/失误：`res://assets/SFX/player/hurt.wav`
  - 升级/强化选择：`res://assets/SFX/player/power_up.wav`
- 字体资源：
  - `res://assets/font/PixelOperator8.ttf`
  - `res://assets/font/PixelOperator8-Bold.ttf`
  - `res://assets/font/pixelFont-7-8x14-sproutLands.ttf`

> 新增资源应优先沿用上述目录，避免散落在 `assets/` 根目录导致后续维护困难。
>
> 如需在极早期阶段临时用占位图，只作为开发便捷手段使用，尽快由正式资源替换。
>
