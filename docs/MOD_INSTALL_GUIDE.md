# Plane War Mod 安装说明（导出版）

本文面向玩家，说明如何在导出后的游戏中安装和启用 Mod。

## 前提条件

- 你使用的是包含 Godot Mod Loader 的游戏版本。

## 一、找到 Mod 目录

导出版默认从**游戏安装目录**下的 `mods` 文件夹读取 Mod。

如果你不确定具体位置，可以：

1. 打开游戏可执行文件所在目录（例如 `PlaneWar.exe` 所在目录）。
2. 在同级创建 `mods` 文件夹（如果还没有）。
3. 最终结构应类似：`<游戏安装目录>/mods/`

## 二、准备 Mod 文件

一个 Mod 至少需要下面两个文件：

- `manifest.json`
- `mod_main.gd`

推荐目录命名格式：

- `<namespace>-<mod_name>`

例如：

- `demo_mod-mod_api_demo`

## 三、安装方式

导出版默认从安装目录下的 `mods` 读取 **zip 包**，推荐方式如下：

- **方式 A：zip 压缩包（发布推荐）**
  - 直接将 Mod zip 放入 `mods` 目录（如 `mods/your_mod.zip`）

> 说明：当前导出版本地 `mods` 来源按 zip 扫描，不会读取该目录下的解压子目录。
> 若你是开发者并在编辑器调试，可使用项目内 `res://mods-unpacked/` 目录进行解包调试。

安装后重启游戏即可生效。

## 四、快速验证是否生效

启动游戏后观察日志输出，确认是否出现 mod 被发现、加载、初始化等信息。  
如果你的 Mod 使用了游戏扩展桥 API（如敌人/武器/升级注册），还可以在战斗中验证行为是否已变化。

## 五、常见问题排查

- **看不到 Mod 生效**
  - 检查 `manifest.json` 是否有效 JSON，且必填字段完整。
  - 检查目录结构是否正确（`manifest.json` 与 `mod_main.gd` 在同一层）。
  - 检查 `namespace/name/version` 是否符合规范。
- **启动时报兼容性警告**
  - 检查 `manifest.json` 中 `compatible_mod_loader_version` 和 `compatible_game_version`。
- **Mod 加载了但功能没变化**
  - 确认 `mod_main.gd` 里确实调用了注册接口（如 `register_enemy_entry`、`register_upgrade_entry`、`register_event_handler`）。
  - 查看日志是否有重复 ID 或无效字段告警。

## 六、给作者的发布建议

- 发布给玩家时优先提供 zip 包。
- 在 Mod 说明中明确：
  - 支持的游戏版本
  - 支持的 Mod Loader 版本
  - 是否与其他 Mod 冲突
  - 安装目录和卸载方式

## 七、依赖边界规则（作者必读）

- Mod 允许依赖桥接 API：`res://scripts/systems/mod_extension_bridge.gd`。
- Mod 不应依赖主程序业务资源（例如 `res://scenes/**`、`res://scripts/**` 的具体玩法实现）。
- Mod 之间禁止互相路径依赖：不要引用 `res://mods-unpacked/<other_mod>/...`。
- HUD 图标请通过 bridge 注册（`register_hud_icon`），不要让主程序去硬编码读取某个 mod 的贴图路径。

建议在发布前运行边界检查脚本（仓库内）：

- `res://scripts/tools/check_mod_boundaries.gd`
