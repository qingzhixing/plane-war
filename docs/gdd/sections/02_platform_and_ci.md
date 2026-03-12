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

## 当前工程与 CI 约定（仅保留约定，不写死实现）

- **Godot 版本约定**：统一使用同一大版本（4.x），具体子版本由工程配置与 CI 工作流保持一致。
- **主场景约定**：游戏有一个固定的主场景入口（例如 `Main`），在项目配置与 CI 中应保持一致引用。
- **分辨率与渲染约定**：竖屏 720×1280 为目标设计分辨率，渲染采用适合移动端的模式（如移动优化管线），具体开关由工程配置决定。

### GitHub Actions CI 约定（抽象）

- **导出模板获取**：CI 需要自动安装对应 Godot 版本的导出模板（headless + export templates），避免手动干预。
- **Windows 导出**：
  - CI 中应导出一个可在 Windows 上直接运行的构建产物（例如 exe + 必要资源的压缩包）。
- **Android 导出**：
  - CI 中应能生成可安装到设备上的 APK（或后续 AAB），并预留可替换签名配置的能力。
- **工作流触发**：`push` 与 `pull_request` 时自动运行构建，将产物作为 CI artifacts 提供下载验证。


