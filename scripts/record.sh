#!/usr/bin/env bash
# Records the dry-run into recordings/demo.cast (asciinema) and renders recordings/demo.gif (agg + ffmpeg).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=recordings; mkdir -p $OUT
./scripts/demo-reset.sh >/dev/null                      # start from the broken state
COLS=110 ROWS=28
script -qec "NO_RESET=1 asciinema rec --overwrite -q --cols $COLS --rows $ROWS -i 2 -c ./scripts/demo-dry-run.sh $OUT/demo.cast" /dev/null
# Terminal.app "Pro"-like colours; the 1080p composition adds window chrome, captions, intro and outro
agg --font-size 20 --font-family "DejaVu Sans Mono" --theme 000000,e6e6e6,000000,c23621,25bc24,adad27,492ee1,d338d3,33bbc8,cbcccd,818383,fc391f,31e722,eaec23,5833ff,f935f8,14f0f0,e9ebeb \
    --idle-time-limit 2 $OUT/demo.cast $OUT/raw.gif
uv run --with pillow --with imageio-ffmpeg python scripts/make-video.py $OUT/demo.cast $OUT/raw.gif $OUT/demo.mp4
rm -f $OUT/raw.gif $OUT/demo.gif
ls -lh $OUT
