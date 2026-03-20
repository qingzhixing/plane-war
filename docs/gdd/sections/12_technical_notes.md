# 12 技术栈与项目结构（Godot 4）

## 技术栈

- 引擎版本：**Godot 4.x**
- **窗口拉伸（全工程统一）**：`project.godot` → Display → Stretch **Mode = viewport**、**Aspect = keep**，基准 **720×1280**。主菜单与 `Main` 同一逻辑：拉伸/放大窗口时整画布等比缩放，避免仅战斗场景缩放而标题界面不缩放。
- 渲染管线：默认（Forward+ 或兼容的移动友好设置，视具体需求调整）
- 平台目标：Windows + Android
- 脚本语言：优先使用 **GDScript**（如需改为 C#，在本节补充说明）

## 多语言与本地化（Localization）

- **当前目标语言**：简体中文（`zh_CN`）+ 英文（`en`）。
- **实现方式**：
  - 使用 Godot 自带的 `TranslationServer` 与 CSV 翻译表（如 `res://i18n/ui.csv`）；
  - 以当前场景中的中文文案作为「原文键」，CSV 中维护对应的英文翻译；
  - 脚本动态创建的 UI 文本统一使用 `tr("原文")` 包装，便于之后继续扩展语言。
- **语言切换入口**：
  - 在设置菜单中新增「语言 / Language」选项（`OptionButton`），至少提供：
    - 简体中文（`zh_CN`）
    - English（`en`）
  - 切换时调用 `TranslationServer.set_locale(...)`，即时更新当前局内 UI。
- **持久化方案**：
  - 在 `user://settings.cfg` 中新增 `settings/locale` 字段，用于记录玩家上次选择的语言；
  - 启动游戏时先从该字段读取并设置语言；若没有记录，则默认使用简体中文（`zh_CN`，与当前实现一致）。

## 项目结构（建议）

- 启动 / 主菜单：`res://scenes/MainMenu.tscn` → 开始游戏后进入 `res://scenes/Main.tscn`；关于页 `AboutUI` + `scripts/about_ui.gd`（`OS.shell_open` 打开 GitHub）。
- **README 截图目录** `docs/picture/` 根下放 **`.gdignore`**（空文件即可），Godot 不再扫描该夹，PNG 仅给仓库/README 用、不生成 `.import`。
- 本地成绩：`user://records.cfg`（`best_score` / `best_combo` / `best_dps`），由 `Main` 结算写入；主菜单「成绩查询」只读同一文件。
- 玩家：
  - 场景：`res://scenes/Player.tscn`
  - 节点类型：`CharacterBody2D`
  - 脚本：`res://scripts/player/player.gd`
- 子弹：
  - core_mod 子弹实现：`res://mods-unpacked/planewar-core_mod/scenes/bullets/` 与 `res://mods-unpacked/planewar-core_mod/scripts/bullets/`。
  - 玩家基础子弹：`res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerBullet.tscn`。
  - 玩家弓箭子弹：`res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerArrow.tscn`。
  - 玩家回旋镖：`PlayerBoomerang` **重写 `area_entered`**，命中只伤不 `queue_free`；`boomerang_multi` 解锁与齐射 +1。
  - 符卡爆发弹幕：`PlayerSpellBullet.tscn`（遇 `enemy_bullet` 只清该弹、不全场清弹）；主武器仍 `PlayerBullet.tscn`。
  - **弓箭**：`_on_area_entered` 遇 `enemy_bullet` 只清弹；炸弹仅爆炸 AoE 清弹；炸弹弹速倍率高于旧版。
- 敌人：
  - 基类脚本：`res://scripts/enemies/EnemyBase.gd`（提供 `max_hp/hp` 与 `apply_damage/_on_dead` 等统一接口）。
  - core_mod 敌人场景：`res://mods-unpacked/planewar-core_mod/scenes/enemies/`（如 `EnemyBasic01.tscn`、`EnemyBasic02_Turret.tscn`、`EnemyElite01.tscn`）。

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
  - **调试**：局内暂停 → 设置 → **连击+（调试）** `+10/+50/+100/+500` 与 **清零**；对应 `Main.debug_add_combo` / `debug_set_combo`（仅开发验 Buff/HUD）。
  - **跳 Boss（调试）**：主线未进续战时，假升级跳到 **第 8 波 Boss**；已进入 **续战小怪** 或 **续关后待升级** 时，直接 **续战 Boss**（击破后走「一轮结束」面板）。每进入新续战块可再跳一次主线式次数会重置，续战内可反复跳 Boss 关。

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

## Mod API（当前实现）

### 目标

- 当前核心战斗内容由 `builtin core mod` 提供（`mods-unpacked/planewar-core_mod`），主工程负责流程壳与调度。
- 扩展入口统一通过 `ModExtensionBridge`，确保敌人、武器、升级的注册与生命周期一致。
- 由 `core_mod` 实现的功能代码与内容资源（如子弹/敌人场景、对应脚本与配置）应放在 `mods-unpacked/planewar-core_mod` 内，避免继续引用主工程同类实现文件。

### 生命周期与入口

- Mod 由 Godot Mod Loader 加载后，在 `mod_main.gd` 中调用 Bridge 接口注册事件/条目/处理器。
- 运行期由主流程派发事件 payload；Mod 可返回字典覆写字段。
- 同一事件允许多个 Mod 参与，按加载顺序执行。

### 事件约定（当前）

