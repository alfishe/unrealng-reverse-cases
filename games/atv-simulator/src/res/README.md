# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs (build/res), `tools/res_formats.py check` proves the round trip (each editable file -> bytes ->
the same file). `tools/build.sh` runs the build first. The formats are in the tool's header.

| Folder | What | Entries |
| --- | --- | --- |
| [screens](screens/README.md) | the loading screen (tape block 6) | the tape's `src/tape/tape.txt` |
| [sprites](sprites/README.md) | the two sprite banks: the game's (203 sprites, the font among them) and the front end's (14 pictures with attributes) | GameGfx `$8F5C`, MenuGfx `$6338` |
| [trails](trails/README.md) | the six trails: records, object lists, animation records | TrailRecords `$7C9C`, Trail5 `$EE84`, Trail6Image `$F230` |
| [tables](tables/README.md) | the sprite and attribute box lists of the panels and intros, the menus | PanelP1Sprites `$6C9E`, TrailIntroBoxes `$6ED7`, MenuDefs `$702A` |
| [texts](texts/README.md) | every text the game prints | HiScoreTitle `$695F`, HiNames `$696A`, HiScores `$6988`, MenuTexts `$70AA`, TrailTexts `$79E6`, GameTexts `$EC4E` |
| [sound](sound/README.md) | the tune player's notes, tunes, sequences and patterns | NoteTable `$FB72` to the end of the patterns `$FDFA` |

Bytes no code reads stay inside their resource as `bytes` lines or rows (the sprite bank's gaps and tail, the
source text after trail 6, the tunes' three bytes after the last pattern); each folder's README names them.
