"""Rebuild the CJK fallback font from Noto Sans CJK JP, keeping only glyphs the game text uses."""

from pathlib import Path
import sys

from fontTools import subset


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "i18n/fonts/vaults-fallback.otf"
SKIPPED = {".godot", "addons", "build"}


def game_text() -> str:
    characters = {chr(code) for code in range(0x20, 0x7F)}
    sources = list(ROOT.glob("i18n/*.po")) + [
        path for path in ROOT.rglob("*.gd") if not SKIPPED.intersection(path.relative_to(ROOT).parts)
    ]
    for path in sources:
        characters.update(path.read_text(encoding="utf-8"))
    return "".join(sorted(characters - {"\n", "\r", "\t"}))


def main(source: str) -> None:
    subset.main([
        source, "--font-number=0", f"--text={game_text()}",
        "--layout-features=*", f"--output-file={OUTPUT}",
    ])


if __name__ == "__main__":
    main(sys.argv[1])
