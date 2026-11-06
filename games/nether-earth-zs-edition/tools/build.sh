#!/bin/sh
# Build both SCLs from the sources and compare each with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# 1. Each part's build (tools/build_<part>.sh) writes its unpacked bytes into build/<part>/ and checks them:
#    intro98 (the '98 BASIC and intro), game98 (the '98 game), front99 (the '99 BASIC, stage 2, pictures, music),
#    menu99 (stage 3, the start-up menu), game99 (the '99 game, the patches, the twelve maps), texts (the .W files).
# 2. The '99's five packed blocks (src/sfx/blocks.txt): tools/zspack.py packs each image with its hints
#    (src/sfx/hints/), sjasmplus puts the set-up and the depacker (src/sfx/zsblock.asm) in front of the stream.
#    The rest of each block's last sector is the image's bytes after the block's length (packed in place).
# 3. tools/mkscl.py writes the SCLs from src/disk98.txt and src/disk99.txt; each is compared with the SCL inside its
#    orig/ zip.
#
# One build at a time: a second run waits for build/.lock (a folder; a stale one older than 30 minutes is taken).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build"
mkdir -p "$b"
lock="$b/.lock"
waited=0
until mkdir "$lock" 2>/dev/null; do
    if [ -n "$(find "$lock" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
        echo "build: taking a stale lock ($lock)" >&2
        rm -rf "$lock"
        continue
    fi
    [ $waited -eq 0 ] && echo "build: waiting for another build ($lock)" >&2
    waited=1
    sleep 2
done
trap 'rm -rf "$lock"' EXIT INT TERM
cd "$here"

# 1. the parts
for part in intro98 game98 front99 menu99 game99 texts; do
    sh "tools/build_$part.sh" "$asm" >/dev/null
done

# 2. the packed blocks
rm -rf "$b/lead"
mkdir -p "$b/lead"
grep -v '^#' src/sfx/blocks.txt | while read -r name image at dst stop far done; do
    [ -n "$name" ] || continue
    python3 tools/zspack.py pack "$b/$image" "$b/lead/$name.pk" --far-bits "$far" \
        --hints "src/sfx/hints/$name.lzhints" >/dev/null
    len=$(wc -c < "$b/lead/$name.pk" | tr -d ' ')
    (cd "$b/lead" && "$asm" --nologo --msg=war -DAT=0x$at -DLEN=$len -DDST_END=0x$dst -DSTOP=0x$stop \
        -DFARBITS=$far -DDONE=0x$done -DSTREAM="\"$name.pk\"" -DOUT="\"$name.blk\"" --lst="$name.lst" \
        "$here/src/sfx/zsblock.asm")
    # The rest of the block's last sector: the packer packed in place over the image in memory, so the sector
    # holds the image's own bytes from the block's length on (zero past the image's end)
    python3 -c "import sys; blk, img = (open(f, 'rb').read() for f in sys.argv[1:3])
n = -len(blk) % 256; open(sys.argv[3], 'wb').write((img[len(blk):] + bytes(n))[:n])" \
        "$b/lead/$name.blk" "$b/$image" "$b/lead/$name.slack"
done

# 3. the disks
python3 tools/mkscl.py src/disk98.txt "$b/NEZSED98.SCL"
python3 tools/mkscl.py src/disk99.txt "$b/NEZSED.SCL"
status=0
for pair in "NEZSED98.zip NEZSED98.SCL" "NEZSED.ZIP NEZSED.SCL"; do
    set -- $pair
    if unzip -p "orig/$1" "$2" | cmp -s - "$b/$2"; then
        echo "build: $2 identical to orig/$1"
    else
        unzip -p "orig/$1" "$2" | cmp - "$b/$2" || true
        status=1
    fi
done
exit $status
