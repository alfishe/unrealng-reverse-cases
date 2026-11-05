# 06. Resources

**Answers:** every resource as a file a person can edit, built back into the original bytes.

1. **Find them.** Sources:
   - L2's graphics, font, text, music, tile and map claims;
   - the pointer tables that index them;
   - the code that writes the screen: the code-vs-screen map (recipe 07) shows which bytes each draw reads;
   - a pointer search, for data no L1 reader shows. Images read with `POP` have no reader, which is how Zynaps'
     sprite descriptors were found.

2. **Cut them out.** Put `@res KIND/NAME.bin` under a data entry in the `.ann`
   ([ann-format.md](../docs/ann-format.md#2-directives)). Entries that name the same file share it. The generator
   writes `INCBIN "res/KIND/NAME.bin",offset,length`.

3. **Give each one an editable format** in the case's `tools/res_formats.py` (start from the template's):

   | Kind | Format | Examples |
   | --- | --- | --- |
   | graphics, sprites, fonts | indexed PNG (ink, paper, mask colour), one sheet with the frames in a row | hate, `res_gfx.py`, `res_font.py` |
   | screens | `.scr` (or PNG + attributes) | every case |
   | tunes, effects | text, one row a note or a step (`res_tune.py`, `res_effects.py`, `sk10.py decode`, `sound_data.py`); `.pt3` for a Pro Tracker module | zynaps, zynaps-128, ZS |
   | levels, maps | text, one row a cell or a record (`res_levels.py`, `zs_level.py`) | zynaps, ZS |
   | texts | the build input in `src/res/text/` (a codec's text: `#codec cp866`, `\xNN`), plus a UTF-8 Markdown page in `docs/texts/` for the reader | GS, ZS (recipe 10) |
   | anything else | the bytes, named | |

   ```bash
   python3 tools/res_formats.py check                  # every editable file both ways
   python3 tools/res_formats.py build --out build/res  # what the build INCBINs
   ```

   A resource that overlaps code needs `res_formats.OVERLAP` (nether-earth-gs).

4. **Check them against the recording.**
   - The memory at the `INCBIN` address must equal the file at chosen frames. Bytes the game rewrites during play
     are named (`verify_res.py`).
   - Check each format against its drawing routine: draw a frame from the file the way the routine does, then
     compare it with the buffer the routine drew (`verify_sprites.py`, `verify_tune.py`, `verify_objects.py` in
     hate).

5. **List them.** `src/res/README.md` lists every file: address, size, format, readers, and a preview
   (`tools/res_preview.py`, written into `docs/img/res/`). Disk-wide and media resources have their own checks:
   `res_media.py check`, `disk_media.py check`.

**Done when:** every byte the analysis called graphics, text, music or level data is in `src/res` in an editable
form, `res_formats.py check` passes, and the build is still bit for bit.
