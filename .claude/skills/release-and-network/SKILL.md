---
name: release-and-network
description: Выпуск версий «Нижних сводов» и сетевой режим через Epic Online Services. Триггеры — «собери/выпусти релиз», «новая версия», GitHub Releases, EOS, Epic Developer Portal, креды eos.cfg, «код комнаты», лобби, p2p, попутчики, проверка сети.
---

# Релиз и сеть

## Сеть (EOS, плагин EOSG 2.3.1)
- Портал: организация `ka-games`, продукт The Lower Vaults (`products/thelowervaults`), песочница и деплоймент Live. Условия Standard Services приняты 25.11.2026.
- Клиент «The Lower Vaults game client», политика «Game client P2P» типа Peer2Peer. Серверных прав (TrustedServer и т.п.) этому клиенту не давать: его секрет едет в сборке.
- Креды лежат в `network/eos.cfg` (права 600, в `.gitignore`). Шаблон — `network/eos.cfg.example`. Если файл потерян, всё берётся заново в портале: Product Settings → SDK Download & Credentials.
- Chrome-расширение отдаёт секреты из страницы как `[BLOCKED]`. Забрать их можно так: перехватить копирование (`DataTransfer.setData`), нажать кнопки Copy, собрать cfg в странице, скачать как blob, переложить из `~/Загрузки` в `network/eos.cfg` и удалить скачанный файл. Значения в чат не выводить.
- Вход анонимный, по Device ID. Подбор игроков — по коду комнаты (`network/room_code.gd`): 6 символов, первый кодирует режим и размер карты, код же задаёт сид карты. Бакет лобби — `lower-vaults-v1-<код>`, в лобби до 8 игроков, связь p2p каждый с каждым, передаются только позы.
- Защита от утечки: `make hooks` (pre-commit) и `make lint` → `tools/check_secrets.sh`.

## Проверки
- `make test` — коды комнат.
- Живая проверка p2p на одной машине: два процесса `tests/eos_peer.gd`. Второму дать другой `HOME`/`XDG_*`, иначе у обоих один Device ID. Оба должны вывести `PASS`.
- Шаблон экспорта игнорирует `--script`, поэтому сценарии гоняются только из проекта, а не из собранной игры.
- Снимок меню — через `xvfb-run` и `--rendering-driver opengl3`. Ошибки fog/instance-шейдеров там ожидаемы: игра рассчитана на Forward+.

## Выпуск
1. Всё закоммитить. Сборка идёт из `REF` (по умолчанию `HEAD`), незакоммиченное в неё не попадёт.
2. `make release` → `build/release/LowerVaults-{linux,windows}-x86_64.zip`. Скрипт берёт `git archive`, подкладывает `eos.cfg`, качает EOSG с проверкой sha256, экспортирует через `cpuq`. Библиотеки EOS должны лежать рядом с исполняемым файлом, поэтому релиз выходит архивами.
3. Записать новую версию в `CHANGELOG.md` и `docs/CHANGELOG.*.md` (10 языков), запушить, затем `gh release create vX.Y.Z --target <sha>` с обоими zip.
4. Новые CJK-строки в `.po` требуют пересборки шрифта: `make fallback-font`.
