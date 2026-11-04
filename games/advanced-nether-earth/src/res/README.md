# Advanced Nether Earth resources

What `tools/build.sh` builds the SCL from besides the sources (`src/loader.asm`, `src/sfx/`, `src/images.asm`,
`src/game/`, `src/disk.txt`). The build compares the SCL with the original byte for byte, so an edit here shows at
once as a difference.

| Path | What | Format |
| --- | --- | --- |
| `gfx/game-font.png` | the game's Cyrillic font, `$C500-$C6FF` (codes `$20-$5F`) | NE's font PNG (`tools/res_formats.py`, NE's `png_to_font`); the letters per code: `tools/game_text.py` |
| `text/nether-plus-w.txt` | the file `NETHER+.W` | UTF-8 here; `tools/mkdisk.py` writes it CP866 with CR LF |
| `text/help-text.md` | the help pages decoded (stage 1) | documentation, not a build input |
| `img/` | the unpacked images the build packs ([README](img/README.md)) | bytes |
| `disk/` | the bytes kept as they are ([README](disk/README.md)) | bytes |
