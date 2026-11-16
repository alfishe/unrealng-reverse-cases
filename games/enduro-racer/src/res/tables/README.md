# tables

CSV files have a header line; `$XX` hex, plain numbers decimal. `tail` lines hold bytes past the last whole record.

| File | Entry | Records |
| --- | --- | --- |
| `controls.csv` | `ControlTable` `$8323-$8354` | 5 control methods: half-row byte and mask of THROTTLE, WHEELIE, LEFT, RIGHT, BRAKES (the last record's 3 masks are also KeyNamesBase's bytes) |
| `hiscores.csv` | `HiScores` `$8DE2-$8E4F` | 5 rows: score (7 digits), name (8), total time |
| `records.csv` | `InitialRecords` `$8003-$800F` | 5 stage records (BCD seconds, hundredths), then the total as a tail |
| `perspective.csv` | `Perspective` `$7800` | each of 128 road rows' depth |
| `edges.csv`, `edges2.csv` | `EdgePatterns` `$7880`, `EdgePatterns2` `$7A80` | 128 three-byte road edge patterns each |
| `crest.csv` | `CrestTable` `$7A00` | each row's line shift on a crest (the crest's column picks the scale) |
| `bends.csv` | `BendProfiles` `$7D80` | three bend profiles of 128 rows (each row's sideways shift), as columns |
| `rowscale.csv` | `RowScale` `$7F00` | per row: scale (`$7F00`), half width (`$7F80`), as columns |
| `countglyphs.png` | `CountGlyphs` `$7C00` | G, O (8 lines), 1, 2, 3 (10 lines), side by side |
| `objects.csv` | `ObjectList4` `$976B-$98EE` | 8 lists (type order 4 5 1 6 2 0 3 7): a `head` (farthest row, aligned row), then `entry` lines (row threshold, y offset, rows, width, address) |
| `riders.csv` | `RiderSprites` `$917E-$9210` | 7 distance bands: threshold, 5 poses (rows +128 mirror, width +128 aligned, address) |
| `riderstarts.csv` | `RiderStarts` `$9111-$9126` | x, acceleration, top speed, bend pose; the sixth rider's last 2 bytes are BikePoses' `$9127-$9128`, so a tail |
| `stages.csv` | `StageTable` `$9E67` | 5 stages: horizon address, lines, the picture's top line |
| `stageparams.csv` | `StageParams` `$A187` | 5 stages: road routine, row builder, off-road routine, ground attribute, copy mode (0 for all), 2 unused bytes |
| `collisions.csv` | `CollisionSizes` `$A1B9` | 8 object types: half width, height |
| `lean.csv` | `LeanTable` `$8E56-$8E5C` | the steering force of each lean, -3 to 3 (the sign from the lean) |
| `steer.csv` | `SteerTable` `$8E5D-$8E71` | the steering force at each speed, index ScrollStep's high byte x 2 (0-20) |
| `bendblend.csv` | `BendBlend` `$75D7-$7607` | BlendBend's 49 steps |
| `dotmasks.csv` | `DotMasks` `$9CAF-$9CB6` | GroundTexture's eight dot masks |
| `dust.csv` | `DustOffsets` `$A0F3-$A0FC` | the splash's and dust's x offset per pose and lean, signed |
| `ayeffect.csv` | `AyEffect` `$A15D-$A166` | the AY effect's five register, value pairs (PlayEffect) |
