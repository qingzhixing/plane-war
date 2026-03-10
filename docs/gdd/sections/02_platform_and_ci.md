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

## 待工程落地后需要补齐的信息

> 当前仓库尚未包含 Godot 工程文件（例如 `project.godot`）。
> CI 的具体实现依赖以下信息：

- Godot 主版本（3.x / 4.x）
- 导出模板（Export Templates）的获取方式
- Android：JDK 版本、Android SDK/Build-Tools 版本
- Android：包名（applicationId）、签名（keystore）方案

