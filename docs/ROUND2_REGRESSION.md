# TODO_ROUND2 回归记录

## 环境

- 引擎：`Godot_v4.6.1-stable_win64_console.exe`
- 启动命令：
  - `Godot_v4.6.1-stable_win64_console.exe --path . --headless --quit-after 240 --log-file <scenario>.log`

## 场景 A：Builtin core mod only

- 方式：在 `user://mod_user_profiles.json` 中将 `demo_mod-mod_api_demo` 设为 `is_active=false`。
- 结果：通过。
- 关键日志：
  - `Initializing -> planewar-core_mod`
  - 未出现 `Initializing -> demo_mod-mod_api_demo`
  - 未出现启动崩溃。

## 场景 B：Builtin core mod + external demo mod

- 方式：在 `user://mod_user_profiles.json` 中将 `demo_mod-mod_api_demo` 设为 `is_active=true`。
- 结果：通过。
- 关键日志：
  - `Initializing -> demo_mod-mod_api_demo`
  - `Initializing -> planewar-core_mod`
  - 未出现启动崩溃。

## 场景 C：重复 ID 冲突

- 方式：临时添加 `conflict_test-mod_conflict`（仅用于本次回归），注册重复 ID：
  - enemy：`builtin.basic`
  - upgrade：`fire_rate`
- 结果：通过（命中预期告警，行为确定）。
- 关键日志：
  - `ModExtensionBridge reject duplicate enemy id: builtin.basic`
  - `ModExtensionBridge reject duplicate upgrade id: fire_rate`
  - 引擎继续运行并正常退出，无崩溃。

## 清理

- 回归后已删除临时冲突 Mod 与场景日志文件。
- `user://mod_user_profiles.json` 已恢复 `demo_mod-mod_api_demo` 为启用状态。
