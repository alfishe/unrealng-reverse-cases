# Advanced Nether Earth resources

The editable data that `tools/build.sh` builds the SCL from, together with the sources in `src/`. Each part's build
script (`tools/build_<part>.sh`) turns its folder into bytes with the part's converter and assembles the part's
modules into `build/<part>/`; `tools/build.sh` then packs the blocks and lays them out on the disk. The SCL is
compared with the original byte for byte, so an edit here shows at once as a difference.

| Folder | Part | What | Converter |
| --- | --- | --- | --- |
| `game/` | the game, `$6731-$D7D7` (`src/game/`) | the font (`gfx/font.png`, Cyrillic), the sprites, the view edges, the map (`map/level.txt`), the texts and the order names (UTF-8) | `tools/game_res.py`; the letter per font code: `tools/game_text.py` |
| `bootmenu/` | the boot menu and the help, `$6060-$F6D4` (`src/bootmenu/`) | 15 pictures (PNG, packed with Hrust 1), two 4x8 fonts, the pointer, the menu and the 28 help pages as text ([README](bootmenu/README.md)) | `tools/bootmenu_res.py`, `tools/bootmenu_hrust.py` |
| `intro/` | the intro (`src/intro/`) | the Eternity logo, the title picture, the "Presents" frames, the scroller's font, dither, star path and text; the `.parse` files hold the token choices of the authors' LZ | `tools/intro_mkpart.py`, `tools/intro_screen.py` |
| `music/` | the tunes and the title cards (`src/music/`) | MAD NIGHT, TAIGA and the Dead End tune (Pro Tracker 2), TOMY and REM (Pro Tracker 3), the three title cards | `tools/music_ptmodule.py`, `tools/music_res.py` |
| `endings/` | Dead End (bank 3) and Final Cut (`src/endings/`) | the pictures, the game-menu picture, the scroll font and text; the `.lzhints` files hold the packer's choices | `tools/endings_*.py` |
| `diskmod/` | the disk save / load module, bank 4 (`src/disk/`) | its font, title picture and sample | `tools/disk_res.py` |
| `disk/` | the SCL itself | the saved game `nether.N` and the filler bytes no program reads, kept as they are ([README](disk/README.md)) | bytes |
| `text/` | the SCL | `nether-plus-w.txt`, the file `NETHER+.W` | UTF-8 here; `tools/mkdisk.py` writes it CP866 with CR LF |
