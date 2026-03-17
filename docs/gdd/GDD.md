# GDD（Game Design Document）- 目录（可维护拆分版）

> 入口文件：按主题拆分，便于多人协作与长期维护。  
> 说明：所有章节默认面向 **Demo/MVP**；后续扩展在各自章节追加“后续规划”小节即可。

## 文档结构

- `docs/gdd/sections/01_overview.md`：概览与设计目标
- `docs/gdd/sections/02_platform_and_ci.md`：跨平台目标与发布方式（手动/可选 CI）
- `docs/gdd/sections/03_core_loop_and_controls.md`：核心循环、失败与继续、输入与手感
- `docs/gdd/sections/04_numbers_and_combat_rules.md`：数值框架、受击/判定、战斗规则
- `docs/gdd/sections/05_level_structure.md`：2–5 分钟波次制关卡结构与可读性原则
- `docs/gdd/sections/05_level_structure_post_boss.md`：Boss 后继续挑战与威胁等级
- `docs/gdd/sections/06_enemies_and_boss.md`：敌人/精英/Boss 模板
- `docs/gdd/sections/07_roguelite_upgrades.md`：升级三选一与强化池分类（MVP）
- `docs/gdd/sections/08_ui_ux.md`：UI/UX 流程与界面清单
- `docs/gdd/sections/09_audio_and_feedback.md`：音频、打击感与反馈
- `docs/gdd/sections/10_mvp_acceptance_and_milestones.md`：MVP 验收与里程碑
- `docs/gdd/sections/11_art_and_assets.md`：占位美术与资源命名约定
- `docs/gdd/sections/12_technical_notes.md`：技术栈与项目结构（Godot 4）
- `docs/gdd/sections/13_release_and_metadata.md`：版本发布信息与检查清单

## 快速摘要（当前已确认需求）

- **平台**：Windows + Android（跨平台）
- **引擎**：Godot 4（CI 细节依赖具体导出配置）
- **画面**：像素风；参考东方氛围但弹幕更少更简单
- **操作**：竖屏、单手拖拽移动、自动射击
- **局内**：波次制 → **主线第 8 波 Boss**；Boss 后可 **续战块（每块 8 波：7 波小怪 + 第 8 波 Boss；每波结束升级；Boss 后询问接着玩或结算）** + 威胁递增
- **局外**：Demo 阶段不做永久养成，仅记录本地最高表现（如最高得分 / 最高 DPS 等）
- **容错与惩罚方向**：玩家采用**离散生命值系统（2 条命）**：  
  - 每局固定 2 条命，不随升级改变；  
  - 受击时优先结算护盾等防御效果，若未防护则扣除 1 条命并进入短暂无敌；  
  - 当生命归零（Life = 0）时**立即结束本局并进入结算**；  
  - 每当一波战斗清场并进入升级结算时，若当前生命小于上限 2，则自动恢复 1 条命（不超过 2 条命）；  
  - 惩罚仍主要通过**连击断掉、评分加成下降**来体现，鼓励“多打几次刷更高分”而非频繁被踢回标题。

## 战斗评价与评分概览

- **战斗结果以评分为核心**：每局结束时根据玩家的击杀数、造成伤害、连击表现与通关速度，给出总评分。
- **生命与受击规则（2 条命 + 评分导向）**：
  - 玩家拥有固定 2 条命；受击在结算护盾等防御后，若仍命中则扣除 1 条命并触发短暂无敌或硬直等反馈；
  - 当本次受击后生命仍大于 0 时，玩家可以继续战斗，但当前连击会被惩罚性衰减，导致评分加成下降；
  - 当生命归零（Life = 0）时，**本次受击结算完成后立即结束本局并进入结算界面**；
  - 设计目标仍是鼓励玩家在**有限生命**内尽量不被击中，以维持高连击与高评分，而不是频繁被“一击秒杀”踢回标题。
- **DPS 统计**：
  - 局内实时计算一段时间窗口内的伤害输出（例如最近 5 秒），并展示当前 DPS 与当局最高 DPS。
  - 关卡结束时展示本局最高 DPS，并可与历史最高 DPS（本地记录）对比。
- **连击系统**：
  - 玩家在限定时间窗口内持续命中/击杀敌人会提升连击数，连击数越高，对应的得分加成越大。
  - 长时间未命中或玩家受击会导致连击断掉，清空连击加成。