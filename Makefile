NOTO_CJK_DIR ?= /usr/share/fonts/opentype/noto
GODOT ?= $(HOME)/.local/share/latticefall/godot-4.7.1-stable

.PHONY: hooks lint test release fallback-font

hooks:
	git config core.hooksPath .githooks

lint:
	tools/check_secrets.sh

test:
	$(GODOT) --headless --script tests/room_code.gd

release: lint
	cpuq run --cpus 4 --label lower-vaults-release env GODOT="$(GODOT)" tools/release.sh

fallback-font:
	docker run --rm --user "$$(id -u):$$(id -g)" -e HOME=/tmp \
		-v "$(CURDIR)":/game -v "$(NOTO_CJK_DIR)":/fonts:ro -w /game python:3.12-slim \
		sh -c 'pip install -q --target /tmp/ft fonttools && PYTHONPATH=/tmp/ft python tools/subset_fallback_font.py /fonts/NotoSansCJK-Regular.ttc'
