# GDD（Game Design Document）- 目录（可维护拆分版）

> 入口文件：按主题拆分，便于多人协作与长期维护。  
> 说明：所有章节默认面向 **Demo/MVP**；后续扩展在各自章节追加“后续规划”小节即可。

## 文档结构

- `docs/gdd/sections/01_overview.md`：概览与设计目标
- `docs/gdd/sections/02_platform_and_ci.md`：跨平台目标与 GitHub Actions 自动构建要求
- `docs/gdd/sections/03_core_loop_and_controls.md`：核心循环、失败与继续、输入与手感
- `docs/gdd/sections/04_numbers_and_combat_rules.md`：数值框架、受击/判定、战斗规则
- `docs/gdd/sections/05_level_structure.md`：2–5 分钟波次制关卡结构与可读性原则
- `docs/gdd/sections/06_enemies_and_boss.md`：敌人/精英/Boss 模板
- `docs/gdd/sections/07_roguelite_upgrades.md`：升级三选一与强化池分类（MVP）
- `docs/gdd/sections/08_ui_ux.md`：UI/UX 流程与界面清单
- `docs/gdd/sections/09_audio_and_feedback.md`：音频、打击感与反馈
- `docs/gdd/sections/10_mvp_acceptance_and_milestones.md`：MVP 验收与里程碑
- `docs/gdd/sections/11_art_and_assets.md`：占位美术与资源命名约定
- `docs/gdd/sections/12_technical_notes.md`：技术栈与项目结构（Godot 4）

## 快速摘要（当前已确认需求）

- **平台**：Windows + Android（跨平台）
- **引擎**：Godot 4（CI 细节依赖具体导出配置）
- **画面**：像素风；参考东方氛围但弹幕更少更简单
- **操作**：竖屏、单手拖拽移动、自动射击
- **局内**：2–5 分钟波次制 → Boss；升级三选一（pick-3），Boss/精英/炮台的攻击节奏强调**可读前摇**（约 0.7–1.0 秒），保证新手可预判与反应空间；核心反馈从“死亡失败”调整为“评分表现”（高分、高连击、高 DPS）
- **局外**：Demo 阶段不做永久养成，仅记录本地最高表现（如最高得分 / 最高 DPS 等）
- **容错与惩罚方向**：玩家有有限 HP，但 HP 归零**不再直接 Game Over**，而是主要通过**评分降低、连击断掉**来体现惩罚，鼓励“多打几次刷更高分”而非频繁被踢回标题

## 战斗评价与评分概览（新增）

- **战斗结果以评分为核心**：每局结束时根据玩家的击杀数、造成伤害、连击表现与通关速度，给出总评分。
- **玩家不会因为死亡被立刻踢出战斗**：
  - 受击会扣除 HP，并清空当前连击、降低当局表现（例如减少评分加成或记为“危险状态”）。
  - HP 归零时不会直接 Game Over，玩家仍可继续战斗、继续刷新评分，只是很难维持高连击与高 DPS。
- **DPS 统计**：
  - 局内实时计算一段时间窗口内的伤害输出（例如最近 5 秒），并展示当前 DPS 与当局最高 DPS。
  - 关卡结束时展示本局最高 DPS，并可与历史最高 DPS（本地记录）对比。
- **连击系统**：
  - 玩家在限定时间窗口内持续命中/击杀敌人会提升连击数，连击数越高，对应的得分加成越大。
  - 长时间未命中或玩家受击会导致连击断掉，清空连击加成。

