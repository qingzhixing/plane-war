# Project TODO

## Split core_mod into basic mods

1. `inventory-coremod`
   - 对现有 `mods-unpacked/planewar-core_mod/mod_main.gd` 做职责切分清单，并搜索全项目 `res://mods-unpacked/planewar-core_mod/` 硬编码引用点（Player/Main/脚本 preload/load、docs）。

2. `define-new-mods`
   - 创建新的 mod 目录与 `manifest.json`：为每个子模定义唯一的 mod_id（namespace/名称），并在 manifest 填写 dependencies 以保证关键注册先后。

3. `split-logic-mod_main`
   - 从 `planewar-core_mod/mod_main.gd` 中抽取：敌人条目注册、敌人生成规则事件、武器条目注册、升级条目注册、升级效果处理器。每个职责落到对应新 mod 的 `mod_main.gd`。

4. `split-assets`
   - 将子弹/敌人/着色器/vfx/config/纹理按上面的“资产承载 mod”移动到新目录；并确保 BulletBase/敌人脚本/shader 的 preload/load 路径改为新目录（避免运行期 File not found）。

5. `update-project-references`
   - 更新主工程引用：`res://scenes/Player.tscn`、`res://scripts/player/player.gd` fallback preload、`res://scenes/Main.tscn` 等所有 scene ext_resource / script preload 路径；同时更新 docs 中 core_mod 路径说明。

6. `remove-old-coremod`
   - 把旧 `planewar-core_mod` 替换为新 mod：从工程与 mod 用户配置中移除旧 mod（或把默认 profile 设为新 mod 集合）。

7. `validate-headless`
   - 用 Godot headless 验证 ModLoader 初始化与 registry 注册无误；再按 `docs/ROUND2_REGRESSION.md` 的三场景跑回归验证（core only / core+demo / conflict）。

