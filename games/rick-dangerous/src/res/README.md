# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/charset0.png`, `charset1.png` | the two char sets (256 chars and their attributes each): levels 1-2, levels 3-4 | PNG in colours, a grid | CharSet0 + CharAttr0, CharSet1 + CharAttr1 |
| `graphics/font.png` | the font's 43 glyphs | PNG | Font |
| `levels/levels.txt` | the zones' maps, zone records, exits and objects | text | Maps, Zones, Exits, Objects (module `leveldata`) |
| `levels/tiles.txt` | the 256 tiles of 4 x 4 chars | text | Tiles |
| `levels/kinds.txt` | the 72 object kinds, their animations and movement scripts | text | ObjectKinds, the anims and scripts |
| `sprites/frames.png` | the 54 sprite frames, mask and pixels | PNG, four indices | SpriteFrames |
| `sprites/copied.png` | the two frames Start copies to `$6A80` and `$7080` | PNG, four indices | Kind16Frame, Kind19Frame (module `loader`) |
| `texts/*.txt` | the ten texts: the level intros, the ending, the menu, GAME OVER | text | the `*Text` entries |
| `screens/loading.png` | the loading screen (`screens/loading.scr`, tape group 1) | PNG in colours | src/tape/tape.txt |
| `music/music.txt` | the AY player's patterns, tunes, order lists, instruments and effects | text | the music part's tables (src/music) |
| `loader/keypage.bin`, `lastblock.bin` | tape group 1's key page and decoy last block | bytes (see `loader/README.md`) | src/tape/tape.txt |

Each folder's README.md has the addresses, the format and the readers.

Built, not kept here (case.json `built`; tools/build.sh copies them to `build/res`): `loader/stage2.bin`
(src/loader/stage2.asm) and `music/music.bin` (src/music/music.asm), which the game's module `loader` INCBINs at
`$5D00` and `$5E00`.
