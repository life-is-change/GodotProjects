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
