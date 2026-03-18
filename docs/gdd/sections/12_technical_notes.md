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
  - 基类脚本：`res://scripts/bullets/BulletBase.gd`（提供 `damage/speed/direction` 等通用属性与基础移动逻辑）。
  - 玩家基础子弹：场景 `res://scenes/bullets/PlayerBullet.tscn`，脚本 `res://scripts/bullets/PlayerBullet.gd`（直线向上、不穿透）。
  - 玩家弓箭子弹：场景 `res://scenes/bullets/PlayerArrow.tscn`，脚本 `res://scripts/bullets/PlayerArrow.gd`。
  - 玩家回旋镖：`PlayerBoomerang` **重写 `area_entered`**，命中只伤不 `queue_free`；`boomerang_multi` 解锁与齐射 +1。
  - 符卡爆发弹幕：`PlayerSpellBullet.tscn`（遇 `enemy_bullet` 只清该弹、不全场清弹）；主武器仍 `PlayerBullet.tscn`。
  - **弓箭**：`_on_area_entered` 遇 `enemy_bullet` 只清弹；炸弹仅爆炸 AoE 清弹；炸弹弹速倍率高于旧版。
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

## Mod API（一期：Hook 优先）

### 目标

- 在不破坏现有战斗流程的前提下，为 Mod 提供稳定扩展点：敌人生成、武器行为、升级池。
- 一期保持“原逻辑可独立运行”，Mod 仅作为增量注入，失败时不应导致对局中断。

### 生命周期与入口

- Mod 通过 Godot Mod Loader 加载后，可调用游戏侧扩展桥接口（`ModExtensionBridge`）。
- 游戏关键节点在运行时向扩展桥抛出事件负载（payload），Mod 可读写约定字段并返回结果。
- 同一事件允许多个 Mod 参与，按 Mod Loader 的加载顺序执行。

### 事件约定（一期）

- 敌人生成：
  - `before_enemy_select`：输入 `wave/threat_tier/extension_index`，可建议 `scene` 或 `enemy_id`。
  - `after_enemy_select`：输入主流程已选结果，Mod 可替换或取消本次生成。
- 武器流程：
  - `before_main_shot`：可修改本次主武器发射参数，或附加额外发射请求。
  - `after_main_shot`：用于特效、追踪统计、触发后处理。
  - `process_mod_weapons`：每帧（或固定节奏）驱动 Mod 自定义副武器逻辑。
- 升级流程：
  - `collect_upgrade_entries`：注入可进入三选一的升级条目（`id/name/desc`）。
  - `apply_upgrade_effect`：当内建逻辑未命中时，尝试交由 Mod 执行升级效果。

### 数据与安全约束

- 注册类数据（如敌人、升级）必须具备唯一 `id`；重复 `id` 采用“拒绝并告警”策略。
- 资源路径无效、字段缺失、类型错误时，跳过该条目并记录日志。
- Mod 抛错隔离：单个 Mod 回调异常只影响该回调，不影响主流程和其他 Mod。

### 验收标准（一期）

- 无 Mod：敌人波次、武器节奏、三选一升级行为与当前版本一致。
- 有 Mod：
  - 可注入至少 1 个敌人并在实战中生成；
  - 可注入至少 1 个升级词条并在三选一出现且可生效；
  - 可通过武器事件在不改原分支的情况下附加 1 次发射行为。

### 二期扩展（Bridge 管理与升级生命周期）

- 在一期能力基础上，补充 Bridge 级别的“可管理性”与“升级生命周期事件”：
  - 事件处理器管理：支持按事件移除单个 handler、清空指定事件 handler、统计事件 handler 数量。
  - 升级生命周期事件：
    - `before_apply_upgrade`：在升级效果应用前触发，可改写 `upgrade_id` 或取消本次应用；
    - `after_apply_upgrade`：在升级处理结束后触发，用于统计、日志、附加后处理。

#### 二期事件约定

- `before_apply_upgrade` 输入字段：
  - `player`
  - `upgrade_id`
  - `cancel`（默认 `false`）
- `before_apply_upgrade` 可写字段：
  - `upgrade_id`：允许重定向到其他升级 ID
  - `cancel`：置 `true` 直接取消本次升级应用
- `after_apply_upgrade` 输入字段：
  - `player`
  - `original_upgrade_id`
  - `resolved_upgrade_id`
  - `applied`（是否成功应用）
  - `cancelled`（是否在 before 阶段被取消）

#### 二期验收标准

- 能通过 API 对指定事件完成 handler 注册、移除、清空，并返回可预期结果。
- Mod 可在 `before_apply_upgrade` 中改写升级 ID，且主流程按改写结果执行。
- Mod 可在 `before_apply_upgrade` 中取消升级，且不会触发内建或 Mod 升级效果。
- `after_apply_upgrade` 在“成功应用 / 未命中 / 被取消”三种场景都能收到准确状态字段。

### 三期目标（纯 Mod 驱动核心）

- 目标：武器、敌人、升级的“内容定义与效果实现”全部由 Mod 提供，主工程仅保留战斗流程壳与调度能力。
- 迁移方式：一次性切换（big-bang），并将当前内置内容封装为 `builtin core mod`。

#### 三期架构约束

- 主工程保留：
  - 战斗主循环与波次时序；
  - 玩家、敌人实例化时机与生命周期管理；
  - UI 展示与结算框架；
  - Mod Bridge 注册、校验、分发机制。
- 主工程移除：
  - 具体武器/敌人/升级条目与数值硬编码；
  - 具体升级效果实现分支（改为由 Bridge 调用 Mod 处理器）。
- 内容来源：
  - `builtin core mod`（项目内默认提供）负责注册当前基线内容；
  - 外部 Mod 在此基础上新增或覆盖。

#### 冲突与覆盖策略（三期）

- `id` 唯一：同一注册表内（武器/敌人/升级）默认拒绝重复 ID，并输出告警。
- 覆盖策略：若需要覆盖，必须显式走“卸载旧条目 + 注册新条目”或专用覆盖接口（后续统一）。
- 缺失回退：关键内容缺失时，主流程不得崩溃；应记录日志并跳过该条目。

#### 三期验收标准

- 无外部 Mod 时，仅依赖 `builtin core mod` 即可完整进行一局战斗（刷怪、射击、升级、生效、结算）。
- 外部 Mod 可独立新增至少 1 个敌人、1 个武器行为、1 个升级并在实战生效。
- 混合加载（builtin + external）时不出现重复 ID 导致的崩溃，冲突有可读日志。

### 三期收敛（去适配壳重构）

- 目标：在三期纯 Mod 驱动基础上，进一步移除主工程中的“过渡适配壳”，把升级应用生命周期统一收敛到 Bridge。

#### 收敛范围

- 删除/下线过渡适配层：
  - `PlayerUpgradeEffectsService`
  - `MainUpgradeEffectsService`
- 主流程改造：
  - `UpgradeManager` 直接调用 Bridge 的统一升级应用入口。
  - `Player.apply_upgrade` 直接调用 Bridge 的统一升级应用入口。
- 配置归属收敛：
  - 内置核心 Mod 使用自身目录配置（`mods-unpacked/planewar-core_mod`），不再依赖主工程 `scripts/config`。

#### 三期收敛验收标准

- 主工程中不再依赖玩家/主场景升级适配服务壳。
- 升级应用前后事件（player/main）都由 Bridge 统一触发并返回一致字段。
- 内置核心 Mod 在不读取 `scripts/config` 的前提下，仍可完整复现基线战斗内容。

