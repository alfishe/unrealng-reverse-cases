# Stage 5's resources

The editable data of stage 5's block (TZX block 52, `$6C3F`-`$F03E`: the flight through the void and the duel with
Dameron), one file a data entry of `src/stage5/stage5.ann` (`@res`). `tools/res_formats.py` turns each into its
bytes with the formats of `tools/res_stage.py` and `tools/res_stage5.py` (their docstrings have the formats in
full); `tools/build.sh` assembles them with INCBIN and checks the tape against the original;
`python3 tools/res_formats.py check` proves every file comes back unchanged through its bytes.

Formats in short:

- `bitmaps-NAME-WxH.png`: frames of W bytes x H lines one after another, 1 bit a pixel, rows top first, no mask.
- `picture-NAME-WxH.png`: a linear picture (H lines of W bytes) and its attributes, in colour.
- `table-NAME.csv`: rows of fixed columns (`res_stage.TABLES`).
- `textlines-NAME.txt`: stage 5's own format (`tools/res_stage5.py`): one text line a line, `COLUMN PIXEL BYTE2
  TEXT`; `\` is the font's full stop (glyph 27).

Stage 5 has no rooms, tiles or map (no graphics block, no rooms.txt), so `tools/fig_rooms.py` draws nothing for it.

| File | Address | Bytes | What | Read by |
|------|---------|-------|------|---------|
| `picture-hud-32x48.png` | `$7000` | 1728 | The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their colours at $7600 (6 rows of 32) | ClearMissiles `$7F10`, EndStageSave `$78C9`, FindFreeMissile `$8C6C`, StageSetUp `$95E4`, UpdateDameronMissiles `$804A` |
| `bitmaps-final-burst-2x12.png` | `$7AD7` | 24 | The final burst's shape: 12 rows of 16 bits, bits 7-14 set (a block 8 fragments wide, 12 high) | NextDameronForm `$A0C4` |
| `table-startitems.csv` | `$7E7F` | 12 | The carried items at the stage's start, copied to CarriedItems by $96DD: slots 0-3 kind 4 (blank), slot 6 kind 8 | InitStageState `$96DD` |
| `table-itemicons.csv` | `$7E8B` | 18 | The 16 x 16 icon of each item kind 0-8 (32 bytes each; kind 4 points to the blank $94B0) | DrawItemIcon `$7DD0` |
| `bitmaps-shot-2x5.png` | `$856C` | 10 | The hero's shot: 5 lines of 2 bytes | DrawShotsNext |
| `table-dameron-path.csv` | `$8A28` | 256 | Dameron's path after the approach: 128 steps of (dX, dY), dX always 0, dY +1 or -1 | DuelPathStep |
| `textlines-intro.txt` | `$8E0D` | 108 | The intro's seven lines: each 3 header bytes, the characters, 0 | DrawIntroText `$8DAF` |
| `textlines-ending.txt` | `$8E79` | 100 | The ending's seven lines, in IntroText's format | DrawEndingText `$8DDE` |
| `bitmaps-text-font-1x8.png` | `$8F96` | 224 | The texts' proportional font: 28 glyphs of 8 bytes, A-Z, space, full stop | DrawTextGlyph |
| `table-burst-steps.csv` | `$9191` | 40 | 20 (dx, dy) steps: 10 for the right-byte particles, 10 for the left-byte ones | UpdateBurstIndex |
| `bitmaps-particles-1x8.png` | `$9230` | 56 | The burst's 8 x 8 particle glyphs: 0-3 from dense to sparse, 4-6 blank | UpdateBurstStep |
| `table-burst-glyphs.csv` | `$926C` | 35 | The glyph (0-3) at each burst step: index = step + a Random 0-3 | UpdateBurstStep |
| `table-burst-directions.csv` | `$928F` | 160 | Six direction tables of 32 step indexes (0-6 into BurstSteps); the first five here | UpdateBurstDirection |
| `table-burst-directions-cut.csv` | `$932F` | 26 | The sixth direction table (direction 5), cut to 26 bytes by EraseParticle's code | UpdateBurstDirection (its index runs past the five tables) |
| `table-frame-offsets.csv` | `$938E` | 48 | The offset of each of the 24 sprite frames in the bank $B3BA | SpriteFrameAddress `$9378` |
| `bitmaps-game-over-8x8.png` | `$A367` | 64 | GAME OVER: 8 bytes x 8 lines (the last line blank) | GameOverStep `$7E9D` |
| `bitmaps-star-slow-3x3.png` | `$A400` | 18 | The slow star: two frames of 3 bytes x 3 lines ($A400, $A409) | DrawStarSlow |
| `bitmaps-star-fast-4x5.png` | `$A412` | 40 | The fast star: two frames of 4 bytes x 5 lines ($A412, $A426) | DrawStarVisible |
| `bitmaps-dameron-face0-7x128.png` | `$A43A` | 896 | Dameron's face, form 0: 7 bytes x 128 lines | DrawFaceSelect |
| `bitmaps-dameron-dome-4x128.png` | `$A7BA` | 512 | The middle of Dameron's head, forms 0-2: 4 bytes x 128 lines | DrawDameronDome `$894D` |
| `bitmaps-dameron-back-4x128.png` | `$A9BA` | 512 | The back of Dameron's head (the hair), every form: 4 bytes x 128 lines | DrawDameronBack `$899C` |
| `bitmaps-dameron-face1-7x128.png` | `$ABBA` | 896 | Dameron's face, form 1: 7 bytes x 128 lines | DrawFaceSelect |
| `bitmaps-dameron-face2-5x128.png` | `$AF3A` | 640 | Dameron's face, form 2: 5 bytes x 128 lines (the skull) | DrawFaceSelect |
| `bitmaps-dameron-dome3-4x128.png` | `$B1BA` | 512 | The middle of Dameron's head, form 3 (no face): 4 bytes x 128 lines | DrawDameronDome `$894D` |
| `bitmaps-bank-3x16.png` | `$B3BA` | 384 | The sprite bank, frames 0-7: 3 bytes x 16 lines (fireballs 0-3, the curved shot 4-7) | SpriteFrameAddress `$9378` |
| `bitmaps-bank-3x9.png` | `$B53A` | 108 | The sprite bank, frames 8-11: 3 bytes x 9 lines, the bolt | SpriteFrameAddress `$9378` through SpriteFrameOffsets `$938E` |
| `bitmaps-bank-3x24.png` | `$B5A6` | 936 | The sprite bank, frames 12-23: 3 bytes x 24 lines, the hero's explosion and the bursts (13 blocks of 72 bytes) | SpriteFrameAddress `$9378` through SpriteFrameOffsets `$938E` |
| `bitmaps-item-icons-2x16.png` | `$B958` | 256 | The item icons: 8 icons of 2 bytes x 16 lines (32 bytes each) | ItemIcons `$7E8B` |
| `bitmaps-energy-bar-6x1.png` | `$BA78` | 6 | The energy bar's pattern: 6 bytes, the same on each of the bar's 6 lines | DrawEnergyBar `$9744` |
| `bitmaps-hero-3x24.png` | `$BB1C` | 864 | The hero: 12 frames of 3 bytes x 24 lines (3 animation steps x 4 shifts of 2 pixels) | HeroFrames `$85D9` |

`picture-hud-32x48.png` holds the same bytes as stage 1's file of that name (each stage block carries its own copy).

**Not resources.** The bytes no code reads stay in the listing as named entries that say so: Unused76C0
`$76C0`-`$77FF`, UnusedA3A7 `$A3A7`-`$A3FF`, SpriteBankSpare `$B67E`, BitMasks `$B950`, ItemIconSpare `$BA18`, UnusedWordTable `$BAC6`,
WindowFrameColours `$7CC2`, FinalBurstShapeTail `$7AEF`, the zero runs after `$BE7C` and StrayByte `$DCBA`.
