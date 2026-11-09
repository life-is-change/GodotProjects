# Orchard Village · 果园村

Godot 4.6.2 / GDScript / Compatibility。村庄由基础 3D 几何体搭成，包含十字道路、中心广场、六栋房屋、20 棵树和带碰撞的角色。相机为 40° 斜俯视正交投影。

## 启动与操作

在 Godot 项目管理器导入本目录的 `project.godot`，按 F6 可运行当前打开场景，按 F5 运行主场景。也可以在项目根目录运行：

```powershell
& 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe' --path .
```

- **WASD** 沿当前画面的方向行走，房屋和树干会挡住角色。
- **Q / E** 各转动 90°，过渡约 0.34 秒。
- **鼠标滚轮** 拉近或拉远，正交尺寸范围为 9–27。网页端先点一下游戏画布。

## 本地 Web 试玩

在项目根目录执行 `node .\tools\serve-web.cjs`，然后在 Chrome 打开 [本地游戏](http://127.0.0.1:8067/index.html)。服务仅监听本机，关闭服务用 Ctrl+C。

## 重新导出

Godot 的「编辑器 → 管理导出模板」可从 `D:\Godot\Godot_v4.6.2-stable_export_templates.tpz` 安装匹配版本的完整模板。也可使用已安装的 Web 单线程模板。Godot 导出预设名为 `Web`，关闭线程和 GDExtension。导出命令：

```powershell
$godot = 'D:\Godot\Godot_v4.6.2-stable_win64_console.exe'
New-Item -ItemType Directory -Force build/web | Out-Null
& $godot --headless --path . --editor --import
& $godot --headless --path . --export-release Web build/web/index.html
& $godot --headless --path . --script res://tests/regression.gd
```

保留 `build/web` 下同批生成的 HTML、JS、WASM 和 PCK 等文件。用上面的 HTTP 服务打开游戏。

[Godot 4.6 Web 导出文档](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html)

## 药水商店 · Windows 版

从广场走到东北侧标有 RENOVATION 的房屋正门，按 F 或点屏幕下方提示。新档从 150 金币、100/100 生命开始。花 100 金币改造后，店门会出现条纹雨棚、招牌和商人。靠近商人按 F 对话，每瓶生命药水 20 金币。按 B 或点右上状态栏打开背包，使用药水恢复 30 点生命，最多恢复到 100。按 Esc 或点击「关闭」退出菜单。

交易和使用药水后会自动写入 `user://orchard_progress.json`。Windows 默认路径是 `%APPDATA%\Godot\app_userdata\Orchard Village\orchard_progress.json`。六栋房屋各有稳定的 `building_id` 元数据，存档以该 ID 记录改造状态。

现有 `build/web` 包含药水商店和史莱姆战斗的单线程 HTML5 导出。将整个目录部署到平台同源静态路径，例如 `/games/orchard-village/`，再用 iframe 加载该路径的 `index.html`。服务器为 WASM 返回 `application/wasm`。浏览器存档保存在 IndexedDB 中，随浏览器和站点来源区分。Web 包内附带 Noto Sans SC 字体许可证。

## 史莱姆战斗

村庄空地有三只史莱姆。先朝怪物移动来调整面向，进入距离后按空格攻击。黄色弧光表示挥击，受伤时角色会闪红。普通攻击造成 10 点伤害，每只史莱姆有 30 点生命，击败后获得 25 金币。留意史莱姆的接触攻击，也可以在战斗中按 B 使用背包里的生命药水。打开背包时停止走动，史莱姆仍然会行动。

倒下后点击「重新开始」回到广场并恢复满血。史莱姆会重生，金币、背包和已改造的商店继续保留。旧存档会读取原先保存的生命值。