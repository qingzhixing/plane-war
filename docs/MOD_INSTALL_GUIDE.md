# Plane War Mod 安装说明（导出版）

本文面向玩家，说明如何在导出后的游戏中安装和启用 Mod。

## 前提条件

- 你使用的是包含 Godot Mod Loader 的游戏版本。
- 已至少启动过一次游戏（用于自动创建用户目录）。

## 一、找到 Mod 目录

导出版默认从 `user://mods` 读取 Mod。  
在 Windows 上通常对应到 `AppData/Roaming/Godot/app_userdata/<你的游戏目录>/mods`。

如果你不确定具体位置，可以：

1. 先运行一次游戏并退出。
2. 在资源管理器中搜索包含 `mods` 的 `app_userdata` 目录。

## 二、准备 Mod 文件

一个 Mod 至少需要下面两个文件：

- `manifest.json`
- `mod_main.gd`

推荐目录命名格式：

- `<namespace>-<mod_name>`

例如：

- `demo_mod-mod_api_demo`

## 三、安装方式

支持以下两种方式（都放到 `mods` 目录里）：

- **方式 A：解压目录（开发调试推荐）**
  - `mods/<namespace>-<mod_name>/manifest.json`
  - `mods/<namespace>-<mod_name>/mod_main.gd`
- **方式 B：zip 压缩包（发布推荐）**
  - 直接将 Mod zip 放入 `mods` 目录

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
