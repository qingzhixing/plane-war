# plane-war

竖屏弹幕射击小品：**波次清场 → 三选一强化 → Boss**，以 **评分 / 连击 / DPS** 为核心反馈（无传统 HP 死亡出局）。  
Godot 4 开发，面向 **Windows / Android**。

<p align="center">
  <img src="docs/picture/Start%20Menu.png" alt="主菜单" width="280" />
  &nbsp;&nbsp;
  <img src="docs/picture/Playing.png" alt="战斗中" width="280" />
  &nbsp;&nbsp;
  <img src="docs/picture/Upgrade.png" alt="升级三选一" width="280" />
</p>

| 主菜单 | 战斗 | 升级三选一 |
|--------|------|------------|

---

## 玩法摘要

- **操作**：单手拖拽移动，自动射击  
- **流程**：多波敌人 → 每波结束 **三选一 Roguelite 强化** → 约第 8 波进入 **Boss**  
- **惩罚**：受击不断命，但会 **断连击**、拉低评分加成；鼓励多打刷高分  
- **局外**：本地记录历史最高 **得分 / 连击 / DPS**（主菜单「成绩查询」）

---

## 运行与导出

- **引擎**：[Godot 4.6](https://godotengine.org/)（项目 `config/features` 含 `4.6`、`Mobile`）  
- **打开工程**：用 Godot 打开本仓库根目录  
- **运行**：主场景为 **`scenes/MainMenu.tscn`**（启动先进主菜单）  
- **导出**：按 Godot 导出预设配置 **Windows / Android / Web** 等（见 `export_presets.cfg`）

---

## 仓库与文档

| 链接 | 说明 |
|------|------|
| **源码** | [github.com/qingzhixing/plane-war](https://github.com/qingzhixing/plane-war) |
| **设计文档** | [`docs/gdd/GDD.md`](docs/gdd/GDD.md) 及 [`docs/gdd/sections/`](docs/gdd/sections/) |
| **截图目录** | [`docs/picture/`](docs/picture/)（README 上图亦在此） |

---

## 开发者

**qingzhixing** — 欢迎 Issue / PR。

---

## 许可

若仓库根目录未单独放置 `LICENSE`，以仓库内实际声明为准；引用或二次分发前请留意作者授权说明。
