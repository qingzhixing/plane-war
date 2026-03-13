# 09 音频与反馈（MVP）

- 命中：小爆炸/闪烁反馈
- 受击：屏幕边缘闪烁 + 轻震（可关）
- 升级：音效 + 极短时间放缓（增强爽感）
- Boss 阶段切换：提示音 + 招式名显示

## 命中与受击视觉反馈（Shader & 粒子）

- **敌人受击变红（Hit Flash）**
  - 表现：敌人被玩家子弹命中（未死亡）时，机体整体快速变红，再在极短时间内恢复原色。
  - 技术实现：
    - 使用 2D `CanvasItem` Shader，对敌人贴图做颜色叠加与闪烁控制。
    - 统一定义 Shader 参数：`hit_strength`（0–1）、`hit_tint`（默认红色）。
    - 敌人基类 `EnemyBase` 在 `apply_damage()` 中短暂将 `hit_strength` 设为 1，然后在若干帧内插值回 0。
  - 约束：Hit Flash 时不改变碰撞判定，仅为纯视觉反馈。

- **擦弹（Graze）**
  - 敌弹 / 敌机在 `GrazeArea` 内重叠时，按 **约 50ms / 目标** 重复加分；不替代中弹判定。
  - **特效**：`GrazeSpark`（`CPUParticles2D`）带 **GradientTexture2D 圆形贴图**，避免 Android GLES 无贴图粒子不显示；`restart()` + deferred 入树；约 90ms / 目标 节流。
  - **绘制顺序**：**玩家 < 擦弹特效 < 子弹**（机体可读 + 擦弹可见；弹幕仍压在最上层）。
  - **颗粒感**：多枚 **偏小、偏硬边** 的粒子（数量↑、单粒 scale↓、渐变边缘收紧），偏「碎屑/星点」而非一大团柔光。
  - **音效**：`assets/SFX/player/Graze.wav`，经 `AudioManager.play_graze()` 播放；SFX 使用 **多路 AudioStreamPlayer 池（约 22 路）**，避免大后期密集触发时同一路被 `play()` 顶断。

- **玩家判定点（Hit Judgement）**
  - 表现：机体中心 **小圆点**（红芯 + 白边），与 `Player` 的 `CollisionShape2D` 同半径、同中心；全程可见（无敌闪烁时可略降透明度或保持可见，按可读性二选一）。
  - 技术：`Player` 子节点 `HitJudgementVisual`（`Node2D` + `_draw`），相对机体略高一层；**整体玩家层仍低于子弹**。

- **玩家受击闪烁（Invincible Blink）**
  - 表现：玩家被敌人或敌弹命中后，短暂无敌期间会整体闪烁（半透明/消失交替），与敌人受击变红区分开。
  - 技术实现：
    - 玩家节点使用简单的 Shader 或 `modulate`/`visible` 切换实现闪烁。
    - 玩家脚本在受击回调中开启“闪烁计时器”，在一定时间内（例如 1 秒）按固定频率改变量或可见性。
  - 约束：闪烁状态下玩家处于“短暂无敌”窗口，防止一帧内多次受击；具体判定逻辑见数值与战斗规则章节。

- **玩家护盾特效**
  - 表现：**稳态护盾（combo_guard）** 有层数时，机体外侧一圈 **完整空心能量环**（整圈落在绘制区域内，避免方形裁切；中心透明；略呼吸）。
  - 命中反馈：
    - 若护盾吸收一次伤害：护盾立即强烈闪光（加亮 + 放大 + 轻微抖动），随后消失。
    - 若护盾仍然存在（例如堆叠护盾的后续设计），则只是短暂闪光，不完全消失。
  - 技术实现：
    - 场景 `PlayerShield.tscn`：根 `Node2D` + 子节点 `ColorRect` + `player_shield.gdshader`（环形渐变 + 可选时间呼吸）。
    - Shader：内圈偏亮白青、外圈可见淡蓝光晕；默认覆盖半径约 **±140px**（随美术可再调）。
    - 可见性由 `set_combo_guard_shield_visible` / 玩家挡伤逻辑控制。

