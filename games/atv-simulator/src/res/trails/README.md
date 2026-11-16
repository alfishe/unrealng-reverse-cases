# trails

| File | Address | Size | Trails | Readers |
| --- | --- | --- | --- | --- |
| `trails14.txt` | TrailRecords `$7C9C-$807A` | 991 | 1-4: the four records, the lists A then B, the animation records `$8042` | SelectTrail (the record of trail n at `$7C9C` + 6 n), WalkList / PlaceItem (the lists), AnimObject `$8A49` |
| `trail5.txt` | Trail5 `$EE84-$F03B` | 440 | 5 TROPICANA, its record at `$EE84` | the same |
| `trail6.txt` | Trail6Image `$F230-$F4B9` | 650 | 6 SWAMP: GameEntry copies it to `$60AC`, and every address in it is the copy's | the same |

**The record**: list A, list B, the length (FinishDistance = length less `$48`). **An item** (6 bytes): the distance
along the trail (a word), y (0: the sprite's own height, else the height above the ground line), the advance (0 in
the image; InitListWidths `$7873` fills it from the sprite), the sprite and the flags (bit 0: the sprite is a picture
of the menu bank, drawn by MenuSprite with its attributes (DeferAttrs); bit 1: drawn
before the ATV (DeferB, DeferredB); bit 2: drawn after it, in front (DeferA, DeferredA); bit 3: masked; PlaceItem
`$8E5E` shifts bits 1-3 into ItemFlags bits 5-7); when the flags' bits 4-7 are set the last two bytes are instead the address of an
animation record. `$FFFF` ends a list. List A (the ground pieces and the obstacles) scrolls at the speed x 128 a pass
(Distance `$D789`, the word TrackPos `$D78A`), list B (the scenery) at the speed x 32, a quarter of list A's (Scenery `$D78E`, ForwardScenery `$E0E1`).
**An animation record**: the sprite, the flags, an id (SeenIds: a record is drawn once a pass), then the motions:
the x period and counter, the y period and counter, the x and y steps (high and low nibble), the frame period and
counter; a counter's bit 7 is its direction; `$FF` ends the record.

There are no obstacle kinds in the data: everything list A draws is ground. GroundUnder (`$E810`) scans the buffer's
pixels under each wheel, so a ramp, a log, a rock or a dune is whatever its pixels are; Crash (`$E94C`) follows from
the height the wheels meet (a step of `$15` or more, a drop of 7 or more). The text form keeps the order of the bytes;
`tools/trail_map.py OUT.png [TRAIL ...]` draws the trails from these files.

**Leftovers.** trail5.txt ends with 36 bytes (`$F018-$F03B`) shaped as animation records that no item points at;
trail6.txt with 147 bytes of assembler source text from the developer's memory (`$F427-$F4B9` of the image, the
copy's `$62A3-$6335`: "LD A,1", "JR MRIGHT", "RIGHT2:LD A,(BDIR)", "CP BOB+8"), copied with the trail and never
read. Known only from the code: no read of them in any recording's L1.
