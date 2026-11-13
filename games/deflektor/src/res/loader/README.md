# loader

The loading screen's two resources, loaded by the turbo block (src/tape/tape.txt) and used by the loader's second
stage (src/loader/stage2.ann) while the game loads; the game never reads them (the game's code later overwrites
`$998E`, the font at `$B326` lies in the loader's area).

| File | Address | Size | Format |
| --- | --- | --- | --- |
| glyphs.png | `$B326` | 472 | 1-bit glyphs, 59 characters from 32: the font PrintGlyph `$B812` uses (FontPtr) |
| script.txt | `$998E` | 6552 | hex text: the script ScriptStep `$B78E` runs, characters and control codes |

The script's control codes (window, position, colour, fills, pictures, pauses, `$04` the end) and the decoded script
are in work/ann/04-loader.md (and src/loader/stage2.ann, module control). A changed script or font changes the turbo
block: tools/mktape.py writes the pulses the loader asks for, so the tape still loads.
