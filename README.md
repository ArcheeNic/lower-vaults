# The Lower Vaults

**English** · [简体中文](docs/README.zh-CN.md) · [Русский](docs/README.ru.md) · [Español](docs/README.es.md) · [Português (Brasil)](docs/README.pt-BR.md) · [Deutsch](docs/README.de.md) · [日本語](docs/README.ja.md) · [Français](docs/README.fr.md) · [Polski](docs/README.pl.md) · [한국어](docs/README.ko.md)

The walk begins in the Archive of Weights and Measures, on a wooden bridge between walls of drawers. From there, stairways wind through an endless tower of tidal cisterns, observatories and tuning-fork forests. Listen as you walk. Each inhabitant has a sound you can recognise before you see it.

![Brass railings line a wooden walkway between banks of archive drawers.](docs/screenshots/archive.jpg)

*Archive of Weights and Measures*

## Play

Extract the entire x86-64 archive for your platform. Keep the EOS libraries beside the executable. The game uses Godot’s Forward+ renderer.

- **Windows** — double-click `LowerVaults.exe`.
- **Linux** — run these commands in the extracted folder.

```sh
chmod +x LowerVaults.x86_64
./LowerVaults.x86_64
```

### If Windows blocks the game

The Windows build is not signed yet, so Windows may stop it from starting.

- **Microsoft Defender SmartScreen** shows “Windows protected your PC”. Choose **More info**, then **Run anyway**.
- **Smart App Control** blocks unsigned apps with no option to run them. You can turn it off in **Windows Security → App & browser control → Smart App Control settings**. On some versions of Windows 11, it can’t be turned back on without reinstalling Windows. The Linux build has no such restriction.

We applied to the SignPath Foundation for a free code signing certificate. The Foundation certifies only projects that are already widely known, so the application was declined for now. We will apply again once the game is better known.

## Playing together

Choose a mode and start walking. A configured build signs you in with a device ID and opens a room. Its six-character code appears in the upper-right corner, for example `K7Q-2MX`. Friends type the code on the title screen and choose **Join by code**. The code carries the mode and map size, so everyone walks the same expedition.

Each room holds up to eight explorers. The connection status appears beside the code. Other explorers wear a glowing shoulder lamp. Each player keeps their own health, relics, encounters and finish. Opening the pause menu keeps you connected. If EOS is unavailable, you can keep walking.

## Controls

| Action | Control |
| --- | --- |
| Enter the tower | Choose a mode or press Enter on the focused mode |
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

## Changelog

All changes by version are in the [changelog](CHANGELOG.md).

## License

The game’s code and assets are released under the [Apache License 2.0](LICENSE). The CJK fallback font is under the [SIL Open Font License](i18n/fonts/OFL.txt). Release archives also include the Epic Online Services SDK, which Epic distributes under its own terms.

## Privacy

When a walk starts, the game connects to Epic Online Services to meet other players by room code. It signs in with an anonymous device ID and shares only your position and facing with players in the same room. The game sends no other data. Epic handles the connection under its [privacy policy](https://www.epicgames.com/site/privacypolicy).

## Token usage for v0.1.0

| Tool | Sessions | Tokens |
|---|---|---:|
| Codex | 4 main sessions and 6 subagent sessions | 75,875,836 |
| Claude Code | 1 release session | 1,645,162 |
| **Total** | **11** | **77,520,998** |

Local session logs cover development and release work on November 24–25, 2026. Cache reads accounted for 98.45% of all tokens. Of the remaining 1,199,332 tokens, 364,313 were model output.

## Build from source

Use **Godot 4.7.1 stable** with the matching export templates. Install them through **Editor → Manage Export Templates**. To play in the editor, open `project.godot` and press F5.

To create both release builds, run the following commands from the project root with the Godot editor executable available as `godot`.

```sh
python3 tools/install_eos.py
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

The output paths are set in [export_presets.cfg](export_presets.cfg). Russian is the source language. The other nine translations are in [i18n](i18n/). The game includes a fallback font for Chinese, Japanese and Korean. [Font licence](i18n/fonts/OFL.txt).

### Configure EOS for a multiplayer build

In the Epic Developer Portal, create or select **The Lower Vaults**, then create a game client with the **Peer2Peer** client policy under **Product Settings → Clients**. Copy the five values from the product, sandbox, deployment and client settings into `network/eos.cfg` using the [config template](network/eos.cfg.example). [Epic’s client policy walkthrough](https://dev.epicgames.com/community/learning/tutorials/JGKP/unreal-engine-eos-p2p-lobbies-and-voice).

The export includes this file when present. You can also supply `eos.cfg` beside the exported executable to override its settings without rebuilding. Distribute the entire configured game folder or archive. To verify, launch the same build on two devices, start a run on one device, enter its room code on the other and move a few steps apart. Check that both players can see each other move and that leaving removes the explorer from the other screen.

For an automated live check, run the following command in the configured project on two devices. Use the same test name and change the final argument to `B` on the second device. Each process returns success after receiving an acknowledgement of its pose from the other device.

```sh
godot --headless --script tests/eos_peer.gd -- vaults-test A
```

If Windows reports a missing MSVCP140 or VCRUNTIME140 DLL, install the [Microsoft Visual C++ Redistributable for x64](https://aka.ms/vc14/vc_redist.x64.exe).
