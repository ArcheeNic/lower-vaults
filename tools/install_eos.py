"""Install the pinned desktop EOSG runtime before importing/exporting the game."""

from hashlib import sha256
from io import BytesIO
from pathlib import Path
import re
from tempfile import TemporaryDirectory
from urllib.request import urlopen
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
VERSION = "2.3.1"
REVISION = "56238973e2cd7ac9ac99ca14f88934465f0a8997"
RELEASE = f"https://github.com/3ddelano/epic-online-services-godot/releases/download/{VERSION}"
ARCHIVE_HASHES = {
    "linux": "76f7afcd01247abbba140d0f6f9d8d4e3524a20e84e08af0acd124238d2575d4",
    "windows": "929d1fcb24c9f10834408f5c9fb80d76a6c942b2deadff553ff3f0ff57a30ee1",
}
ADDON = ROOT / "addons/epic-online-services-godot"
ARCHIVE_ROOT = "epic-online-services-godot/addons/epic-online-services-godot"


def install():
    manifest = (ROOT / "tools/eosg.gdextension.in").read_text(encoding="utf-8")
    files = sorted(set(re.findall(r'"(bin/[^"]+)"', manifest)))
    with TemporaryDirectory(dir=ADDON) as temp:
        staging = Path(temp)
        for platform, digest in ARCHIVE_HASHES.items():
            print(f"Downloading EOSG {VERSION} for {platform}...", flush=True)
            url = f"{RELEASE}/epic-online-services-godot-{platform}-{REVISION}.zip"
            with urlopen(url, timeout=120) as response:
                data = response.read()
            if sha256(data).hexdigest() != digest:
                raise ValueError(f"SHA-256 mismatch for {platform} EOSG archive")
            with ZipFile(BytesIO(data)) as archive:
                for name in files:
                    if name.startswith(f"bin/{platform}/"):
                        dest = staging / name
                        dest.parent.mkdir(parents=True, exist_ok=True)
                        dest.write_bytes(archive.read(f"{ARCHIVE_ROOT}/{name}"))

        for name in files:
            dest = ADDON / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            (staging / name).replace(dest)
        (staging / "eosg.gdextension").write_text(manifest, encoding="utf-8")
        (staging / "eosg.gdextension").replace(ADDON / "eosg.gdextension")

    # Godot 4.7.1 crashes on editor shutdown if it first discovers EOSG during
    # scanning. Registering it for startup also works on a fresh checkout.
    extension_list = ROOT / ".godot/extension_list.cfg"
    extension_list.parent.mkdir(exist_ok=True)
    extensions = []
    if extension_list.exists():
        extensions = extension_list.read_text(encoding="utf-8").splitlines()
    uri = "res://addons/epic-online-services-godot/eosg.gdextension"
    if uri not in extensions:
        extensions.append(uri)
        extension_list.write_text("\n".join(extensions) + "\n", encoding="utf-8")
    print("EOSG is installed. Run the Godot project import before exporting.")


if __name__ == "__main__":
    install()
