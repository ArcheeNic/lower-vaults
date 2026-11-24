# 下层穹窿

[English](../README.md) · **简体中文** · [Русский](README.ru.md) · [Español](README.es.md) · [Português (Brasil)](README.pt-BR.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [Français](README.fr.md) · [Polski](README.pl.md) · [한국어](README.ko.md)

这是一场穿行于无尽高塔的第一人称漫游。旅程始于度量衡档案馆，脚下是木桥，两侧是成排的档案抽屉。循着楼梯，可以抵达潮汐蓄水池、天文台和音叉之林。塔里的每个居民都有独特的声音。有时还没看见身影，就已经知道是谁来了。

![带黄铜栏杆的木栈道从一排排档案抽屉之间穿过。](screenshots/archive.jpg)

*度量衡档案馆*

## 启动游戏

Linux 和 Windows 版本均适用于 x86-64，所有游戏资源都已打包进可执行文件。游戏使用 Godot 的 Forward+ 渲染器。

- **Windows** — 双击 `build/LowerVaults.exe`。
- **Linux** — 在项目目录中运行以下命令。

```sh
chmod +x "build/Нижние своды.x86_64"
"./build/Нижние своды.x86_64"
```

## 操作

| 动作 | 操作方式 |
| --- | --- |
| 进入高塔 | 按回车键、空格键或点击「进入」 |
| 行走 | WASD 或方向键 |
| 环顾四周 | 移动鼠标 |
| 奔跑 | 移动时按住 Shift |
| 暂停或继续 | Esc |
| 退出游戏 | Esc →「退出游戏」 |

在暂停菜单中可以分别调节鼠标灵敏度、主音量和自己的脚步声。

## 语言设置

标题画面和暂停菜单的右上角都有语言选择器。切换后，菜单、操作提示和地点名称会立即更新。首次启动时，游戏会使用支持的系统语言，如果没有对应的翻译则使用英语。手动选择的语言会保留到下次启动。页面顶部列出了全部十种语言。

## 游戏截图

![石道穿过尖拱，通向尽头的玫瑰窗。](screenshots/cathedral.jpg)

*深渊上的大教堂*

![利维坦的头骨和一长排肋骨悬在狭窄的桥道上方。](screenshots/leviathan.jpg)

*利维坦遗骸*

## 0.1.0 版本开发期间的 token 用量

| 工具 | 会话 | Token 数 |
|---|---|---:|
| Codex | 4 个主会话和 6 个子代理会话 | 75,875,836 |
| Claude Code | 1 个发布准备会话 | 1,645,162 |
| **合计** | **11** | **77,520,998** |

根据 2026 年 11 月 24 日至 25 日开发和发布准备期间的本地会话日志，从缓存读取的 token 占总数的 98.45%。其余 1,199,332 个 token 中，364,313 个由模型生成。

## 从源码构建

请使用 **Godot 4.7.1 stable** 及同一版本的导出模板。可通过 **Editor → Manage Export Templates** 安装模板。要在编辑器内运行游戏，请打开 `project.godot` 并按 F5。

要生成两个平台的发行版，请在项目根目录运行以下命令。`godot` 命令应指向编辑器的可执行文件。

```sh
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

输出路径在 [export_presets.cfg](../export_presets.cfg) 中设置。原文为俄语，其他九种语言的翻译位于 [i18n](../i18n/) 目录。游戏内置了供中文、日文和韩文使用的后备字体。[字体许可证](../i18n/fonts/OFL.txt)。
