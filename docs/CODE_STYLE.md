## 代码风格与命名规范（Godot 4 / GDScript）

本项目采用 **Godot 风格的变体**：类名 PascalCase，脚本 / 变量 / 函数 / 资源多用 snake_case，节点名语义清晰。所有新代码与重构代码都应遵循本规范。

### 1. 通用约定

- **语言**：代码标识符统一使用英文；UI 文案可以使用中文。
- **缩写**：仅保留常用且含义明确的缩写，例如 `hp`, `dps`, `ui`, `cfg`；避免生僻缩写。

### 2. GDScript 命名

- **类名（class_name / 内联类）**
  - 使用 PascalCase，例如：`Player`, `EnemyBase`, `WaveManager`, `UpgradeService`, `HudViewModel`。
- **脚本文件名**
  - 与主类名对应的 snake_case，例如：`player.gd`, `enemy_base.gd`, `wave_manager.gd`。
- **变量 / 函数**
  - 使用 snake_case，例如：`current_hp`, `max_hp`, `apply_damage()`, `spawn_wave()`, `update_combo()`。
  - 布尔变量以 `is_` / `has_` 开头，例如：`is_paused`, `has_shield`, `is_debug_mode_enabled`。
- **常量**
  - 使用全大写 + 下划线，例如：`PLAYER_SPEED_MAX`, `WAVE_COUNT_PER_STAGE`。
- **信号**
  - 使用 snake_case，强调事件含义，例如：`combo_changed`, `life_zero`, `wave_cleared`, `upgrade_picked`。

### 3. 节点与场景命名

- **场景文件（.tscn）**
  - 使用 PascalCase 名称，例如：`MainMenu.tscn`, `Main.tscn`, `Player.tscn`, `EnemyBasic01.tscn`。
- **节点名**
  - UI 与 HUD 节点使用语义化 PascalCase，例如：`StartButton`, `SettingsButton`, `ScoreLabel`, `ComboLabel`, `AboutScroll`。
  - 仅为脚本需要访问的节点设置唯一名称；装饰性节点可保持默认或简短名称。
- **自动加载单例（autoload）**
  - 使用 PascalCase 类名 + snake_case 脚本文件，例如类 `AudioManager` 存放于 `audio_manager.gd`。

### 4. 目录结构（脚本）

- 所有脚本放在 `scripts/` 下，根据职责细分子目录：
  - `scripts/player/`：玩家相关脚本（如 `player.gd`, 玩家碰撞 / 擦弹等）。
  - `scripts/enemies/`：敌人基类与具体敌人逻辑（如 `enemy_base.gd`, `enemy_spawner.gd`）。
  - `scripts/bullets/`：子弹与武器相关脚本（如 `player_bullet.gd`, `player_bomb.gd`）。
  - `scripts/ui/`：HUD 和通用 UI 组件脚本（如 `hud.gd`, `status_slot.gd`, `spell_star_button.gd`）。
  - `scripts/systems/`：全局系统与服务（如 `audio_manager.gd`, `wave_manager.gd`, `upgrade_service.gd`）。

### 5. 代码风格细节

- **缩进与括号**
  - 使用 4 空格缩进，不使用 Tab。
  - `if` / `for` / `match` 等保持一行一条语句，避免多条语句写在同一行。
- **函数长度**
  - 单个函数尽量控制在一个屏幕内（约 40 行以内）；超过时考虑拆分为多个私有辅助函数。
- **早返回**
  - 对错误 / 特殊情况优先使用早返回，例如：
    - `if not is_instance_valid(target): return`
    - `if not visible: return`
- **信号与回调**
  - Godot 连接到脚本的回调（如 `_on_button_pressed`）内部尽量只做一次转发，例如调用 `start_game()` 或 `open_settings_panel()`，避免在回调里堆积业务逻辑。

### 6. 文档与注释

- 注释只解释**意图与约束**，不描述显然的行为。
- 对于重要系统（升级、波次、成绩记录、调试入口等），建议在脚本头部添加简短说明和使用示例。

