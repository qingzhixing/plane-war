## 项目结构与模块梳理

本节概述当前 Godot 工程的主要场景、脚本与单例，后续重构会在此基础上逐步引入状态管理、服务与数据驱动配置。

### 场景结构（Scenes）

- `scenes/MainMenu.tscn`：主菜单与关于 / 成绩查询 / 设置入口。
- `scenes/Main.tscn`：战斗主场景，挂载 `scripts/main.gd` 管理波次、升级与记录。
- `scenes/Player.tscn`：玩家实体与拖拽控制。
- `scenes/enemies/*.tscn`：普通敌人与 Boss 场景（如 `EnemyBasic01.tscn`, `EnemyElite01.tscn`, `Boss01.tscn`）。
- `scenes/bullets/*.tscn`：玩家与敌人子弹 / 符卡 / 副武器等弹体场景。
- `scenes/ui/*.tscn`：HUD 组件与 UI 控件（如 `SpellStarButton.tscn`, `StatusSlot.tscn`）。
- `scenes/vfx/*.tscn`：擦弹、玩家护盾、命中特效等视觉反馈。

### 脚本结构（Scripts）

- 核心战斗逻辑：
  - `scripts/main.gd`：管理波次、Boss 刷新、经验与升级、成绩记录与续战流程。
  - `scripts/player.gd`：玩家移动、射击与升级应用。
  - `scripts/enemy_spawner.gd`：敌人刷怪逻辑。
  - `scripts/enemies/EnemyBase.gd`：敌人基类与受击 / 死亡接口。
- 子弹与武器：
  - `scripts/bullets/BulletBase.gd` 及各类玩家子弹（`PlayerBullet.gd`, `PlayerArrow.gd`, `PlayerBomb.gd`, `PlayerBoomerang.gd`, `PlayerSpellBullet.gd`）。
- HUD 与 UI：
  - `scripts/hud.gd`：战斗 HUD，显示生命 / 分数 / 连击 / DPS 等。
  - `scripts/ui/spell_star_button.gd`、`scripts/ui/side_weapon_cd_slot.gd` 等 UI 组件。
- 菜单与面板：
  - `scripts/main_menu.gd`：主菜单逻辑。
  - `scripts/settings_ui.gd`：设置面板。
  - `scripts/records_query_ui.gd`：成绩查询。
  - `scripts/about_ui.gd`：关于 / 更新日志面板。
  - `scripts/upgrade_ui.gd`：升级三选一 UI。
  - `scripts/post_boss_choice.gd`：Boss 后继续游玩 / 结算选择。
- 辅助与特效：
  - `scripts/graze_spark.gd`, `scripts/hit_judgement_visual.gd` 等 VFX 与调试脚本。

### 单例与配置（Autoload & Config）

- `AudioManager`（`scripts/audio_manager.gd`）通过 autoload 提供全局音频播放服务。
- `SettingsService`（`scripts/systems/settings_service.gd`）统一读写 `user://settings.cfg` 中的附加设置（如震动、画面缩放）。
- `project.godot` 中配置窗口拉伸（`viewport` + `keep`）、基准分辨率 `720×1280`，主场景为 `MainMenu.tscn`。
- 本地成绩存储在 `user://records.cfg`，由 `scripts/systems/records_service.gd` 统一读写，`main.gd` 与成绩查询面板复用该服务。