- 敌人生成：
  - `before_enemy_select` 与 `after_enemy_select` 字段：`wave`、`effective_wave`、`threat_tier`、`extension_index`、`enemy_id`、`scene`、`cancel_spawn`。
  - 可改写 `scene` / `enemy_id`，或设置 `cancel_spawn=true` 取消本次生成。
- 武器流程：
  - `before_main_shot`：可改写发射模式、取消默认发射、附加 `spawn_requests`。
  - `after_main_shot`：用于统计与后处理。
  - `process_mod_weapons`：每帧驱动 Mod 副武器。
- 升级流程：
  - `collect_upgrade_entries`：注入升级候选（最低字段 `id/name/desc`）。
  - `before_apply_upgrade` / `after_apply_upgrade`：玩家升级生命周期。
  - `before_apply_main_upgrade` / `after_apply_main_upgrade`：Main 侧升级生命周期。

### 数据与安全约束

- 注册类数据（敌人/武器/升级）必须唯一 `id`；重复 ID 默认拒绝并告警。
- 关键字段缺失或类型错误时，跳过条目并记录日志。
- Mod 回调异常隔离：单个回调失败不应阻断主流程。

### 已完成收敛项

- 过渡壳 `PlayerUpgradeEffectsService` 与 `MainUpgradeEffectsService` 已移除。
- 升级应用生命周期统一走 Bridge。
- 内置核心 Mod 使用自身配置目录，不依赖 `scripts/config`。

### 验收标准（当前）

- 仅加载 builtin core mod：可完整进行战斗（刷怪、射击、升级、生效、结算）。
- 加载 builtin + external mod：可在不改主工程分支下新增敌人/武器行为/升级并实战生效。
- 冲突场景（重复 ID）：行为可预期（拒绝 + 告警），且无启动/运行崩溃。

---

## Mod 管理（仅主菜单）

### 目标
- 在**主菜单**提供独立 **Mod 管理** 入口（专用场景 `res://scenes/ModManager.tscn`），允许玩家对已安装的 Mod 进行启用/禁用。
- **局内设置**不提供 Mod 开关，避免对局中改动加载集。
- 禁用后的 Mod 在**下次游戏启动**不再生效；编辑过程中不中断玩家——**全部改完后**在离开 Mod 管理页返回主菜单时，**若本次会话改过开关**，才**一次性**询问是否立即重启（可选「稍后」，配置已写入，下次启动仍生效）。

### 实现方式
- UI 层通过 ModLoader 提供的用户配置 API 修改启用状态：
  - `ModLoaderUserProfile.disable_mod(mod_id)`
  - `ModLoaderUserProfile.enable_mod(mod_id)`
- 修改结果持久化到 `user://mod_user_profiles.json`。

### UI 行为
- **Mod 管理页**（`scripts/ui/mod_manager.gd`）：
  - 显示 mod_id / mod manifest 的 `name`
  - 提供勾选框表示当前启用状态
  - 对 `is_locked`（锁定）或 `!is_loadable`（无法加载）条目显示不可用状态
  - 切换开关时立即写配置；**不**在每次点击时弹出重启或显示「立即重启」条
  - 点击「返回主菜单」：无改动则直接回主菜单；有改动则弹出确认：立即重启 / 稍后

### 验收标准（Mod 管理）
- 切换某个 Mod 为 disabled 后，关闭游戏并重新启动：
  - 该 Mod 不会再初始化（不再执行其 `mod_main.gd`）
  - 其相关事件/条目注册不会被注入
- 切换并启用回 enabled 后，表现恢复为 ModLoader 正常加载。

### 核心 Mod 与默认加载

- **识别方式**：命名空间（namespace）为 `"planewar"` 的 Mod 被视为核心 Mod。
- **默认加载**：核心 Mod 在游戏启动时自动加载，不受 `enable_mods` 选项影响。
- **不可禁用**：核心 Mod 不能在游戏内被禁用，Mod 管理器中相关条目显示为锁定状态，禁用复选框不可用。
- **加载逻辑**：ModLoader 在初始化时会确保核心 Mod 的 `is_active` 始终为 `true`，并从禁用列表中自动移除核心 Mod 的 ID。
- **核心功能**：当前核心 Mod 包括：
  - `planewar-weapon-system`：武器系统
  - `planewar-enemy-system`：敌人系统
  - `planewar-upgrade-system`：升级系统
- **扩展性**：未来可通过在 manifest 中添加 `"is_core": true` 字段来标记其他核心 Mod，保持向后兼容。

### 开发规范

- **Mod 功能扩展原则**：当需要实现 Mod 相关的功能变更（如核心 Mod 默认加载、锁定等）时，**不得**直接修改 `addons/mod_loader/` 下的插件代码。
- **唯一修改点**：所有 Mod 列表与开关 UI 应集中在 **`scripts/ui/mod_manager.gd`**（及 `ModManager.tscn`）；设置面板 `settings_ui.gd` 不负责 Mod 启用/禁用。
- **理由**：
  - 保持插件原样，便于未来升级 ModLoader 版本。
  - 将游戏特定的逻辑与通用插件解耦。
  - 通过 UI 层控制核心 Mod 的锁定状态，无需侵入插件内部。
- **实现方式**：在 Mod 管理器中，通过检查 Mod 的 `namespace` 属性（可通过 `mod_data.manifest.mod_namespace` 获取）来识别核心 Mod，并强制将对应的复选框设为 `disabled` 与 `button_pressed = true`，同时提供适当的提示文本（如“核心功能，不可禁用”）。



