# Die unteren Gewölbe

[English](../README.md) · [简体中文](README.zh-CN.md) · [Русский](README.ru.md) · [Español](README.es.md) · [Português (Brasil)](README.pt-BR.md) · **Deutsch** · [日本語](README.ja.md) · [Français](README.fr.md) · [Polski](README.pl.md) · [한국어](README.ko.md)

Ein Spaziergang in der Ich-Perspektive durch einen endlosen Turm. Im Archiv der Maße und Gewichte führt der Weg über eine Holzbrücke zwischen Schubladenwänden. Treppen führen weiter zur Gezeitenzisterne, zur Sternwarte und in den Wald der Stimmgabeln. Jeder Bewohner hat seinen eigenen Klang. Oft hört man ihn, bevor man ihn sieht.

![Ein Holzsteg mit Messinggeländer führt an Reihen von Archivschubladen vorbei.](screenshots/archive.jpg)

*Archiv der Maße und Gewichte*

## Spiel starten

Entpacke das komplette x86-64-Archiv für dein System. Lass die EOS-Bibliotheken neben der ausführbaren Datei. Beim Start eines Durchgangs öffnet die konfigurierte Version einen Raum und zeigt oben rechts seinen sechsstelligen Code, zum Beispiel `K7Q-2MX`. Deine Mitspieler geben ihn auf dem Startbildschirm ein und wählen **Mit Code beitreten**, um dieselbe Expedition zu betreten.

- **Windows** — `build/LowerVaults.exe` per Doppelklick starten.
- **Linux** — im Projektverzeichnis folgende Befehle ausführen.

```sh
chmod +x "build/Нижние своды.x86_64"
"./build/Нижние своды.x86_64"
```

## Steuerung

| Aktion | Eingabe |
| --- | --- |
| Turm betreten | Eingabetaste, Leertaste oder **Eintreten** |
| Gehen | WASD oder Pfeiltasten |
| Umsehen | Maus |
| Rennen | Beim Gehen die Umschalttaste gedrückt halten |
| Pausieren oder fortsetzen | Esc |
| Spiel beenden | Esc → **Spiel beenden** |

Im Pausenmenü lassen sich die Mausempfindlichkeit, die Gesamtlautstärke und die Lautstärke der eigenen Schritte einstellen.

## Sprache

Die Sprachauswahl befindet sich oben rechts im Startbildschirm und im Pausenmenü. Menüs, Hinweise und Ortsnamen wechseln sofort die Sprache. Beim ersten Start verwendet das Spiel die Systemsprache, sofern sie unterstützt wird, andernfalls Englisch. Die Auswahl wird für den nächsten Start gespeichert. Alle zehn Sprachen sind oben auf dieser Seite verlinkt.

## Bildschirmfotos

![Ein steinerner Steg führt unter Spitzbögen auf ein Rosettenfenster zu.](screenshots/cathedral.jpg)

*Kathedrale über dem Abgrund*

![Über schmalen Brücken hängen der Schädel und die Rippen eines Leviathans.](screenshots/leviathan.jpg)

*Gebeine des Leviathans*

## Änderungsprotokoll

Die Änderungen jeder Version stehen im [Änderungsprotokoll](CHANGELOG.de.md).

## Tokenverbrauch für v0.1.0

| Werkzeug | Sitzungen | Token |
|---|---|---:|
| Codex | 4 Hauptsitzungen und 6 Subagenten-Sitzungen | 75.875.836 |
| Claude Code | 1 Sitzung zur Veröffentlichung | 1.645.162 |
| **Gesamt** | **11** | **77.520.998** |

Die lokalen Protokolle erfassen die Entwicklung und die Release-Vorbereitung am 24. und 25. November 2026. 98,45 % aller Token wurden aus dem Cache gelesen. Von den übrigen 1.199.332 Token entfielen 364.313 auf die Modellausgaben.

## Aus dem Quellcode bauen

Benötigt werden **Godot 4.7.1 stable** und die passenden Exportvorlagen. Sie lassen sich über **Editor → Manage Export Templates** installieren. Zum Spielen im Editor `project.godot` öffnen und F5 drücken.

Für beide Release-Versionen die folgenden Befehle im Projektverzeichnis ausführen. Der Godot-Editor muss als `godot` aufrufbar sein.

```sh
python3 tools/install_eos.py
godot --headless --import
godot --headless --export-release "Linux"
godot --headless --export-release "Windows"
```

Die Ausgabepfade stehen in [export_presets.cfg](../export_presets.cfg). Die Originaltexte sind auf Russisch, die neun Übersetzungen liegen unter [i18n](../i18n/). Eine mitgelieferte Ersatzschrift deckt Chinesisch, Japanisch und Koreanisch ab. [Schriftlizenz](../i18n/fonts/OFL.txt).
