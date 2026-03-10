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
- **局内**：2–5 分钟波次制 → Boss；升级三选一（pick-3）
- **局外**：Demo 阶段不做永久养成
- **容错**：HP=3；HP 归零可“继续游玩”，每局免费 1 次

