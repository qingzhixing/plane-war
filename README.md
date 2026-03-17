# plane-war

竖屏弹幕射击小品：**波次清场 → 三选一强化 → Boss**，以 **评分 / 连击 / DPS** 为核心反馈，采用 **2 条命离散生命值系统**（受击扣命，生命归零时立刻结算本局，且每波结束若未满血会自动恢复 1 命）。  
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
- **惩罚**：玩家拥有固定 **2 条命**；受击在结算护盾后若仍命中则扣 1 命并短暂无敌，生命未归零时可继续战斗但会 **断连击 / 衰减评分加成**，当生命归零（Life = 0）时本局立刻进入结算；每当一波战斗清场并进入升级结算时，若生命未满 2 条会自动恢复 1 命；整体鼓励多打刷高分  
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
| **截图目录** | [`docs/picture/`](docs/picture/)（内含 `.gdignore`，Godot 不导入该目录，避免多余 `.import`） |

---

## 开发者

**qingzhixing** — 欢迎 Issue / PR。

---

## 许可

若仓库根目录未单独放置 `LICENSE`，以仓库内实际声明为准；引用或二次分发前请留意作者授权说明。
