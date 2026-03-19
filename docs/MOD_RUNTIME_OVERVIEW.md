# Plane War Mod 加载与运行机制（当前实现）

## 1. 总览

本项目 Mod 机制分为两层：

- **加载层（Godot Mod Loader）**：负责发现、校验、依赖排序、实例化 `mod_main.gd`。
- **扩展层（ModExtensionBridge）**：负责将 Mod 回调接入战斗流程（敌人、武器、升级）。
- **内置核心包（builtin core mod）**：当前基线武器/敌人/升级已迁移到 `mods-unpacked/planewar-core_mod`，主工程仅保留流程壳。

---

## 2. 启动与加载时序

1. 引擎启动后，autoload 先初始化 `ModLoaderStore`，再初始化 `ModLoader`。
2. `ModLoaderStore` 加载 options、CLI 覆盖、日志与缓存。
3. `ModLoader` 扫描 mod 来源并逐个处理：
   - 读取 `manifest.json`
   - 校验 `ModManifest`（字段、版本、依赖、兼容性）
   - 构建 `ModData`（必需文件、目录名匹配、来源判定）
   - zip 模式使用 `load_resource_pack()` 挂载资源包
4. 执行依赖检查，计算加载顺序 `mod_load_order`。
5. 按顺序实例化每个 mod 的 `mod_main.gd` 并挂到 `ModLoader` 节点下。
6. 初始化后处理脚本扩展与场景扩展（若有）。

---

## 3. Mod 来源与目录约定

当前项目会从以下来源收集 mod：

- **解包目录**：`res://mods-unpacked/`（编辑器内总会加载；导出后是否加载取决于 `load_from_unpacked`）
- **本地 zip**：默认 `<游戏安装目录>/mods/*.zip`
- **Steam Workshop**：可选来源，取决于配置

> 说明：`<游戏安装目录>/mods` 的本地来源是按 zip 收集，不会扫描该目录下的解压子目录。

---

## 4. Mod 包最小结构

一个可加载 Mod 至少需要：

- `manifest.json`
- `mod_main.gd`

并要求目录名与 `manifest` 的 `namespace-name` 一致（如 `demo_mod-mod_api_demo`）。

---

## 5. 运行时扩展机制（ModExtensionBridge）

### 5.1 事件扩展点

- `before_enemy_select`
- `after_enemy_select`
- `before_main_shot`
- `after_main_shot`
- `process_mod_weapons`
- `collect_upgrade_entries`
- `before_apply_upgrade`
- `after_apply_upgrade`
- `before_apply_main_upgrade`
- `after_apply_main_upgrade`

事件通过 payload 字典传递；handler 可返回字典覆盖字段。

### 5.2 注册表扩展点

- `register_enemy_entry(enemy_id, entry)`
- `register_upgrade_entry(upgrade, direct_combat=false)`
- `register_weapon_entry(weapon_id, entry)`
- `register_upgrade_effect_handler(handler)`
- `register_main_upgrade_effect_handler(handler)`
- `register_upgrade_alias(alias_id, target_id)`
- `register_enemy_entry(..., replace_existing=true/false)`
- `register_weapon_entry(..., replace_existing=true/false)`
- `register_upgrade_entry(..., replace_existing=true/false)`
- `unregister_enemy_entry(enemy_id)`
- `unregister_weapon_entry(weapon_id)`
- `unregister_upgrade_entry(upgrade_id)`
- `clear_enemy_registry() / clear_weapon_registry() / clear_upgrade_registry()`
- `get_registered_enemy_entries() / get_weapon_entries() / get_registered_upgrades()`
- `unregister_event_handler(event_name, handler)`
- `clear_event_handlers(event_name = "")`
- `get_event_handler_count(event_name)`
- `get_registry_stats()`

`get_registry_stats().events` 表示“当前有处理器的事件名数量”，不是处理器总数。

---

## 6. 游戏内接入点

- **敌人生成**：`EnemySpawner` 已移除内建敌人硬编码，默认从 Bridge 注册表与事件结果决定最终敌人。
- **主武器发射**：`Player` 在发射前后派发事件，并优先尝试按 Bridge `weapon entry` 生成发射请求。
- **升级池合并**：`UpgradeService` 直接消费 Bridge 已注册升级（无本地默认升级常量）。
- **升级效果执行**：主流程通过 `ModExtensionBridge` 统一升级入口分发（支持 player/main 的前后生命周期事件）。

---

## 7. 内置核心 Mod 与示例

- 内置核心内容包：`mods-unpacked/planewar-core_mod`
  - 注册基线敌人、武器条目、升级条目、别名、主/玩家升级效果处理器。
  - 使用自身配置文件（`config/upgrade_effects.json`、`config/enemy_spawn_config.json`），不依赖 `scripts/config`。
  - 作为“无外部 Mod”时的默认内容来源。
- 示例扩展包：`mods-unpacked/demo_mod-mod_api_demo`
  - 展示第三方 Mod 如何注入额外敌人、升级与武器事件。

---

## 8. 回归验证建议

建议每次改动后至少执行三组场景：

1. **仅 builtin core mod**：禁用 `demo_mod-mod_api_demo`，确认核心战斗完整可玩。
2. **builtin + demo mod**：启用 `demo_mod-mod_api_demo`，确认 demo 升级/附加发射生效。
3. **重复 ID 冲突**：准备冲突测试 Mod，确认重复注册被拒绝并输出稳定告警。

---

## 9. 验证与排障建议

1. 启动后查看 `ModLoader` 日志是否有：
   - mod 被发现
   - manifest 校验通过
   - mod 初始化完成
2. 若“加载成功但无效果”，检查：
   - `mod_main.gd` 是否注册了事件或条目
   - `id` 是否重复被拒绝
   - payload 字段名与类型是否符合桥接约定
3. 若“完全未加载”，优先检查：
   - 路径来源是否正确（安装目录 `mods`、是否使用 zip）
   - 目录名是否匹配 `namespace-name`
   - `manifest.json` 必填字段是否完整
