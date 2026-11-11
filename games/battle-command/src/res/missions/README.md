# Missions (side 2)

Side 2 of the tape holds the catalogue and the ten mission blocks (src/tape/side2.txt, ROM-speed blocks). A mission
block loads at bank 0 `$DBC5` (LoadMission `$84C1`, LdBytes `$8617`, the reload part through `$855B`); the
catalogue loads at bank 4 `$CB64` (LoadDirectory `$715D`). `NN-NAME.txt` is the block as text (tools/res_missions.py:
every header field by name, the 64 vertices, the segments, the objects, the object templates, then the mission's
own code and data as hex lines at their addresses, the 3D models as `model` lines, one instruction a line, ../models/README.md; it builds back byte for byte). `NN-NAME.preview.png` is
the world from above (segments by style, objects as dots, yellow the active ones, the start in cyan, the
Helicarrier's pickup pad in magenta, the desertion line in red; the build ignores it). The models of each block are
listed and drawn in ../models.

The header (`$DBC5-$DBFF`): the mission number, `"MISSION:::"`, the half extents X / Y (BoundaryCheck `$D4B8`; four
units more is desertion), five unread bytes, the templates' address, the object count and list, the segment count,
the first switchable segment and its switch object, the goal hook (called every pass from `$6A66`; it sets the goal
flag `$68E8`), 8 bytes to `$7611` (the player's flags, heading, X, Y), the model library, the end of the part a
reload restores, 12 bytes to `$7E82` (the pad's X at +7, Y at +10), a byte to `$CAAF`, the mission time to `$68EB`.
Then vertex X `$DC00`, vertex Y `$DC40` (signed, x 1024 world units), the 6-byte segments from `$DC80` (vertex a,
vertex b, orientation, two sizes, the style), the 8-byte object records (flags, type, heading, spare, X word, Y word
in 4 world units, `$FF` after the last), and the 30-byte templates (object record bytes +2 to +`$1F`; the model
word at template +26).

| File | Bytes | Extent | Segments | Objects | Templates | Goal hook | Models |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01-blast-em-mission | 8058 | 28 x 22 | 10 | 89 | 34 | `$EB60` | `$EC57` |
| 02-missile-battery | 6384 | 18 x 17 | 16 | 59 | 25 | `$E2F4` | `$E80B` |
| 03-hostage-rescue | 6769 | 26 x 16 | 12 | 75 | 30 | `$E322` | `$E994` |
| 04-railway-ambush | 6418 | 28 x 22 | 8 | 50 | 17 | `$E927` | `$E93F` |
| 05-night-moves | 7534 | 28 x 17 | 21 | 119 | 31 | `$EA0E` | `$EB06` |
| 06-escort-duty | 7716 | 28 x 22 | 8 | 132 | 30 | `$EB93` | `$EC77` |
| 07-satellite-search | 7748 | 28 x 16 | 15 | 93 | 33 | `$EA6F` | `$EA73` |
| 08-river-raid | 6204 | 23 x 17 | 24 | 63 | 24 | `$E97F` | `$E9A3` |
| 09-hideout | 6709 | 28 x 17 | 11 | 94 | 29 | `$E8B5` | `$E8C4` |
| 10-grand-finale | 7014 | 28 x 22 | 8 | 102 | 32 | `$EA07` | `$EB09` |

**Mission 2 is damaged on the Ocean tape.** Its header asks for 6406 bytes, the block holds 6384. The first 3487
bytes (`$DBC5-$E963`) equal the Erbe release's block (6406 bytes, which loads and plays); from `$E964` on the 2897
bytes are other data that no other block of either release holds. LdBytes waits for the missing 22 bytes, times out,
and `$855B` asks for the block again for ever. Here the block is Ocean's, as on the tape: 19 of its 21 models break
(../models/02-missile-battery.txt).

`catalogue.txt` (`catalogue.bin`, 7124 bytes, the DIRECTORY block): `"MISSION:TAPE1"` (IsCatalogueLoaded `$C870`
compares 7 bytes), the ten 27-byte names from +`$20` (BuildMissionNames `$C030`), a word table, the ten goal texts,
the briefing maps' data and the ten briefings (CopyMissionText `$70F6` copies the chosen mission's texts to
`$DBF3`), as a text of the texts' kind (../texts/README.md: UTF-8, `{XX}` for the other bytes; in the small font
`:` is a space and `[` a full stop).