- **子弹命中粒子特效**
  - 表现：
    - 玩家子弹命中敌人时，在命中点播放极短的火花/碎片粒子（不喧宾夺主）。
    - 普通命中使用基础火花；高连击阶段或精英/Boss 可考虑略增强粒子数量与亮度。
  - 技术实现：
    - 使用 `CPUParticles2D` 或 `GPUParticles2D` 预设场景，例如：
      - `res://scenes/vfx/HitSpark.tscn`（玩家子弹命中敌人）。
    - 玩家子弹在确认命中时实例化该粒子场景，放置到命中坐标并自动 `one_shot` 播完后自毁。

- **敌人死亡爆炸特效**
  - 表现：
    - 普通小怪死亡：小型爆炸粒子 + 短暂闪光。
    - 精英/Boss 阶段/部件死亡：更大、更亮的爆炸，叠加少量碎片或烟雾。
  - 技术实现：
    - 使用独立爆炸粒子场景，例如：
      - `res://scenes/vfx/EnemyExplodeSmall.tscn`
      - `res://scenes/vfx/EnemyExplodeBig.tscn`
    - 敌人基类 `_on_dead()` 负责根据敌人类型选择合适的爆炸特效并实例化。
  - 与音效的联动：
    - 普通爆炸特效播放时，从 `Explosion1–5.ogg` 中随机一个。
    - 精英/Boss 爆炸可叠加更重一点的爆炸音效（后续可新增资源）。

## BGM 策略（全局播放）

- **全局音乐节点**：使用 AutoLoad 单例承载 BGM 播放，不随关卡/场景切换而销毁。
- **暂停行为**：游戏暂停（`Tree.paused = true`）或加载新场景时，BGM 继续播放，不被打断。
- **BGM 池**（首批 4 首）：
  - `assets/BGM/Pixel Wanderer_1.mp3`
  - `assets/BGM/Pixel Wanderer_2.mp3`
  - `assets/BGM/Pixel Rogue Anthem_1.mp3`
  - `assets/BGM/Pixel Rogue Anthem_2.mp3`
- **播放规则**：
  - 每次进入游戏时，从上述 4 首中 **随机洗牌得到播放队列**。
  - 按队列顺序自动连续播放一首接一首；一轮播完后重新洗牌开始下一轮。
  - 失败界面（Game Over）可以短暂压住或停止当前 BGM，播放独立的失败音效。

## SFX 资源清单（当前已导入）

- **敌人受伤音效**
  - 资源：`assets/SFX/enemy/EnemyInjured.ogg`
  - 用途：普通敌人被玩家子弹命中但未死亡时播放一次，加强命中感

- **敌人/物体爆炸音效（随机池）**
  - 资源：
    - `assets/SFX/explode/Explosion1.ogg`
    - `assets/SFX/explode/Explosion2.ogg`
    - `assets/SFX/explode/Explosion3.ogg`
    - `assets/SFX/explode/Explosion4.ogg`
    - `assets/SFX/explode/Explosion5.ogg`
  - 用途：
    - 敌人死亡爆炸时，从上述 5 个 Clip 中随机播放 1 个，避免听觉重复
    - 后续可复用在玩家炸弹、场景可破坏物等爆炸事件

- **失败/游戏结束音效**（可选保留）
  - 资源：`assets/SFX/game_state/Lose.ogg`
  - 用途：当前设计下玩家不会死亡，本音效可留作其他场景（如提前结算、特殊失败条件）或暂不使用。

- **玩家操作与反馈音效（新增）**
  - 资源：
    - `assets/SFX/player/Shoot.wav`
    - `assets/SFX/player/hurt.wav`
    - `assets/SFX/player/power_up.wav`
  - 用途：
    - `Shoot.wav`：玩家自动射击时按节奏播放，强化输出反馈
    - `hurt.wav`：玩家受击或连击中断时播放，提示失误
    - `power_up.wav`：升级三选一确认后播放，强化成长反馈
