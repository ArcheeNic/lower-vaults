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

## Подпись для Windows (SignPath Foundation, начато 25.11.2026)
- Без подписи Smart App Control в Windows 11 блокирует exe совсем, кнопки «Запустить всё равно» нет.
- Условия SignPath: OSI-лицензия на всё, никакого проприетарного кода, сборка из исходников на CI, ручное подтверждение каждого релиза, на главной обязательны «Code signing policy» и раздел о приватности (они есть во всех README). Закрытый EOS SDK в архиве — риск отказа: Артур решил всё равно подать заявку.
- CI: `.github/workflows/release.yml` запускается по тегу `v*` или вручную. Креды берёт из секрета `EOS_CFG`, подписывает при наличии переменной `SIGNPATH_ORGANIZATION_ID` и секрета `SIGNPATH_API_TOKEN`. В SignPath нужны проект `lower-vaults`, политика `release-signing` и конфигурация артефакта `windows-zip` (копия — в `.signpath/artifact-configurations/windows-zip.xml`).
- Версию в exe задаёт `VERSION` (из тега) через `config/version`. Godot 4.7 сам меняет ресурсы PE на Linux, rcedit не нужен.
- **Отказ 25.11.2026** (письмо от oss-support@signpath.org через 1,5 ч после подачи): мало публичной известности — звёзд, форков, контрибьюторов, внешних упоминаний (Reddit, YouTube, статьи). Про EOS SDK ни слова. Подать заново можно, когда проект станет заметнее; тогда вернуть в README раздел «Code signing policy» с фразой «Free code signing provided by SignPath.io, certificate by SignPath Foundation» (его убрали после отказа).
- Пока подписи нет: во всех README в разделе запуска есть подраздел «If Windows blocks the game» (SmartScreen → «Подробнее → Выполнить в любом случае», Smart App Control — только отключить или играть в Linux-версию) с пояснением про отказ. Та же заметка — в описаниях релизов v0.1.0–v0.4.0 и в тексте по умолчанию в `release.yml`. Новый релиз вручную — добавлять её в notes.
- Платить за подпись Артур сейчас не может. Бесплатная альтернатива — Microsoft Store: регистрация индивидуального разработчика бесплатна с 09.2025, MSIX подписывает Microsoft (подпись только у версии из Store, zip на GitHub остаётся неподписанным). Регистрацию в Partner Center проходит сам Артур. Платные: Certum Open Source, SignPath по подписке, OV-сертификат.
- Тестовая сборка CI без публикации: `gh workflow run 430366395 --ref main`, архивы — в артефакте `LowerVaults-test-build`. Проверена 25.11.2026, всё зелёное.
