# 06. Resources

**Answers:** every resource as a file a person can edit, built back into the original bytes.

1. Find them: L2's graphics, font, text, music, tile and map claims; the pointer tables that index them; the
   writers of the screen (the code-vs-screen map, recipe 07, shows which bytes each draw reads).
2. `@res` in `game.ann` cuts each into `src/res/<kind>/<name>.bin` and writes `INCBIN` in the source.
3. Editable formats (the case's `tools/res_formats.py`, started from the template's; H.A.T.E.'s is a full example): graphics as PNG (indexed: ink, paper, a mask colour; one file a sheet
   with its frames in a row), screens as `.scr`, music and levels as text with one row a note or a cell. The build
   turns them into the `.bin` files; `res_formats.py check` proves the round trip.
4. Check each against the recording (`verify_res.py`-style: the memory at the `INCBIN` address equals the file at
   chosen frames, or the bytes the game rewrites in play are named), and each format against its drawing routine
   (draw a frame from the file the way the routine does and compare with the buffer it drew, `verify_sprites.py`).
5. `src/res/README.md` lists every file: address, size, format, who reads it, the preview image.

**Done when:** every byte the analysis called graphics, text, music or level data is in `src/res`, editable, and
the build is still bit for bit.
