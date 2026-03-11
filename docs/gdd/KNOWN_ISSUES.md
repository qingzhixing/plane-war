# 已知问题记录（临时）

- ~~**HP HUD（心形图标）**~~（已处理）
  - 处理：根 Control 使用 PRESET_FULL_RECT 铺满视口；HBox 锚在右上角并用 offset 精确定位；用 `is_instance_valid(_player)` 与 `clampi(get_hp(), 0, max_icons)` 保证显示个数正确。

- ~~**玩家移动偶发卡顿**~~（已处理）
  - 处理：单帧拖拽位移限制在 120px 内，避免触摸抖动造成大跳；clamp 后把 `_pointer_pos` 同步为当前屏幕坐标，避免与下一帧拖拽冲突。

