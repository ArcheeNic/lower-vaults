#!/usr/bin/env bash
# Renders the 1280×640 GitHub social preview from the archive screenshot.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SERIF=${SERIF:-/usr/share/fonts/opentype/urw-base35/NimbusRoman-Regular.otf}
SANS=${SANS:-/usr/share/fonts/truetype/ubuntu/Ubuntu-R.ttf}

magick "$ROOT/docs/screenshots/archive.jpg" \
	-resize 1280x -gravity center -crop 1280x640+0+40 +repage -modulate 118,108 \
	\( -size 1280x330 gradient:'rgba(10,11,10,0)-rgba(10,11,10,0.78)' \) -gravity south -compose over -composite \
	\( -size 640x1280 gradient:'rgba(10,11,10,0)-rgba(10,11,10,0.55)' -rotate 90 -resize 760x640! \) -gravity west -compose over -composite \
	-gravity southwest -fill '#f0e3c9' -font "$SERIF" -pointsize 92 -interline-spacing -24 \
	-annotate +64+118 'THE LOWER
VAULTS' \
	-fill '#dcceb9' -font "$SANS" -pointsize 25 \
	-annotate +68+60 'A first-person walk through an endless tower' \
	-quality 90 "$ROOT/docs/social-preview.jpg"
