# The Lower Vaults

**English** · [简体中文](docs/README.zh-CN.md) · [Русский](docs/README.ru.md) · [Español](docs/README.es.md) · [Português (Brasil)](docs/README.pt-BR.md) · [Deutsch](docs/README.de.md) · [日本語](docs/README.ja.md) · [Français](docs/README.fr.md) · [Polski](docs/README.pl.md) · [한국어](docs/README.ko.md)

The walk begins in the Archive of Weights and Measures, on a wooden bridge between walls of drawers. From there, stairways wind through an endless tower of tidal cisterns, observatories and tuning-fork forests. Listen as you walk. Each inhabitant has a sound you can recognise before you see it.

![Brass railings line a wooden walkway between banks of archive drawers.](docs/screenshots/archive.jpg)

*Archive of Weights and Measures*

## Play

The Linux and Windows builds are standalone x86-64 executables with the game assets included. The game uses Godot’s Forward+ renderer.

- **Windows** — double-click `build/LowerVaults.exe`.
- **Linux** — run these commands from the project directory.

```sh
chmod +x "build/Нижние своды.x86_64"
"./build/Нижние своды.x86_64"
```

## Controls

| Action | Control |
| --- | --- |
| Enter the tower | Enter, Space or the **Enter** button |
| Walk | WASD or arrow keys |
| Look around | Mouse |
| Run | Hold Shift while moving |
| Pause or resume | Esc |
| Quit | Esc → **Quit game** |

The pause menu has separate sliders for mouse sensitivity, master volume and the sound of your own footsteps.

## Language

Use the language selector at the top right of the title screen or pause menu. Menus, hints and location names change immediately. On first launch, the game uses your system language if supported and English otherwise. It remembers your choice the next time you play. All ten supported languages are linked at the top of this page.

## Screenshots

![A stone walkway leads towards a rose window beneath pointed arches.](docs/screenshots/cathedral.jpg)

*Cathedral over the Chasm*

![A leviathan’s skull and long rib cage hang over a network of narrow bridges.](docs/screenshots/leviathan.jpg)

*Remains of the Leviathan*

## Build from source

Use **Godot 4.7.1 stable** with the matching export templates. Install them through **Editor → Manage Export Templates**. To play in the editor, open `project.godot` and press F5.

To create both release builds, run the following commands from the project root with the Godot editor executable available as `godot`.

```sh
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

The output paths are set in [export_presets.cfg](export_presets.cfg). Russian is the source language. The other nine translations are in [i18n](i18n/). The game includes a fallback font for Chinese, Japanese and Korean. [Font licence](i18n/fonts/OFL.txt).
