# Tables

The page-tail tables, the kind templates, the start values, the 48K effects, the gates, the title scene, the actor scripts and the
packer's phase table, all from the game part. CSV files have a header line; a column whose name starts with `_` (the
record's address, the kind, the notes) is written for the reader and is not read back. Hex-line files have one record
or script a line; `$ADDR:` and `#` lines are comments.

## The page tails (PageTailTemplate `$6B5C-$7047`)

BuildPageTails `$5D07` copies the 1260-byte template, ten rows of 126 bytes, to `+$82..+$FF` of the pages
`$5D00-$6600`. Row n goes to page `$5D` + n; image address = `$6B5C` + 126 n + (run-time low byte - `$82`). The
template is cut into its tables. The three pieces of code in it (SetTuneCode `$6C96`, TitleWhiteRowsCode `$6FB8`,
PageTail66 `$6FCA`) stay data rows in the `.ann`, as does SpriteSetsTail `$6D4E`.

| File | Address (run time) | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `score-table.csv` | PageTailTemplate `$6B5C-$6BAB` (`$5D82`) | 80 | CSV: sprite, points (6 BCD digits) | AddScore `$99E7` | 20 score records; the code names record n by its low byte `$82` + 4n |
| `items.csv` | ItemRecords `$6BAC-$6C35` (`$5DD2-$5DFF`, `$5E82-$5EDD`) | 138 | rows: frame, score, b2, b3 | CollectPickup `$98B6`, SetWeapon `$98F3` (through TemplateForKind `$A652`) | the pickup kinds' records; `$6BD8-$6BD9` spare |
| `walk-lists.txt` | WalkLists `$6C36-$6C50` (`$5EDE`) | 27 | hex lists | AnimateActor `$9BB6` | walk frame lists: [n] then n frames (an actor's `+$05`) |
| `weapons.csv` | WeaponRecords `$6C51-$6C81` (`$5EF9`, `$5F82-$5FAB`) | 49 | rows of 7 bytes | HiroAttack `$926E` | the thrown weapons, kinds `$40-$46`, patched into WeaponTemplate `$64EE` |
| `touch-zones.csv` | TouchZoneRecords `$6C82-$6C95` (`$5FAC`) | 20 | CSV, signed | HiroInZone `$9529` | five zones: Hiro's Y and X relative to an actor, [from, to) |
| `sprite-sets.csv` | PageTail60 `$6CD6-$6D4D` (SizeClasses `$6082`) | 120 | CSV: half columns, rows, bytes a frame, address | InitActor `$A65D` | the 24 picture sets (set 0 the tiles; graphics/README.md) |
| `actor-templates.csv` | PageTail61 `$6D54-$6FB7` (`$6182-$65FF`) | 612 | CSV, 18 bytes a record | InitActor `$A65D` (through TemplateForKind `$A652`) | 34 actor templates copied to an actor's `+$03..+$14`; `_note` gives the kinds that use each (WeaponTemplate, SharedEnemyTemplate, HiroTemplate, TitlePieceTemplate among them) |
| `cell-colours.csv` | CellColoursTemplate `$703F-$7047` (CellColours `$66F7`) | 9 | CSV | RedrawCell `$8867` (`$88BA`), TitleColour `$A754` (the last six, TitleColours `$66FA`) | a revealed cell's attribute by the high nibble of its plane `$6C` byte |

## Other tables

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `kind-templates.csv` | KindTemplates `$7200-$7291` | 146 | CSV, 73 words | TemplateForKind `$A652` | per actor kind: the run-time address of its template or item record |
| `effects-48k.csv` | EffectTable `$8683-$872A` | 168 | CSV, 12 bytes a record | StartEffect `$855B`, EffectEnvelope `$85B6`, EffectSweep `$8609`, EffectSound `$8634` | the 48K's 14 beeper effects: time, sweep delay and period, mixer, sweep step, pitch, envelope |
| `start-values.csv` | GlobalsInit `$5C00-$5C14` | 21 | CSV: offset, value (`_note` the variable) | NewGame `$5CA9` (56 bytes to `$6642`), LoseEnergy `$9615` (the first 10, or 7 in a boss fight) | the start values of the globals: energy `$20`, ChargeStep 1, Lives `$05` (BCD), the score 0, the shown copies set unequal so the panel draws at once |
| `gates.csv` | GateRooms `$76D2` (GateClosed `$76D8`, GateX `$76DE`, GateSide `$76E4`, to `$76E9`) | 24 | CSV, one gate a row (stored column by column) | BarrierFind `$8F28`, RoomBarrier `$8F01`, BarrierOpen `$8F22`, NewGame `$5C4D` | the six invisible gates: room, closed flag, Hiro's X, the side |
| `title-actors.csv` | TitleActors `$7600-$76B5` | 182 | CSV, 7 bytes a record | TitleSequence `$A73E`, LoadTitlePieces `$A7D7` | the title scene's 26 actors (15, then 11 from `$7669`) |
| `title-order.csv` | TitleActorOrder `$76B6-$76CF` | 26 | CSV | TitleMovePiece `$A775` | the actor pages in the order the scene steps them |
| `scripts-76.txt` | ActorScripts `$76EA-$79FE` | 789 | hex lines of 16 | StartSequence `$917E`, SequenceFrameAt `$9191`, ActorFrameStep `$A6B1`, AnimateActor `$9BB6`, PathControl `$93FB`, MotionStep `$9253` | actor scripts (LOOP.md section 6) |
| `scripts-7a.txt` | ActorScriptsMore `$7A08`, SpawnTriples `$7B80`, SpawnedScript `$7B89` (to `$7BD7`) | 464 | hex lines, a named script starting a line | the same; SpawnSparks `$965F` (SpawnTriples) | Hiro's scripts (StrikeScript1, WalkScript, RunScript, ...), the spawn triples, the spawned actors' script; MessageNumber `$7B63` is a variable inside |
| `reverse-codes.csv` | ReverseCodes `$7A00-$7A07` | 8 | CSV | MirroredColumn `$8C51` | a 3-bit value mirrored: 0 4 2 6 1 5 3 7 |
| `packer-phases.csv` | PackerPhases `$FD98-$FDF4` | 93 | CSV: address word, mask | PackRow `$8CE5` | 31 records: the packer entries (PackUnits0 `$8D45` ...) and stops with the edge masks. The words are code addresses written as numbers: they must change if the packer moves |
| `unit-offsets.csv` | UnitByteOffsets `$FDF5-$FDFC` | 8 | CSV | SpriteScreenAddress `$8828` | the byte of a 3-byte group that holds unit n: 0 0 0 1 1 1 2 2 |
