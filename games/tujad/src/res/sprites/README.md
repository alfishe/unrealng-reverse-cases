# Sprites

PNG sheets (tools/res_formats.py: palette 0 paper, 1 ink, 2 grid; each frame top row first; the text chunk
`tujad-sheet` holds the layout and the bytes before each frame). The interrupt `$95D0` XORs every sprite onto the
screen from the sprite list `$FF01`. The enemy and object frames start with a shift byte (0 in the image) and are
shifted in place by ShiftGraphic3 `$7EBB` / ShiftGraphic4 `$7EFE`, so their bytes change in play.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Droid.png` | `$9C40-$A257` | 1560 | MoveDroid `$7208` (DroidFrames `$6888`, DroidWidths `$68A4`), TurnRound `$7866` (mirrors `$9C40-$A4AF` in place, all but `$A0A0-$A0EF`; `$A258-$A4AF` are 600 zero bytes), PlaceDroid `$7A6D` (byte 4: the facing), Teleport `$7719` (the beam frame `$A0A0`) | 14 frames of 40 rows: the walk 0-7 (3 bytes wide), the turn 8-9 and the front 10 (2 bytes), 11-13 (3 bytes: the droid moving while it steps down). Row 1 of the sheet: frames 0-7, row 2: 8-10, row 3: 11-13. The image holds the right-facing set |
| `Enemies.png` | `$A74E-$AEC4` | 1911 | MoveEnemy `$90E7` (EnemyKind `$90C8`: EnemyGraphics `$68C1`, EnemyFrameCounts `$68B8`; ExplosionFrames `$68D3`), ShiftGraphic3 | Rows 1-9: the nine enemy kinds (4, 3, then 4 frames), row 10: the explosion. Each frame 1 shift byte + 16 rows of 3 bytes |
| `Materialise.png` | `$AEC5-$AF84` | 192 | MoveEnemy (MaterialiseFrames `$68DB`) | 4 frames of 16 rows of 3 bytes: an enemy appearing. No shift byte, never shifted |
| `Probe.png` | `$AF85-$B048` | 196 | Fire `$861C` (FireWeapon3), MoveShot `$8298` (MoveShot3Frame) | Weapon 3's probe: 4 frames, 1 shift byte + 16 rows of 3. Frames 2 and 3 seen in L1 (three recordings fire weapon 3), frame 4 in the recording probe-shield (doc 05, 5.8): only frame 1 is known only from the code |
| `Objects.png` | `$B049-$B901` | 2233 | MoveObject `$809D` (ObjectKind `$7C28`; ObjectDeathFrames `$68E3`), MoveShot (Weapon3Frames `$68EB`), ShiftGraphic4 | Rows 1-5: the object kinds of kind bits 4 (3 frames), 5 (4), 6 (3), 7 (4) and none (3), 1 shift byte + 24 rows of 4 bytes; row 6: an object's death (4 frames, 97 bytes); row 7: the probe's explosion (4 frames of 49 bytes). The first death frame `$B6BA` is never read: the dying states select words 2-4 of ObjectDeathFrames, state AND `$0C` = 0 ends the death first (MoveObjectDying `$8236`) |
| `Patrollers.png` | `$B902-$BC01` | 768 | MovePatrollers `$6AAD` | Row 1: a patroller going right, row 2: going left; 4 frames of 24 rows of 4 bytes each, never shifted |
| `ShotGraphics.png` | `$8814-$8853` | 64 | Fire `$861C`, MoveShot `$8298` | The bolts of weapon 1 (`$8824`, alternating with `$8814`) and weapon 2 (`$8844`, with `$8834`): 2 bytes x 8 rows |
| `HudIcons.png` | `$8C55-$8D34` | 224 | ShowWeapon `$79C2`, DrawItem `$6E0D`, DrawHud `$8AE8` (through Blit16 `$8A93`) | 7 icons of 16 x 16: weapons 0-3, GEN 19 (`$8CD5`), the HUD's energy (`$8CF5`), the energy source (`$8D15`) |
