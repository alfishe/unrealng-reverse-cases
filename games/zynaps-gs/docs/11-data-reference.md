# 11. Data reference

Every data entry of the game image (`$5C00`-`$FFFF`) and every variable of `src/game/game.ann`, in address order by
module, with the routines the recordings saw read and write it:

- `gsplay`: the GS game's own play: stage 2's TTD recording `r1` (Pentagon 128 + GS 512 KB, music) replayed by L1 over its frames 2951-4724, level 1 from the round start (1773 frames; zgsA's `work/zgsA/r1-play`, copied)
- `z48r1`: the 48K case's `r1` (`../zynaps/work/r1`): all 12 levels and the wrap, 75000 frames (the same code at the same addresses, without the GS hooks)
- `z48c2`: the 48K case's `c2` (`../zynaps/work/c2`): level 1 from the start, 1500 frames

The object records' fields are drawn in [7. Objects](07-objects.md), the player record and the weapons' variables in
[10. Gameplay logic](10-gameplay-logic.md). The driver's data in bank 1 (its stubs' parameters, the FX tables) is in
[9. Sound](09-sound.md).

Written by `python3 tools/fig_routines.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

## tilecopy

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5C00` | `TileGraphics` | 2048 | The 256 scenery tiles, 8 line pages of 256 bytes: line y of tile t at `$5C00` + 256 y + t. The bytes of TileSource (`$BC00`), which the 48K's Start copies here; read in play by BuildGlyph `$89C9` through TileSet `$7F6D` (c2: `$5C00-$63BA`, tile codes up to `$BA` in level 1). A tile drawn mirrored goes through BitReverse `$FB00`. | `BigSpriteCell`, `BuildGlyph`, `GlyphLine` | - |
| `$6400` | `WaveCellGraphics` | 1024 | The cells of the wave sprites: 8-byte linear glyphs for the sprite builders. The bytes of WaveCellSource (`$C400`). BuildCellSprite `$8EDB` reads `$64E0-$64FF` and `$65E0-$65FF` (c2: 5 entries), BuildBigSprite `$8F0C` 8 bytes a cell from `$66E0`. | `BigSpriteCell`, `BuildCellSprite` | - |

