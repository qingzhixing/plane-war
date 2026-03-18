# Plane War Mod 加载与运行机制（当前实现）

## 1. 总览

本项目 Mod 机制分为两层：

- **加载层（Godot Mod Loader）**：负责发现、校验、依赖排序、实例化 `mod_main.gd`。
- **扩展层（ModExtensionBridge）**：负责将 Mod 回调接入战斗流程（敌人、武器、升级）。

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

事件通过 payload 字典传递；handler 可返回字典覆盖字段。

### 5.2 注册表扩展点

- `register_enemy_entry(enemy_id, entry)`
- `register_upgrade_entry(upgrade, direct_combat=false)`
- `register_weapon_entry(weapon_id, entry)`
- `register_upgrade_effect_handler(handler)`
- `register_upgrade_alias(alias_id, target_id)`
- `unregister_event_handler(event_name, handler)`
- `clear_event_handlers(event_name = "")`
- `get_event_handler_count(event_name)`

---

## 6. 游戏内接入点

- **敌人生成**：`EnemySpawner` 在选敌前后派发事件，并可抽取 mod 敌人条目。
- **主武器发射**：`Player` 在发射前后派发事件，支持取消默认发射与追加自定义发射请求。
- **升级池合并**：`UpgradeCatalog` 合并 Mod 注册升级。
- **升级效果执行**：`PlayerUpgradeEffectsService` 在应用前后派发升级生命周期事件，并在未命中内建升级时交给 Mod handler。

---

## 7. 示例 Mod（demo_mod-mod_api_demo）

示例包含：

- 注入敌人条目（`EnemyElite01`）
- 注入升级条目（`mod_api_demo_damage`）
- 注入升级生效逻辑（玩家子弹伤害 +2）
- 监听主武器事件并追加额外发射请求

---

## 8. 验证与排障建议

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
