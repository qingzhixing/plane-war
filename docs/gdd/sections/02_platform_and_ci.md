# 02 平台与发布（跨平台 + GitHub Actions 自动构建）

## 目标平台

- **必须**：Windows（桌面端可玩）
- **必须**：Android（移动端可玩）
- **可扩展**：后续可加入 Web（若性能/输入适配允许）

## 自动构建要求（GitHub Actions）

- **触发**：每次 push / PR 自动构建
- **产物**：
  - Windows：可运行的导出包（zip）
  - Android：APK（Demo 便于安装；如后续上架再做 AAB）
- **交付**：Actions artifacts（或 Release artifacts）可下载验证
- **约束**：
  - 构建流程应可在无交互环境运行
  - Android 签名策略建议分阶段：
    - Demo 阶段：可先使用调试签名
    - 需要稳定升级/安装时：CI 注入 keystore（推荐），避免每次签名变化导致无法覆盖安装

## 当前工程与 CI 约定（已落地）

- **Godot 版本**：4.5（`project.godot` 中 `config/features` 已包含 `"4.5"`）。
- **主场景**：`res://scenes/Main.tscn`（在 `project.godot` 中通过 UID 引用）。
- **窗口分辨率**：竖屏 720×1280，`renderer/rendering_method="mobile"`。

### GitHub Actions CI 约定

- **导出模板获取**：在 CI 中下载安装 Godot 4.5 对应的导出模板（使用官方提供的 Linux headless + export templates 包）。
- **Windows 导出**：
  - 使用 `godot --headless --export-release "Windows Desktop" build/plane-war-windows.exe`。
  - 将生成的 exe 与必要资源打包为 zip，作为 Actions artifact。
- **Android 导出**：
  - 使用调试签名导出 APK：`godot --headless --export-release "Android" build/plane-war-android.apk`。
  - 后续如需稳定升级，再在 CI 中注入 keystore 与签名配置。
- **工作流触发**：`push` 与 `pull_request` 时自动运行构建，产物通过 Actions artifacts 提供下载验证。


