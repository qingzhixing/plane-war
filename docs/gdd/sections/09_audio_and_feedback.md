# 09 音频与反馈（MVP）

- 命中：小爆炸/闪烁反馈
- 受击：屏幕边缘闪烁 + 轻震（可关）
- 升级：音效 + 极短时间放缓（增强爽感）
- Boss 阶段切换：提示音 + 招式名显示

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