## leveldata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6800` | `PathStarts` | 28 | The start of each of the 28 enemy paths: (address - `$681C`) / 2. LaunchWave `$91EC`: E = PathStarts[the path number], the path pointer (record +`$1D`/+`$1E`) = `$681C` + 2E (`$9324-$9331`). A wave's enemies take the path of their kind unless the wave names one (bit 7 of its kind byte). c2: the bytes of paths 7 and 15 read (`$6807`, `$680F`). | `LaunchWave` | - |
| `$681C` | `PathCode` | 266 | The path bytecode of the enemies, 28 paths. RunPath `$94CB` (c2: 1405 entries): a byte with bit 7 set is the frame count of the command after it (0 = for ever); a command's bits 0-2 pick the routine from PathOps `$8114`, bits 3-6 are its parameter (7 = an extended op from PathExtOps `$8124`; extended op 3 is a loop with a word target). Every path starts on an even offset (the table holds offset / 2). c2 reads `$6864-$6866` and `$6888-$688B` (paths 7 and 15). | `PathReadWord`, `RunPath` | - |
| `$6926` | `WaveIndex` | 29 | Wave number -> the offset / 2 of its definition from `$6943` (29 waves). LaunchWave `$921A`: n = WaveIndex[A], the definition at `$6943` + 2n. c2: waves 7, 15 (`$692D`, `$6935`) launched. | `LaunchWave` | - |
| `$6943` | `WaveDefinitions` | 290 | The 29 wave definitions. Each: the bonus byte (wave record +1: bits 6-7 the drop, the rest the bonus score), the kind (bit 7: a path number and one more byte follow), the enemy count, the gap (frames between the enemies, the delay +`$1B` grows by it), then x, y for each enemy (y `$FF` = random row 0-127). x is halved and added to `$C0`, y to the script's row byte (`$9344-$936D`). Every definition has an even length. c2: `$698B-$6996` and `$69D9-$69DE` (waves 7 and 15). | `LaunchWave` | - |
| `$6A65` | `EnemyKinds` | 176 | The 22 enemy kinds, 8 bytes each. Copied by LaunchWave (`$9261-$92BB`) into the wave template `$803E`: +0 -> +`$18`, +1 the colour select (with WeaponRatingLevel `$80E9`: the set of KindColours; AND `$E3` -> +`$21`), +2 low nibble -> +`$0C` (score index), high -> +`$17` (speed), +3 -> +`$10` (X acceleration), +4 -> +`$14` (Y acceleration), +5 -> +`$07` (the handler kind of KindHandlers `$80FA`), +6 -> +`$25` (colour), +7 -> +`$0D` (hit points, `$FF` invulnerable). Kinds `$14` and up use sprite cache record 0. c2: kinds 7 and 15. | `LaunchWave` | - |
| `$6B15` | `KindColours` | 24 | 8 colour sets of 3 bytes: +`$19`, +`$20`, +`$22` of the enemy. Index ((WeaponRatingLevel + the kind's colour select) AND `$1C`) / 4 (`$9271-$9293`): a better armed ship meets the other set. c2: `$6B15-$6B1A`. | `LaunchWave` | - |
| `$6B2D` | `LevelTable` | 96 | The 12 levels, 8 bytes each. LevelStart `$B062` copies LevelTable[LevelOrder[+6]] (HL = `$6B25` + 8 (n + 1)) to the record's +`$0D`-+`$14`: +0 a byte (0 in all twelve, ScriptState `$81D7`, never read), +1/+2 the level script, +3 PlayFlags (`$FF`), +4/+5 ScrollCount (the start value `$40`, `$30`, `$38` or `$10`: the number of map columns ReplayScroll `$AF6B` builds at the level start, not a speed), +6 the scenery script number (`$81DD`), +7 ScriptLevelBias (`$81DE`, added to WeaponRating). | `SetLevelStart` | - |
| `$6B8D` | `LevelScripts` | 1820 | The level scripts of the 12 levels (the wave timelines). Run by WaveScriptStep `$AD66` (c2: 165 entries, the steps `$6B8D-$6BA6` of level 1). A step: the wait (ScriptWaitCount `$81E1` counts the WaveScriptStep runs, 8 frames each, up to it), the command: below `$40` an op of ScriptCommands `$81FF` (ops 7-12 take one or two words); `$40-$7F` a jump on the condition (ScriptConditions `$8223`, on the flags ScriptFlags `$81E2` of the last counter op) to the word; `$80-$BF` wave A AND `$3F` with the next byte as its row offset; `$C0-$FF` a conditional call. All twelve end with op 5 (the level's end) and a `$FF` wait. | `ScriptByte`, `ScriptWord`, `WaveScriptStep` | - |
| `$72A9` | `CellPatterns` | 56 | 7 colour patterns of 8 attributes for WorkCell `$FFD8`. ScriptSetCell `$8EC5` copies pattern n (a scenery script byte `$C0`+n) to `$FFD8-$FFDF`; a shape row's odd attribute byte `$B1`+2k takes WorkCell byte k (the scenery's colour scheme). c2: pattern 2 (`$72B9-$72C0`). | `ScriptSetCell` | - |
| `$72E1` | `SceneryScriptTable` | 78 | The 39 scenery scripts, indexed by ScriptNumber `$81DD`. RunScript `$8D7A` (c2: reads `$72E3` = script 1, then `$7321-$7324` = scripts 32 and 33 called by it). Levels use scripts 1-4, 6, 8-12 and 14; 15 is unused (it names groups 59 and 60, which point at ShapeTable). | `RunScript` | - |
| `$732F` | `SceneryScripts` | 363 | The scenery script bodies. A byte below `$80` places that object group (DrawGroup `$8DCA`) and yields until 16 more columns have scrolled; `$80` n calls script n (the variant mask saved); `$E0`+n sets the variant mask ScriptVariant `$8021` = n * 16; `$C0`+n loads colour pattern n; `$FF` ends (the top script restarts). | `RunScript`, `ScriptStep` | - |
| `$749A` | `GroupTable` | 122 | The 61 object groups, word pointers. DrawGroup `$8DCA` (`$8DD0`). c2 reads entries 30-38 (`$74D6-$74E7`). Entries 59 and 60 point at ShapeTable (`$7783`): only scenery script 15 uses them, and no level runs it. | `DrawGroup` | - |
| `$7514` | `ObjectGroups` | 623 | The group bodies: 3-byte objects, `$FF` the end. An object: byte 0 bits 0-4 the row, bit 5 drawn bottom up, bit 6 mirrored; byte 1 the variant bits (high nibble, AND ScriptVariant: none set, skipped) and the column (low nibble); byte 2 the shape. A byte `$80-$FE` is a sub-group (byte 1) taken when its bits 0-6 shifted left meet the variant mask (none in the data). c2: groups 30-38, `$7615-$76DD`. | `DrawGroup` | - |
| `$7783` | `ShapeTable` | 158 | The 79 shapes, word pointers. DrawGroup `$8E15` (index * 2 added to `$7783`). Entries 30 and 31 point at the 2 bytes before shape 32 (no group uses them). | `DrawGroup` | - |
| `$7821` | `Shapes` | 1593 | The shape bodies: the row count, then per row an attribute, a cell mask and the tiles. PlaceColumn `$8EA1` (c2: 209 entries): the attribute byte (odd: WorkCell byte (A - `$B1`) / 2), then a mask whose set bits, from bit 7, are the columns that get a tile; one tile byte per set bit, written to the map ring (the attribute to the attribute ring). | `DrawGroup`, `PlaceColumn` | - |

## effectdata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7E5A` | `EffectTable` | 48 | The 6 sound effects, 8 bytes each, from effect 1. EffectPlay `$B30C`: entry `$7E5A` + 8 (n - 1) -> EffectState `$7F8A-$7F90` and the segment lengths `$7F91`/`$7F92`: +0 pitch A, +1 its step, +2 pitch B, +3 its step, +4 the step change per segment, +5 the segments, +6 the flags, +7 the segment lengths (nibbles). c2 reads effects 1, 2 and 4 (`$7E5A-$7E69`, `$7E72-$7E79`). | `EffectPlay` | - |
| `$7E8A` | `EffectSpare` | 10 | 10 zero bytes after effect 6. No reader in c1/c2 (the request numbers in the code are 1-6 and `$32`). | - | - |
| `$7E94` | `ShipDescriptor` | 13 | The sprite descriptor of the ship (record `$F36C` +0/+1). +0/+1 the image (`$E008`), +4 and +6 the size of a shifted copy, +8 the height in rows (read by TestHitGrid `$9150`: `$7E9C`), +`$0B` the width (read `$7E9F`), +`$0C` the row mask. | `TestHitGrid` | - |
| `$7EA1` | `ExplosionAnim` | 13 | The explosion's sprite and animation record. Set by StartExplosion `$A293` (record +0/+1); MarkEnemyGrid `$90CB` reads +8/+`$0B` (`$7EA9`, `$7EAC`). | `MarkEnemyGrid` | - |
| `$7EAE` | `SightDescriptor` | 13 | The sight's sprite descriptor (record `$F600`, kind 6). TestHitGrid reads +8/+`$0B` (`$7EB6`, `$7EB9`). | `TestHitGrid` | - |
| `$7EBB` | `PodAnim` | 13 | The weapon pod's sprite and animation record. Set by ExplosionToPod `$A2D6`; MarkEnemyGrid reads `$7EC3`, `$7EC6`. | `MarkEnemyGrid` | - |
| `$7EC8` | `LaserDescriptor` | 13 | The laser shot's sprite descriptor (the four records from `$F4F8`). TestHitGrid reads `$7ED0`, `$7ED3`. | `EnemyGone`, `TestHitGrid` | - |
| `$7ED5` | `ShotDescriptor` | 13 | The enemy shot's and the plasma ball's sprite descriptor. MarkEnemyGrid and TestHitGrid read `$7EDD`, `$7EE0`. | `MarkEnemyGrid`, `TestHitGrid` | - |
| `$7EE2` | `SpriteCache` | 112 | The sprite cache: record 0 and records 1-6, 16 bytes each. GetSpriteCache `$93A7` (c2: 7 entries): kinds `$14` and up use record 0 (`$7EE2`, its image at `$C008`, 7 x 7 cells) without caching; the others search records 1-6 for one of their kind (+`$0E` = kind OR `$80`, +`$0D` the use count) or take a free one. +0/+1 the image buffer (`$E748`, `$E988`, `$EBC8`, `$EE08`), +4/+6 the size (`$48`, `$60`), +8 the rows, +`$0B` the width, +`$0C` the row mask, +`$0F` the record bit. LevelSetUp `$8D28` clears the six use counts. | `EnemyGone`, `GetSpriteCache`, `LaunchWave`, `LoadCellSprite`, `MarkEnemyGrid` +2 | `EnemyGone`, `GetSpriteCache`, `LaunchWave`, `LevelSetUp`, `SpriteBuildDone` |
| `$7F52` | `SpareCacheRecord` | 16 | A seventh record of the same layout, out of the search (B = 6). No reader or writer in c1/c2; its values follow the pattern of records 5 and 6 (buffer `$E988`, size `$60`). | - | - |

## gamevars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7F62` | `PassCount` | 1 | +1 each play pass (PlayInterrupt `$AA03`); bit 0 = an odd pass. c2 (TTD frames 300-316): +1 every 2 frames. Read by the explosion step `$A1C8`, the panel `$AB13`. | `ExplosionStep`, `PanelFrame`, `PlayInterrupt`, `l_A9EF` | `PlayInterrupt`, `l_A9EF` |
| `$7F63` | `PassBit` | 1 | Rotated left each pass (`$AA0A`): AND an object's bit +`$24` picks the objects that act this pass. EnemyFire `$A0FE`, the fuel tick (bit 0) in PlayerHandler `$9A5B`. | `EnemyFire`, `PlayInterrupt`, `PlayerHandler`, `l_A9EF` | `PlayInterrupt`, `l_A9EF` |
| `$7F64` | `PassDepth` | 1 | +1 on the entry of PlayInterrupt, -1 at its end: 1 = not nested | `PlayChain`, `PlayInterrupt`, `PlayInterruptExit`, `PlayPass`, `l_A9EF` | `PlayInterrupt`, `PlayInterruptExit`, `PlayLoop`, `l_A9EF` |
| `$7F65` | `PassPhase` | 1 | The play pass phase 1-4 then 0; 4 on entry: the pass is skipped (`$A9FB`). Phase 1 starts a pass (`$AA49`), 2 runs the level script (`$AAAD`), odd phases MarkEnemyGrid. | `NewSpanNode`, `PlayInterrupt`, `PlayPass`, `ScrollControl`, `l_A9EF` | `ChainEnd`, `PlayInterrupt`, `PlayLoop`, `l_A9EF` |
| `$7F66` | `ChainStep` | 2 | The drawing chain's current step: `$AAE5`, +5 each phase (PlayChain `$AACC`) | `PlayChain` | `PlayChain`, `PlayInterrupt`, `l_A9EF` |
| `$7F68` | `NodeFreeList` | 2 | The head of the span node free list (pool `$F800`; LevelSetUp `$8C3E`) | `PopNode`, `PushNode` | `LevelSetUp`, `PopNode`, `PushNode` |
| `$7F6A` | `ShiftPage` | 1 | The glyph cache page of the fine scroll phase: `$C0` `$C8` `$D8` `$D0` (a Gray code) | `RowStart`, `ScrollControl` | `PlayLoop`, `ScrollControl` |
| `$7F6B` | `FineScrollToggle` | 1 | `$08` or `$10`, XORed into ShiftPage by ScrollControl `$A9D2` | `ScrollControl` | `PlayLoop`, `ScrollControl` |
| `$7F6C` | `ScrollThisPass` | 1 | `$FF` when the pass scrolls one fine step, 0 when not; PathOpScroll `$9640` tests bit 0 | `PathOpScroll` | `ScrollControl` |
| `$7F6D` | `TileSet` | 2 | The tile set pointer `$5C00` of BuildGlyph `$89C9` (L replaced by the tile) | `BuildGlyph` | - |
| `$7F6F` | `RowsLeft` | 1 | The renderer's row counter, 18 down to 0 (DrawPlayfield `$85CA`) | `RowStar` | `DrawPlayfield`, `RowStar` |
| `$7F70` | `EmptyRows` | 1 | Rows without nodes counted by the scroll step (`$8AED`) | `ScrollStep` | `ScrollStep` |
| `$7F71` | `RandomSeed` | 5 | The five bytes of the random number generator (Random `$8544`, seeded by `$8516`) | `EnemyFire`, `Random` | `Random` |
| `$7F76` | `SkipDraw` | 1 | Bit 0 set: DrawGroup places nothing (the catch-up loop `$AF6B`) | `DrawGroup` | `ReplayScroll` |
| `$7F77` | `PanelBurst` | 1 | Set to 6 by FireLaser `$9C1D` when 0; the panel (`$AB13`) counts it down, a pair of cells moving out | `FireLaser`, `PanelFrame` | `FireLaser`, `PanelFrame` |
| `$7F78` | `SpinnerFrame` | 1 | The panel spinners' frame 0-15, +1 each odd pass (`$AB13`) | `PanelFrame` | `PanelFrame` |
| `$7F79` | `SpinnerColour` | 1 | The spinners' ink, + SpinnerColourStep each odd pass, bouncing between 1 and 7 | `PanelFrame`, `PlayerHandler` | `PanelFrame` |
| `$7F7A` | `SpinnerColourStep` | 1 | +1 or -1 | `PanelFrame` | `PanelFrame` |
| `$7F7B` | `DeathTimer` | 1 | `$FF` while the ship lives; `$16` at its death, counted down (PlayerDying); not `$FF` stops the scroll and the level script | `PlayerHandler`, `ScrollControl`, `WaveScriptStep` | `KillPlayer`, `PlayerHandler`, `RoundPlaySetup` |
| `$7F7C` | `EndPending` | 1 | The end of play asked for: 1 a life lost, 2 the level done (script op 5), 4 abort | `CheckPauseAndEnd` | `CmdLevelEnd`, `PlayLoop`, `PlayerHandler` |
| `$7F7D` | `EndCode` | 1 | EndPending moved here by `$ABD5`: ends the play loop (`$B1E9`) | `PlayLoopBranch`, `PlayLoopCheck`, `PlayLoopTest` | `CheckPauseAndEnd`, `PlayLoop` |
| `$7F7E` | `RowBeep` | 1 | The beeper bit toggled XOR `$18` per playfield row (one of the three explosion-noise toggles; silent while the mask is 0) | `RowStart` | `RowStart` |
| `$7F7F` | `RowBeepMask` | 1 | Its AND mask: the bit shifted out of SoundPattern1 each pass (`$AA30`) | `RowStart` | `PlayInterrupt` |
| `$7F80` | `SoundPattern1` | 2 | A 16-bit pattern shifted left each pass; `$FD00` for an explosion (StartExplosion `$A293`) | `PlayInterrupt` | `BigEnemyHandler`, `PlayInterrupt`, `StartExplosion` |
| `$7F82` | `ObjectBeep` | 1 | The beeper bit toggled per object strip (`$8F9B`) | `ObjectStrips` | `ObjectStrips` |
| `$7F83` | `ObjectBeepMask` | 1 | Its mask: the bit of SoundPattern2 (`$AA3B`) | `ObjectStrips` | `PlayInterrupt` |
| `$7F84` | `SoundPattern2` | 2 | `$EDB2` for an explosion | `PlayInterrupt` | `BigEnemyHandler`, `PlayInterrupt`, `StartExplosion` |
| `$7F86` | `SlotBeep` | 1 | The beeper bit toggled per object slot (RunObjects `$9463`) | `RunObjects` | `RunObjects` |
| `$7F87` | `SlotBeepMask` | 1 | Its mask: the bit of SoundPattern3 (`$AA46`) | `RunObjects` | `PlayInterrupt` |
| `$7F88` | `SoundPattern3` | 2 | `$D6ED` for an explosion | `PlayInterrupt` | `BigEnemyHandler`, `PlayInterrupt`, `StartExplosion` |
| `$7F8A` | `EffectState` | 7 | The playing effect's +0-+6 (EffectPlay `$B30C`), stepped by `$B379` | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` |
| `$7F91` | `SegLenA` | 1 | The effect's segment length A (the low nibble of +7) | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` |
| `$7F92` | `SegLenB` | 1 | Segment length B (the high nibble) | `EffectRestore` | `EffectPlay` |
| `$7F93` | `PitchA` | 1 | The effect's pitch A | `EffectAfterJobs`, `EffectHalf`, `EffectRestore` | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` |
| `$7F94` | `PitchB` | 1 | Pitch B | `EffectHalf`, `EffectRestore` | `EffectAfterJobs`, `EffectPlay`, `EffectRestore` |
| `$7F95` | `EffectFrames` | 1 | The frames left in the segment | `EffectAfterJobs`, `EffectRestore` | `EffectAfterJobs`, `EffectFirstLen`, `EffectPlay`, `EffectRestore` |
| `$7F96` | `EffectTick` | 1 | `$80` from the title interrupt `$A9E4` and a new effect request, `$FF` from PlayInterrupt. The effect's tone loop runs until an interrupt changes it. | `EffectAfterJobs`, `EffectRestore`, `EffectTickCheck`, `EffectTickRead` | `EffectAfterJobs`, `EffectRestore`, `PlayInterrupt`, `RequestEffect`, `TitleInterrupt` +1 |
| `$7F97` | `CurrentEffect` | 1 | The effect playing (0 none, `$80` stop); a request lower than it is refused (RequestEffect `$B2F0`) | `EffectPlay`, `RequestEffect` | `EffectEnd`, `PlayLoop`, `RequestEffect` |
| `$7F98` | `CurrentPlayer` | 1 | 1 or 2 (AddScore `$A495`, PrintPlayerScore `$A4BF`; XOR 3 at the change, `$B16D`) | `AddScore`, `NextPlayer`, `PrintPlayerScore`, `RoundSetup`, `ScoreJob` | `NextPlayer` |
| `$7F99` | `PlayerRecord` | 2 | The current player's record: `$7F9C` or `$7FCC` (10 readers in c1/c2) | `CmdCheckpoint`, `CmdLevelEnd`, `DrawLives`, `FireLaser`, `LevelDone` +10 | `NextPlayer` |
| `$7F9B` | `Players` | 1 | 1 or 2 (SelectPlayers `$A790`; ChangePlayer `$B149`) | `NextPlayer` | - |

## playerdata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7F9C` | `Player1` | 48 | Player 1's record (48 bytes). +0-+3 the score (4 BCD bytes, high first; AddScore `$A489`), +4 the lives (DrawLives `$A4EF`), +5 the lives lost in the level (LevelStart clears it, PlayerDied `$B119` adds 1), +6 the level order index (LevelDone `$B174`: +1 mod 12), +7 the pod selector 0-4, +8 the side weapon (0 none, 2 plasma, 3 missiles, 4 seeker; script op 5 clears +8/+9), +9 the double plasma flag, +`$0A` the laser level 0-3, +`$0B` the speed `$40-$A0`, +`$0C` the extra-life index into ExtraLifeScores, +`$0D`-+`$2F` the level state (LevelTable's 8 bytes, ScriptStateInit's 5, the rest of ScriptState). | `AddScore`, `DrawLives`, `FireLaser`, `FuelOut`, `LevelDone` +13 | `AddScore`, `CmdCheckpoint`, `CmdLevelEnd`, `FuelOut`, `LevelDone` +5 |
| `$7FCC` | `Player2` | 48 | Player 2's record (48 bytes), the same fields. PlayersSetup `$AFB7` zeroes both records (96 bytes from `$7F9C`), gives player 2 three lives when two play, else none. | `DrawLives`, `FuelOut`, `NextPlayer`, `PanelFrame`, `PlayerDied` +6 | `FuelOut`, `NextPlayer`, `PlayerDied` |
| `$7FFC` | `BcdScratch` | 4 | PrintBcd's copy of the number it prints (`$A43E`) | `PrintBcd`, `PrintBcdLeading`, `PrintBcdRest`, `PrintBcdRestNext` | `PrintBcd`, `PrintBcdLeading`, `PrintBcdRest`, `PrintBcdRestNext` |

## systemvars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8003` | `LevelOrder` | 12 | The order of the 12 levels: 0 1 2, six of 3-8 shuffled, 9 10 11. PlayersSetup `$AFB7` fills `$8006-$800B` with the levels 3-8 in a random order for each game; LevelStart `$B06F` takes LevelOrder[+6]. The tape holds 0 1 2 0 0 0 0 0 0 9 10 11. | `SetLevelStart` | - |
| `$800F` | `ExtraLifeScores` | 6 | The scores of the extra lives: the score's +1 byte (BCD) 01 03 05 07 09, then `$FF`. `$AC8A`: when the score's +1 byte is at least ExtraLifeScores[+`$0C`], +`$0C` and the lives go up: extra lives at 10000, 30000, 50000, 70000 and 90000. | `ScoreJob`, `ScoreJobRating` | - |
| `$8015` | `GlyphAlloc` | 3 | The glyph allocator: the slot index, the bitmap byte's low address (`$E0-$FF`), the bit mask. Read and written by AllocGlyphs `$8912`. | `AllocGlyphs` | `AllocGlyphs` |
| `$8018` | `MainSP` | 2 | The main stack pointer, saved while the scenery coroutine runs (`$8D60`, `$8D69`) | `YieldScript` | `ResumeScript` |
| `$801A` | `ScriptSP` | 2 | The scenery coroutine's stack pointer (its stack top `$FDFB`, StartScript `$8D35`) | `ResumeScript` | `StartScript`, `YieldScript` |
| `$801C` | `ScrollColumn` | 2 | The map ring pointer of the leading column (`$B760` at the level start; +1 per scroll step) | `ScrollStep`, `StartColumn` | `LevelSetUp`, `ScrollStep` |
| `$801E` | `ScriptColumn` | 1 | The column where the next group goes, +16 per group (ResumeScript `$8D45`) | `DrawGroup`, `ResumeScript` | `LevelStart`, `ResumeScript` |
| `$801F` | `ScriptRoom` | 1 | The columns scrolled since the last group: +1 per scroll step, -16 per group | `ResumeScript`, `ScrollStep` | `LevelStart`, `ResumeScript`, `ScrollStep` |
| `$8020` | `ScriptBusy` | 1 | `$FF` while a group is being placed, 0 after it | `ResumeScript`, `RunScript`, `ScriptStep` | `ResumeScript`, `RunScript`, `ScriptStep`, `StartScript` |
| `$8021` | `ScriptVariant` | 1 | The variant mask (high nibble) the group objects are tested with; `$F0` on the tape | `DrawGroup`, `RunScript`, `ScriptStep` | `RunScript`, `ScriptReturn`, `ScriptStep` |
| `$8022` | `ScrollMap` | 2 | The scenery map position: cell = ScrollMap + 128 Y + X (`$B730` at the level start; SceneryCell `$99FF`) | `SceneryCell`, `ScrollStep` | `LevelSetUp`, `ScrollStep` |
| `$8024` | `DrawQueueRead` | 1 | The sprite build queue's read index 0-7 (`$ACAD`) | `SpriteBuildEmpty`, `SpriteBuildNext` | `LevelSetUp`, `SpriteBuildEmpty`, `SpriteBuildNext` |
| `$8025` | `DrawQueueWrite` | 1 | Its write index (QueueSpriteLoad `$9441`) | `QueueSpriteLoad`, `SpriteBuildNext` | `LevelSetUp`, `QueueSpriteLoad` |
| `$8026` | `DrawQueue` | 24 | 8 entries of 3 bytes: the kind, the record address | `SpriteBuildEmpty`, `SpriteBuildNext` | `QueueSpriteLoad` |
| `$803E` | `WaveTemplate` | 44 | The 44-byte object record LaunchWave builds once a wave and copies to each enemy. Zeroed (`$924A`), filled from the kind (`$9261-$92BB`) and the sprite cache (`$92C2`), then copied into the record IY: +0-+8 and +`$0B`-+`$2B` (`$9304-$9313`; +9/+`$0A` stay the record's own). | `LaunchWave` | `LaunchWave` |
| `$806A` | `WavePaths` | 8 | The path number of each enemy of the wave being launched (`$9231-$9247`) | `LaunchWave` | `LaunchWave` |
| `$8072` | `FreeEnemySlots` | 1 | Free slots of the 8 enemy records at `$F398` (5 at the level start) | `FreeEnemySlot`, `LaunchWave`, `TakeEnemySlot` | `FreeEnemySlot`, `LevelSetUp`, `ScatterDebris`, `TakeEnemySlot` |
| `$8073` | `WavesAllowed` | 1 | Wave records that may be in use (6 at the level start); LaunchWave -1, the wave's end +1 | `EnemyGone`, `LaunchWave` | `EnemyGone`, `LaunchWave`, `LevelSetUp` |
| `$8074` | `EnemyShotsLeft` | 1 | Enemy shots that may still start (3 at the level start; EnemyFire `$A113`) | `EnemyFire`, `FreeObject` | `EnemyFire`, `FreeObject`, `LevelSetUp` |
| `$8075` | `WaveRecords` | 18 | 6 wave records of 3 bytes: the live count (`$FF` free, bit 7 one escaped), the bonus byte, the kind | `EnemyGone`, `LaunchWave` | `EnemyGone`, `LaunchWave`, `LevelSetUp` |
| `$8087` | `SpriteCacheMask` | 1 | A bit per used sprite cache record (`$93A7`) | `EnemyGone`, `GetSpriteCache` | `EnemyGone`, `GetSpriteCache`, `LevelSetUp` |
| `$8088` | `SpriteCacheFree` | 16 | The free record of a use mask: low nibble, or the high one by bit 4 of the kind (`$93D8`) | `GetSpriteCache` | - |
| `$8098` | `BigSpriteMap1` | 9 | A 7 x 9 cell map (one bit a cell) for BuildBigSprite with A = 1 | `BuildBigSprite` | - |
| `$80A1` | `BigSpriteMap2` | 9 | The cell map for BuildBigSprite with A <> 1 | `BuildBigSprite` | - |
| `$80AA` | `PrintPos` | 2 | The print position, an attribute address `$5800-$5AFF` (PrintChar `$A33B`, print codes 3-6) | `PrintChar`, `PrintCharKind`, `PrintSetColumn`, `PrintSetRow` | `PrintChar`, `PrintCharKind`, `PrintPlayerScore`, `PrintSetColumn`, `PrintSetRow` |
| `$80AC` | `PrintAttr` | 1 | The printed characters' attribute (print codes 0-2) | `PrintChar`, `PrintCharKind` | `PrintBcd`, `PrintBcdLeadNext`, `PrintBcdLeading`, `PrintPlayerScore` |
| `$80AD` | `PrintPending` | 1 | Below `$20`: a print code waiting for its byte; `$20` none (PrintChar `$A326`) | `PrintChar`, `PrintCharSave`, `PrintString` | `PrintChar`, `PrintCharDone`, `PrintCodeDone` |
| `$80AE` | `RasterTable` | 2 | The colour table of the menu raster interrupt (`$A520`): `$FC20` | `MenuRasterInterrupt` | `MenuScreenSetup` |
| `$80B0` | `RasterLines` | 1 | The scan lines the menu raster colours: 168 or 112 | `MenuRasterInterrupt` | `LevelStart`, `MenuScreenSetup` |
| `$80B1` | `RasterList` | 2 | The colour list ExpandNextColours takes (`$A5B0`) | - | - |
| `$80B3` | `RasterSpare` | 6 | Six bytes no routine reads or writes in c1/c2 | - | - |
| `$80B9` | `RasterFrames` | 1 | Frames the menu raster still runs (-1 a frame, `$A578`) | `MenuRasterInterrupt`, `WaitMenuRasterEnd` | `LevelStart`, `MenuRasterInterrupt` |
| `$80BA` | `LaserShotsFree` | 1 | Laser shots not in flight (4 at most, `$B2D1`); fire when it plus the laser level is 4 or more | `FireLaser`, `LaserHandler` | `FireLaser`, `LaserHandler`, `ShotsSetup` |
| `$80BB` | `LaserHitMask` | 1 | Per pass: the enemy bits hit by the ship or a laser (TestHitGrid `$9150`) | `BigEnemyHandler`, `EnemyHandler`, `LockableHandler`, `SelfDestruct` | `RunObjects`, `SelfDestruct`, `TestHitGrid` |
| `$80BC` | `ColourCycle` | 1 | 8, `$10`, `$18`: +8 each pass (`$AA1B`); the pods' flashing colour | `PlayInterrupt`, `PodStep`, `l_A9EF` | `PlayInterrupt`, `l_A9EF` |
| `$80BD` | `HarmlessMaskA` | 1 | Enemy bits that do not kill the ship nor stop a laser (StartExplosion, ExplosionToPod) | `ExplosionToPod`, `FreeEnemySlot`, `LaserHandler`, `PlayerHandler`, `StartExplosion` +1 | `ExplosionToPod`, `FreeEnemySlot`, `LevelSetUp`, `StartExplosion`, `StartExplosionQuiet` |
| `$80BE` | `HarmlessMaskB` | 1 | See HarmlessMaskA | `ExplosionToPod`, `FreeEnemySlot`, `LaserHandler`, `PlayerHandler`, `StartExplosion` +1 | `ExplosionToPod`, `FreeEnemySlot`, `LevelSetUp`, `StartExplosion`, `StartExplosionQuiet` |
| `$80BF` | `ShipHistoryIndex` | 1 | The index into ShipHistory (PlayerHandler `$9AF3`) | `PlayerHandler` | `PlayerHandler`, `PlayerSetup` |
| `$80C0` | `ShipHistory` | 32 | The ship's last 8 positions, 4 bytes each (X fraction, X, Y fraction, Y); the sight follows the oldest. PlayerSetUp `$B21C` fills it by pushing 16 words below `$80E0` (SP = `$80E0` at `$B253`). | - | `PlayerHandler` |
| `$80E0` | `LockTarget` | 2 | The enemy record the sight locked on (`$9FFC`) | - | - |
| `$80E2` | `LockMask` | 1 | Its collision bit, 0 no lock | `BigEnemyHandler`, `LockableHandler` | `BigEnemyHandler`, `LockableHandler` |
| `$80E3` | `MissileHitMask` | 1 | Per pass: the enemies the homing missile hits (cleared by RunObjects `$94B2`) | `BigEnemyHandler`, `LockableHandler` | `RunObjects` |
| `$80E4` | `SightMask` | 1 | Per pass: the enemies under the sight | `BigEnemyHandler`, `LockableHandler` | `RunObjects` |
| `$80E5` | `PlasmaHitMask` | 1 | Per pass: the enemies the plasma or the seeker hit | `EnemyHandler` | `RunObjects` |
| `$80E6` | `Fuel` | 1 | The fuel / power timer: -1 on passes with PassBit bit 0, `$B4` from a full pod cycle, halved when a pod is lost | `PanelFrame`, `PlayerHandler`, `PodStep` | `FuelOut`, `PlayerHandler`, `PodStep`, `RoundPlaySetup` |
| `$80E7` | `WeaponRatingMask` | 1 | `$FF` or `$30` (WeaponRating `$9B75`); EnemyFire `$A0F6` reads it | `EnemyFire` | `WeaponRating` |
| `$80E8` | `WeaponRatingValue` | 1 | The enemies' fire chance (WeaponRating `$9B75`: + ScriptLevelBias); read only by EnemyFire `$A109` (Random below it: a shot) | `EnemyFire` | `WeaponRating` |
| `$80E9` | `WeaponRatingLevel` | 1 | 0 or 8: picks the KindColours set (LaunchWave `$9271`) | `LaunchWave` | `WeaponRating` |

## handlertables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$80EA` | `SideWeaponFrames` | 6 | The side weapon's routine per pass: `$9C83` plasma, `$9CCA` homing, `$9CFE` seeker (index +8 - 2, `$9B2E`) | - | - |
| `$80F0` | `PodActions` | 10 | The pod actions: `$9D4C` speed, `$9D5D` laser, `$9D68` plasma, `$9DA5` homing, `$9DDD` seeker (index = the selector; `$A217`, `$B284`) | - | - |
| `$80FA` | `KindHandlers` | 26 | The object handlers by kind (+`$07`): 0 player, 1 laser, 2 enemy, 3 explosion, 4 pod, 5 enemy shot, 6 sight, 7 seeker, 8 lockable, 9 plasma, 10 missile, 11 enemy, 12 big enemy. RunObjects `$946F`/`$9487` (c2: 6080 JumpTable entries in all). | `JumpTable` | - |
| `$8114` | `PathOps` | 16 | The path commands 0-7 (bits 0-2 of a command): RunPath `$94DC` | `JumpTable` | - |
| `$8124` | `PathExtOps` | 32 | The 16 extended path ops (bits 3-6 of command 7): PathOpExtended `$950F` | `JumpTable` | - |
| `$8144` | `SineTable` | 64 | A signed sine, 64 steps a turn (`$20` = 1): SetVelocity `$98F1` reads it (c2: 21 entries) | `SetVelocity` | - |

## controldata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8184` | `FireHeld` | 1 | Passes fire has been held, 0 released (ReadControls `$A725`) | `PlayerHandler`, `PodStep`, `ReadControls` | `ReadControls` |
| `$8185` | `FireChanged` | 1 | `$FF` when fire was pressed or released since the last read (`$A73C`) | `PlayerHandler` | `ReadControls` |
| `$8186` | `ControlBits` | 1 | Bit 0 right, 1 left, 2 down, 3 up (`$A742`) | `PlayerHandler` | `ReadControls` |
| `$8187` | `JoystickFlags` | 1 | Bit 0 Kempston, bit 1 Sinclair rather than cursor | `ReadControls` | `ReadControls` |
| `$8188` | `KeyTable` | 10 | 5 keys (fire up down left right) as port high byte and bit mask; P L SS A S by default | `ReadControls` | - |
| `$8192` | `KeyScanRows` | 6 | The half-rows WaitKeyPress scans: `$FE` `$FD` `$FB` `$DF` `$BF` `$7F` | - | - |
| `$8198` | `KeyNames` | 40 | The 40 key names in the order of the half-rows `$FEFE`..`$7FFE`; 0-3 = messages 9-12 (CS SS SP EN) | - | - |
| `$81C0` | `LifeSteps` | 5 | The attribute steps between the life marks (DrawLives `$A4EF` reads 6 bytes: the 6th is EventRequests, unused) | `DrawLives` | - |
| `$81C5` | `EventRequests` | 1 | A bit per job asked for (bit 7 first; EventDispatch `$AC07`) | `AddScore`, `DrawLives`, `EventPending`, `PlayLoop`, `PodStep` +2 | `AddScore`, `EventAny`, `PlayLoop`, `PodStep`, `QueueSpriteLoad` +1 |
| `$81C6` | `EventMask` | 1 | The enabled jobs (`$FF` from the play loop's start) | `EffectJob`, `EventAny`, `EventEnabled`, `PodIconJob`, `ScoreJob` +1 | `EffectJob`, `EventDone`, `PlayLoop`, `PodIconJob`, `ScoreJob` +1 |
| `$81C7` | `EventHandlers` | 16 | The 8 job routines, bit 7 first | `JumpTable` | - |
| `$81D7` | `ScriptState` | 35 | The level script's state (35 bytes, `$AD56` from the player record, `$AED2` back). +0-+7 come from LevelTable, +8-+`$0C` from ScriptStateInit, the rest is the call stack. +0 (`$81D7`) is LevelTable's first byte (0 in every level; nothing reads it). | `CmdCheckpoint`, `CmdDecrement`, `CmdScrollStop`, `MoveStars`, `PlayInterrupt` +11 | `CmdDecrement`, `CmdScrollStop`, `CmdStore`, `ReplayScroll`, `RestoreCheckpoint` +7 |
| `$81FA` | `ScriptStateInit` | 5 | Copied to the record's +`$15`-+`$19` at a level's start: the stack pointer `$81F6`, wait 0, flags 0, restart 0 | `SetLevelStart` | - |
| `$81FF` | `ScriptCommands` | 36 | The level script ops 0-17 (JumpTable from WaveScriptStep `$AD86`) | `JumpTable` | - |
| `$8223` | `ScriptConditions` | 14 | The 7 jump conditions on ScriptFlags: always, Z, NZ, C, NC, P, M (`$AE00`) | `JumpTable` | - |

## scoredata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8231` | `PointsTable` | 48 | 12 awards x 4 BCD bytes: 0 25 50 75 100 150 200 250 500 1000 2000 5000. AddScore `$A489` adds entry A from `$8234` + 4A down (c2: 9 entries reading `$8235-$823C`: 25 and 50). | `AddScore` | - |
| `$8261` | `HiScoreTable` | 70 | The high-score table: 5 entries of a print string (position, initials) and a 4-byte BCD score. PrintString `$A401` prints the strings, PrintBcd (`$A43E`) the scores; HighScoreEntry inserts a new one. The editable text: src/res/text/hiscores.hsc.txt. | - | - |
| `$82A7` | `ColoursTop` | 39 | A run-length colour list: 48 lines into `$FC20` (MenuScreenSetup `$A692`, SelectPlayers `$A799`) | `ExpandColours` | - |
| `$82CE` | `ColoursMenu` | 9 | 120 lines into `$FC50` (MenuScreenSetup `$A69D`) | `ExpandColours` | - |
| `$82D7` | `ColoursHighlight` | 9 | 64 lines into `$FC50` (SelectPlayers `$A7A8`, RedefineKeys `$A5D5`) | - | - |
| `$82E0` | `ColoursBar` | 14 | The sweeping bar of SelectPlayers (`$A7BB`); its `$FF` at `$82ED` is also the message list's start | `PrintMessage` | - |

## texts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$82EE` | `Messages` | 552 | The 28 messages. The print codes (PrintChar `$A321`): a byte below `$20` takes the next byte: 0 attribute, 1 ink, 2 paper, 3 column, 4 row, 5 column + n, 6 row + n; `$1B` n prints message n; `$80` and up are the game's glyphs (`$B54F`). c1: PrintMessage 98 entries, PrintString 103. GS: two messages read "PRESS 1,2,3 & FIRE" (`$8479-$848F`) where the 48K credits "MUSIC STEVE TURNER": the beeper title tune is gone (src/res/text/messages.msg.txt holds the GS text). | `PrintMessage`, `PrintString` | `RoundSetup` |

## playfield

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$85E4` | `SentinelNode` | 3 | The span node that ends every row: handler RowEnd, then a 0 byte. A three-byte node: the word `$85E7` (RowEnd) and a 0. An empty row's head field (+6/+7 of its record) points here; the last node of every row links here. LevelSetUp writes it into all 18 records. | - | - |

## scroll

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8C31` | `SpanHandlers` | 10 | The span handler of each run width 0-4. SpanDraw0, SpanDraw1, SpanDraw2, SpanDraw3, SpanDraw4. | `SetSpanHandler` | - |

## scenery

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8EC4` | `PlaceColumnSpare` | 1 | A RET byte after the loop's JP: never reached | - | - |

## movers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$974C` | `LandingFlag` | 1 | PathOpLand's per-frame flag and retry count. Bit 7: an object has used PathOpLand in this pass (RunObjects clears it each pass); bits 0-6: the failed tries since the last landing. | `PathOpLand`, `RunObjects` | `PathOpLand`, `PlayLoop`, `RunObjects` |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A1EB` | `UnusedRet` | 1 | A RET no code reaches. `$C9`: a RET after the JP of ExplosionStep; no jump or call leads here (a leftover of an edit of the routine). | - | - |

## print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A3A3` | `PrintControlTable` | 14 | The routines of the print codes 0-6. Each takes its operand in C: PrintSetAttr, PrintSetInk, PrintSetPaper, PrintSetColumn, PrintSetRow, PrintColumnRight, PrintRowDown. | `PrintChar`, `PrintCharSave` | - |

## hiscore

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A8B6` | `HighScoreHaltLoop` | 1 | GS: the HALT loop's DJNZ `$A8B5` as bytes (`$10` `$FD`): the early exits land on its `$FD`. The walk of the code cannot hold both: the DJNZ at `$A8B6` and the jump target `$A8B7` inside it. The two bytes assemble the same. | - | - |

## panel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A919` | `SpinnerFrames` | 16 | The 16 frames of a spinner: offsets into SpinnerImages. Even: a shape top down; odd: the end of a shape, bottom up. | `DrawSpinner` | - |
| `$A929` | `SpinnerImages` | 80 | The spinner shapes: 5 x 16 rows, the left 8 pixels. From a thin diagonal line (`$A929`) to a full ring (`$A969`): the turning disc seen from its edge to its face. | `DrawSpinner` | - |

## rounds

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B0FE` | `HiScoreSpare` | 1 | a lone RET (`$C9`) no code reaches | - | - |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B111` | `EndHandlers` | 8 | the end codes 1-4: PlayerDied, LevelDone, AbortGame, AbortGame | `JumpTable` | - |

## tune

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B4A9` | `TuneSpare` | 4 | AND A; RET and two zeros no code reaches | - | - |
| `$B4AD` | `TuneDuration` | 2 | the note length in loop passes: the high byte set by the `$C0`+ commands, the low byte 0 | - | - |

## icons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B4AF` | `PodIcons` | 160 | five 16 x 16 icons, 32 bytes each: the left cell's 8 lines, the right's, then the lower row's two. Drawn by PodIconJob at rows 20-21 (`$5086`/`$50A6`), columns 6-7, icon n = the player record's +7 (the selected pod, 0-4). Bytes in the order IconRow reads them: TL, TR, BL, BR, each top line first. | `IconLine`, `IconRow` | - |

## font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B54F` | `Glyphs` | 432 | 54 glyphs of 8 x 8, the print codes `$80-$B5`. The print routine (`$A321`) takes HL = code * 8 + `$B14F`, so code `$80` is `$B54F` and `$B5` the last (`$B6F7`). The editable form: src/res/fonts/glyphs.font.png (tools/res_font.py), 9 glyphs a row. | - | - |

## start

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B700` | `data_B700` | 47 | data_B700 | `BuildCell`, `BuildGlyph`, `CmdResetRecords`, `LevelSetUp`, `MoveStars` +7 | `BuildCell`, `CmdResetRecords`, `LevelSetUp`, `PlaceColumn`, `ScrollStep` |

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B72F` | `MapRingSpace` | 1233 | The map ring from `$B72F` on (zero on the tape). In play: the map ring `$B700-$BFFF`, the playfield's 18 rows of 128 bytes, two rows a page; a row's record holds its pointer (+0/+1 = `$B71F` + `$80` * row, set by LevelSetUp `$8C3B`). The scenery scripts write tile codes into it, RowStart (`$86CE`) pushes a row onto the attributes, BuildGlyph (`$89C9`) and ScrollStep (`$8AED`) read it (c2: `$86CE` 11862 entries reading `$B700-$BFFF`). Its first 47 bytes (`$B700-$B72E`) are the start-up routine at `$B6FF`, dead once it has run; LevelSetUp clears `$B700-$BFFF` (LD HL,`$B700`, BC = `$08FF`) before the first level. On the tape these 1233 bytes are zero: no leftover. | `BuildCell`, `BuildGlyph`, `CmdResetRecords`, `LevelSetUp`, `MoveStars` +9 | `BuildCell`, `CmdResetRecords`, `LevelSetUp`, `PlaceColumn`, `ScrollStep` |
| `$BC00` | `TileSource` | 2048 | The 256 scenery tiles, as the start-up copies them to TileGraphics `$5C00`. GS: the dump keeps the tape copy as well; the GS version never runs Start, and its block carries these bytes twice (here and at TileGraphics). Same bytes, one editable file: src/res/gfx/tiles.gfx.png builds both (tools/res_gfx.py's tiles-tape.bin). 2048 bytes: 8 line pages of 256 bytes, line y of tile t at `$BC00` + y*256 + t. The start-up (`$B6FF`: LD HL,`$BC00`, DE = `$5C00`, BC = `$0C00`, LDIR) copies them with the wave cells to `$5C00-$67FF`, where BuildGlyph (`$89C9`) reads them through TileSet `$7F6D` (c2: `$5C00-$63BA`, tile codes up to `$BA` in level 1); a tile drawn mirrored goes through BitReverse `$FB00`, flipped through the line pages +`$700` down. In play `$BC00-$BFFF` is the map ring's last four rows and `$C000-$C3FF` the glyph cache's first page: the tape copy is dead after the start-up. Editable as src/res/gfx/tiles.gfx.png (16 x 16 tiles). | `BuildCell`, `BuildGlyph`, `CmdResetRecords`, `GlyphLine`, `LevelSetUp` +17 | `BigSpriteCell`, `BuildCell`, `BuildGlyph`, `CmdResetRecords`, `FillBlankCell` +7 |
| `$C400` | `WaveCellSource` | 1024 | The cells of the wave sprites, copied to `$6400`. GS: kept as at TileSource: the same bytes as WaveCellGraphics. 1024 bytes copied to `$6400-$67FF` by the start-up: 64 columns of 16 lines (two 8-line cells), column-major, a set bit the sprite's pixel. A wave sprite of kind A < 16 is two columns at `$6400` + A*32; from 16 up three columns at `$6620` + (A-16)*48 (LoadCellSprite `$ACD9`: HL = `$6400` + (A>>3)*256 + (A&7)*32, plus (A-16)*16 + `$20` from 16 up). BuildCellSprite (`$8EDB`) complements them into a sprite cache image (SpriteCacheImages `$E748`) with a blank column after each; c2 reads only `$64E0-$64FF` and `$65E0-$65FF` (kinds 7 and 15, level 1). `$6600-$661F` (two columns) is no sprite of that addressing. Editable as src/res/gfx/wave-cells.gfx.png. | `BuildGlyph`, `GlyphLine`, `RotateByteShift`, `RotateLineMerge`, `SpanDraw1` +4 | `BuildGlyph`, `GlyphLine`, `RotateByteShift`, `RotateLineStore`, `SpriteShiftCopy` |
| `$C800` | `GlyphCacheUpper` | 6144 | The glyph cache pages `$C8-$DF` (zero on the tape). In play: the glyphs shifted by 2, 6 and 4 pixels (pages `$C8`, `$D0`, `$D8`; BuildGlyph `$89C9` writes them, the span handlers read them). 6144 zero bytes on the tape. GS: not in Trush block 4 (its `$C800-$DFFF` carry `$5C00-$73FF`); the installer's Mover clears it after moving them down (src/disk/install.asm). block4.asm leaves these zeros out. | `RotateByteShift`, `RotateLineMerge`, `SpanDraw1`, `SpanDraw2`, `SpanDraw3` +2 | `BuildGlyph`, `GlyphShift2`, `GlyphShift4`, `RotateByteShift`, `RotateLineStore` +1 |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E000` | `SpritePad` | 8 | 8 bytes above the player's image (blank in play). Zero on the tape, `$FF` after the start-up (GS: `$FF`). BuildObjectStrips (`$8FC2`) moves an image pointer back by the sprite's Y within its cell (0-7), so the first column of the first image reads up to 7 bytes before it: these keep that blank. | - | - |
| `$E008` | `PlayerSprite` | 576 | The player's ship: 8 shifts of 3 columns x 24 lines. Descriptor `$7E94` (the ship's record `$F36C` +0/+1). 576 bytes, a shift every 72; lines 16-23 of each column are blank. Complemented on the tape (GS: not, the start-up has run). | - | - |
| `$E248` | `SightSprite` | 576 | The homing sight: 8 shifts of 3 columns x 24 lines. Descriptor `$7EAE` (the sight's record `$F600`, kind 6, SightHandler `$9E03`): two pairs of brackets 11 lines apart. Complemented on the tape (GS: not, the start-up has run). Not drawn in c1/c2 (the homing missile was never taken). | - | - |
| `$E488` | `ExplosionFrames` | 384 | The explosion: 8 frames of 2 columns x 24 lines. Descriptor `$7EA1` (StartExplosion `$A293` sets it with frame 1): the image base `$E458` + frame * 48, frames 1-8 here; ExplosionStep (`$A1C8`) ends at frame 9. A ball that grows, bursts and scatters. Complemented on the tape (GS: not, the start-up has run). | - | - |
| `$E608` | `LaserSprite` | 64 | The laser shot: 4 shifts (2 pixels apart) of 2 columns x 8 lines. Descriptor `$7EC8` (the four shot records from `$F4F8`, kind 1, LaserHandler `$9E32`): a dashed line on the first line. Complemented on the tape (GS: not, the start-up has run). | - | - |
| `$E648` | `BallSprite` | 256 | The enemy shot and plasma ball: 8 shifts of 2 columns x 16 lines. Descriptor `$7ED5` (the enemy shot records from `$F474`, kind 5; the plasma balls `$F5A8` and `$F5D4`, kind 9): a 7-line ball. Complemented on the tape (GS: not, the start-up has run). | - | `FillBlankCell` |
| `$E748` | `SpriteCacheImages` | 2304 | The sprite cache images, also the panel's save area. 2304 bytes, two uses in turn: - the images of the cached enemy sprites: the descriptors from `$7EF2` point at `$E748`, `$E988`, `$EBC8` and `$EE08` (8 shifts of 3 columns x 24 lines, `$240` each), the 4-column ones at `$E748`, `$EBC8` and `$E988` (`$300` each). BuildCellSprite (`$8EDB`) writes the unshifted copy from the wave cells, complemented; ShiftSprite (`$8F5A-$8F65`) and the copy at `$AD44` make the other 7 shifts (c2: `$E748-$E987`). - SavePanel (`$A98D`) saves the screen third `$5000-$57FF` here and the attribute rows 19-23 (`$5A60-$5AFF`) at `$EF48`; RestorePanel (`$A979`) puts them back (c2: saved frame 610, restored 780 at the player change, sprites rebuilt at frames 102-1274). On the tape: a saved panel left from the mastering session (1578 of the 2048 bitmap bytes equal the c2 screen of frame 250 at `$5000`; 135 of the 160 attribute bytes) and zero after `$EFE8`. Nothing reads them before SavePanel or BuildCellSprite writes: a leftover. | `RestorePanel`, `RotateByte`, `RotateByteShift`, `RotateLineMerge`, `RotateNextByte` +2 | `BuildCellSprite`, `FillBlankCell`, `RotateByte`, `RotateByteShift`, `RotateLineMerge` +5 |
| `$F048` | `PodSprite` | 192 | The weapon pod: 4 shifts (2 pixels apart) of 3 columns x 16 lines. Descriptor `$7EBB` (set by ExplosionStep's end `$A2D6` when the dead enemy leaves a pod: kind 4, colour `$08`, PodStep `$A1FD`). A round ball of 13 lines. Complemented on the tape (GS: not, the start-up has run). | - | - |

## records

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F108` | `RecordsGap` | 36 | 36 bytes nothing uses. Zero on the tape, read or written by nothing in c1 or c2. | - | - |
| `$F12C` | `RowRecords` | 576 | The 18 row records of the playfield, 32 bytes each. Zero on the tape; LevelSetUp (`$8C3B`) fills them. Fields (10-notes.md, F1): +0/+1 the map ring pointer (`$B71F` + `$80` * row), +2/+3 the attribute address (`$583F` + `$20` * row), +4/+5 the screen address, +6/+7 the head span node (SentinelNode `$85E4` when empty), +8 the glyph count, +`$0A` the node count, +`$0B`/+`$0C` the glyph-slot bit and pointer into GlyphBitmap `$FFE0`, +`$0D`/+`$0E` the last node, +`$0F` the cache slot, +`$10`/+`$11` the column builder's bit and pointer, +`$12` the scroll countdown, +`$13`, +`$14` flags, +`$15` the strip count (ClearStripCounts `$8F70`), +`$16`/+`$17` the strip list, +`$18`-+`$1F` the row's star (InitStars `$8846` PUSHes from SP = `$F14C`, StarsStep `$8894` from `$F144`). | `BuildCell`, `BuildCellDone`, `BuildGlyph`, `BuildObjectStrips`, `CmdResetRecords` +7 | `BuildCell`, `BuildCellDone`, `BuildGlyph`, `BuildObjectStrips`, `ClearStripCounts` +5 |
| `$F36C` | `PlayerObject` | 44 | The player's ship record (kind 0). The first of 16 object records of 44 bytes (`$F36C-$F62B`). Fields: +0/+1 the sprite descriptor, +2 the frame, +3/+4 the X (+3 the fraction, its bits 5-7 the shift; +4 the column + 16), +5/+6 the Y (+5 the fraction, its bits 5-7 the line; +6 the row), +7 the kind (KindHandlers `$80FA`), +8 flags (bit 7 active, bit 5 drawn), +9/+`$0A` the strip buffer, +`$0B` the row mask of the strips, +`$0D` the hit mask, +`$0E`/+`$0F` the X speed, +`$10`/+`$11` the X acceleration, +`$12`/+`$13` the Y speed, +`$14`/+`$15` the Y acceleration (PathOpAccelerate `$9529`), +`$24` the slot's collision bit, +`$25` the colour, +`$26`/+`$27` counters. The tape holds every record's start values: the descriptors, the strip buffers, the masks +`$0B`, the collision bits +`$24` and the colours +`$25` (the ship: `$7E94`, `$F62C`, `$E0`, `$01`, `$45`; play sets its colour again); ResetPlayers and the level start rewrite the moving fields. | `BuildObjectStrips`, `ClampColumn`, `ClampRow`, `DirectionTo`, `EnemyShotStep` +15 | `BuildObjectStrips`, `ClampColumn`, `ClampRow`, `FireLaser`, `KillPlayer` +5 |
| `$F398` | `EnemyObjects` | 220 | The five enemy records (kinds 2, 8, 11 and the cache kinds). `$F398`, `$F3C4`, `$F3F0`, `$F41C`, `$F448`; with the three enemy shots they are the 8 slots of the hit grid (bit n = slot n, +`$24` = `$02`, `$04` ... `$80`). On the tape all five are empty (kind 0, no descriptor) with their strip buffers (`$F650` + 36 n), +`$0B` = `$E0` and the collision bits. | `BigEnemyHandler`, `BuildObjectStrips`, `ClampRow`, `CmdEnemiesLeft`, `CmdEnemyEscape` +47 | `BigEnemyHandler`, `BuildObjectStrips`, `ClampRow`, `CycleColour`, `EnemiesSetup` +35 |
| `$F474` | `EnemyShots` | 132 | The three enemy shot records (kind 5, BallSprite). Descriptor `$7ED5`, colour `$48`, strip buffers `$F734`, `$F74C`, `$F764` (two strips each). | `BuildObjectStrips`, `DirectionTo`, `EnemyFire`, `EnemyShotStep`, `FreeObject` +9 | `BuildObjectStrips`, `EnemyFire`, `EnemyShotStep`, `FreeObject`, `KillPlayer` +5 |
| `$F4F8` | `LaserShots` | 176 | The four laser shot records (kind 1, LaserSprite). Descriptor `$7EC8`, colour `$78`, a strip each (`$F77C`, `$F788`, `$F794`, `$F7A0`). | `BuildObjectStrips`, `FireLaser`, `KillPlayer`, `LaserHandler`, `ObjectStrips` +5 | `BuildObjectStrips`, `FireLaser`, `KillPlayer`, `LaserHandler`, `PlayerHandler` +3 |
| `$F5A8` | `PlasmaBall2` | 44 | The second plasma ball (the double plasma). Kind 9, descriptor `$7ED5`, strip buffer `$F7AC`. | `KillPlayer`, `ObjectStrips`, `PlayerHandler`, `PlayerSetup`, `RunObjects` +1 | `KillPlayer`, `PlayerHandler`, `PlayerSetup`, `RunObjects`, `TestHitGrid` |
| `$F5D4` | `SideShot` | 44 | The side weapon's shot: plasma ball, homing missile or seeker. Kinds 9, 10, 7; strip buffer `$F7C4`. | `KillPlayer`, `ObjectStrips`, `PlayerHandler`, `PlayerSetup`, `RunObjects` +1 | `KillPlayer`, `PlayerHandler`, `PlayerSetup`, `RunObjects`, `TestHitGrid` |
| `$F600` | `SightObject` | 44 | The homing sight (kind 6, SightSprite). Descriptor `$7EAE`, colour `$78`, strip buffer `$F7DC`; RunObjects starts here and walks down by 44 bytes. | `KillPlayer`, `ObjectStrips`, `PlayerHandler`, `PlayerSetup`, `RunObjects` +1 | `KillPlayer`, `PlayerHandler`, `PlayerSetup`, `RunObjects`, `TestHitGrid` |
| `$F62C` | `StripBuffers` | 468 | The objects' strip entries, 12 bytes each. 39 entries: the ship 3 (`$F62C`), the five enemies 3 each from `$F650`, four spare from `$F704`, the enemy shots 2 each from `$F734`, the laser shots 1 each from `$F77C`, the plasma ball 2 (`$F7AC`), the side shot 2 (`$F7C4`), the sight 3 (`$F7DC`). An entry: +0/+1 a link word, +2/+3 StripDraw (`$8603`), +4/+5 the image pointer, +6 the colour and +7 the columns, +8 the attribute column and +9 a byte StripDraw patches into `$866D`, +`$0A`/+`$0B` the next strip's +2 (StripDraw returns into it). BuildObjectStrips (`$8FC2`) fills +4-+`$0B` with PUSHes and steps over +2/+3 (DEC SP, DEC SP), and RowEnd returns into +2: the `$8603` words are never written by the code, they come from the tape. So does the link word (the same in the title and play snapshots). | - | - |

## tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F800` | `NodePool` | 768 | 95 span nodes of 8 bytes. LevelSetUp (`$8C3B`) links them into the free list (head NodeFreeList `$7F68`) and ends it with `$FFFF` at `$FAF8`. A node: +0/+1 the span handler, +2 the column, +3 the countdown, +4/+5 the next node, +6 the width. PopNode `$8AD0`, PushNode `$8ADF`, the scroll step `$8AED` and `$8C1C` walk it (c2). | `NewSpanNode`, `PopNode`, `ScrollStep`, `SetSpanHandler` | `LevelSetUp`, `NewSpanNode`, `PushNode`, `ScrollStep`, `SetSpanHandler` |
| `$FB00` | `BitReverse` | 256 | 256 bytes, each the bit reverse of its index. Built by LevelSetUp (`$8C3B`, loop `$8CE9`). BuildGlyph (`$89C9`) patches its own load to look tiles up here for a mirrored tile (the row's flag bit 1); DrawSpinner (`$A8BE`) mirrors the panel's spinner with it. | `BuildGlyph`, `DrawSpinner`, `GlyphLine` | `LevelSetUp` |
| `$FC00` | `HitGridX` | 256 | The collision grid: one byte a column (play) / the menu's raster colours. Play: ClearHitGrid (`$91C6`, SP = `$FD90`, 200 bytes of PUSHes) clears `$FC00-$FD8F` in phases 2-4, MarkEnemyGrid (`$90CB`) ORs the collision bit of each enemy slot into the X bytes (step 4) and the Y bytes `$FD00` (step 8), TestHitGrid (`$9150`) ANDs them for the ship and its shots. Menu: ClearColourBuffer (`$A5A7`) zeroes it, ExpandColours (`$A5D1` and its callers `$A685`, `$A790`) writes a colour per scan line from `$FC20`, the menu raster interrupt (`$A512`) reads `$FC20-$FC7F`. | `MarkEnemyGrid`, `MenuRasterInterrupt` | `ClearColourBuffer`, `ExpandColours`, `MarkEnemyGrid` |
| `$FD00` | `HitGridY` | 144 | The Y half of the collision grid. `$FD00-$FD8F`, cleared with HitGridX; MarkEnemyGrid (`$90CB`) ORs the enemies' collision bits in, TestHitGrid (`$9150`) reads them (c2: 331 and 494 entries). | `MarkEnemyGrid` | `MarkEnemyGrid` |
| `$FD90` | `ScriptStack` | 107 | The scenery script's stack (down from `$FDFB`). The scenery coroutine runs on its own stack: StartScript (`$8D35`) sets its SP ScriptSP (`$801A`) to `$FDFB` and puts the script's entry `$8D72` there; ScriptYield (`$8D45`) and ScriptResume (`$8D69`) swap SP between it and the main stack. c2 play-start holds return addresses at `$FDD9-$FDFA`. On the tape: zero to `$FDE7`, then the start of a routine left by the mastering machine, running into the next entries to `$FE4A`: DI; XOR A; LD (`$FE4B`),A, then a loop that takes a count, an address and that many bytes through CALL `$FE17` and stores them with a border flash, then a checksum compared at `$FE0A` (JP NZ,0 on a bad one). `$FE17` reads a byte from the ZX Interface 1 RS-232 port (OUT (`$EF`), IN (`$F7`), bit 7, 11-step delays): a download link, never used by the game. | `MarkEnemyGrid` | `DrawGroup`, `MarkEnemyGrid`, `PlaceColumn` |
| `$FDFB` | `ScriptStackTop` | 2 | The scenery script's first return address. StartScript (`$8D35`) writes `$8D72` here (the script entry) before the first resume. The tape holds leftover bytes (`$6F`, `$CD`). | - | `StartScript` |
| `$FDFD` | `InterruptJump` | 3 | JP to the frame handler, where every IM 2 interrupt lands. SetUpInterrupts (`$8516`) writes JP `$A9E4` here; the handler word `$FDFE` is switched by the menu and play code. The tape holds the leftover routine's bytes. | `StopAndSettle` | `CheckPauseAndEnd`, `PlayLoop`, `PlayLoopBranch`, `PlayLoopTest`, `SetMenuRaster` +2 |
| `$FE00` | `VectorTable` | 257 | The IM 2 vector table: 257 bytes of `$FD`. SetUpInterrupts (`$8516`) fills `$FE00-$FF00` with `$FD` and sets I = `$FE`, so any vector the bus gives reads `$FDFD`. Reads at `$FEFF`/`$FF00` in the recordings are interrupts taken inside routines (c1: `$A321` 1566 entries, c2: `$899E` 3948). On the tape: the rest of the leftover routine to `$FE4A`, then zeros. | `AllocGlyphs`, `BuildCell`, `BuildColumn`, `BuildColumnBack`, `BuildColumnStep` +67 | - |

## tunedata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF01` | `TunePeriods` | 27 | the period of each note number, in loop passes (index 0 unused) | - | - |
| `$FF1C` | `TuneOrder` | 14 | the patterns in play order: A A B A C C D | - | - |
| `$FF2A` | `TunePatternA` | 55 | pattern A (played 3 times): the opening phrase | - | - |
| `$FF61` | `TunePatternB` | 59 | pattern B: the climbing arpeggios | - | - |
| `$FF9C` | `TunePatternC` | 18 | pattern C (twice): the ostinato | - | - |
| `$FFAE` | `TunePatternD` | 38 | pattern D: the closing phrase | - | - |

## topcells

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FFD4` | `FontLeftover` | 3 | the lines 4-6 of the ROM's 'P' (`$7C`, `$40`, `$40`), no code reads them | - | - |
| `$FFD7` | `Invulnerable` | 1 | the developer switch: not 0 = the ship cannot be killed. Read only at `$9B4C`, the collision's death path: when the ship is hit and Invulnerable is not 0, the death count-down (`$9B5F`, DeathTimer = `$16`) is skipped and the ship flies on. Never written by the game: 0 on the tape (the 'P' glyph's empty last line), so a POKE 65495,1 makes the ship immortal. Measured (work/f4/invuln.py from work/explore/play-start.szx, no input): with 0 the idle ship died at frames 300-400, 900-1000 and 1400-1500 (deaths 3); with 1 no death in 30000 frames, through levels 0-3 into level 4. | `PlayerHandler` | - |
| `$FFD8` | `WorkGlyph` | 8 | an 8-byte work cell: `$8EC5` copies a glyph of `$72A9` + 8 n here, `$8EA1` draws it (on the tape: the ROM's 'Q') | `PlaceColumn` | `ScriptSetCell` |
| `$FFE0` | `ColumnFlags` | 32 | 32 flags a screen column (to `$FFFF`, past the image): cleared by `$8C3B` at each level start (`$8CD9`, LDIR of 32 bytes `$FFE0-$FFFF`), `$89C9` sets bits in (H = `$FF`, L = the object's +`$11`); on the tape the ROM's 'R'-'U' | `AllocGlyphs`, `BuildGlyph`, `GlyphMarkBits`, `LevelSetUp`, `ScrollStep` | `BuildGlyph`, `GlyphMarkBits`, `LevelSetUp`, `ScrollStep` |
