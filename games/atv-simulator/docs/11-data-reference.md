# 11. Data reference

Every data entry of the game image `$6338`-`$FF77`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/rec/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6338` | `MenuGfx` | 965 | The front end's graphics bank: 14 pictures, each a sprite and its attributes. +0 the count (14), +1 the bank's length word (`$03C5`: it ends at `$66FD`), +3 zero, then a pair of words a picture from +4: the sprite's offset and the attributes' offset, both from `$6338`. A sprite is width (bytes), height (lines), advance, shift, then width x height bytes; the attributes are width, height (cells) and a byte a cell. MenuSprite (`$863D`) and MenuSpriteAttrs (`$773D`) read it (c1: the title's ATV and logo, the trail intro's number, the panel frames). | `CopyAttrs`, `MenuSprite`, `MenuSpriteAttrs`, `ModeCopyScreen`, `ModeXorBuffer` +9 | `RotateSpriteLeft`, `RotateSpriteRight`, `ShiftBytesLeft`, `ShiftBytesRight`, `ShiftLeftBy` +1 |
| `$66FD` | `MenuGfxEnd` | 35 | 35 zeros after the bank, never read | - | - |
| `$6720` | `MenuVars` | 1 of 7 | The menu's variables | `Highlight`, `ItemPtr`, `MenuBoxDraw`, `MenuBoxFrame`, `MenuBoxScreen` +5 | `ClearMenuSpare`, `MenuBox`, `MenuTimer`, `Title`, `MenuControl` (`stage1/rec/menu`) +3 |
| `$6721` | `MenuBoxY` (`MenuVars`+1) | 1 | its y (the top line, counted up from the bottom) | `Highlight`, `MenuBoxFrame`, `MenuBoxScreen`, `MenuBoxClear` (`stage1/rec/menu`) | `MenuBox` |
| `$6722` | `MenuBoxHeight` (`MenuVars`+2) | 1 | its height (lines) | `MenuBoxDraw`, `MenuBoxFrame` | `MenuBox` |
| `$6723` | `MenuCount` (`MenuVars`+3) | 1 | its item count | `MenuLoop` | `MenuBox` |
| `$6724` | `TuneTimer` (`MenuVars`+4) | 1 | a word from `$04C8` (Title), counted by MenuTick each tune interrupt and by MenuLoop each HALT: the high scores at `$0A00` in the tune (26.7 s), the title at `$8000` (MenuLoop) | `MenuTimer` | `MenuTimer`, `Title` |
| `$6725` | `MenuSpare` (`MenuVars`+5) | 1 | written 0 by ClearMenuSpare, never read | `MenuTimer` | `ClearMenuSpare`, `MenuTimer`, `Title` |
| `$6726` | `MenuItem` (`MenuVars`+6) | 1 | the highlighted item (0 up) | `Highlight`, `ItemPtr`, `KeySlot` (`stage1/rec/menu`), `MenuKeys2Select` (`stage1/rec/menu`), `MenuLoop` (`stage1/rec/menu`) | `Title`, `MenuControl` (`stage1/rec/menu`), `MenuKeys2Select` (`stage1/rec/menu`), `MenuLoop` (`stage1/rec/menu`), `MenuMain` (code) |
| `$6727` | `RowAddrs` | 384 | The screen address of each of the 192 lines, top first (BuildRowAddrs fills it at the start; zeros in the image) | `ScreenAddr` | `BuildRowAddrs` |
| `$68A7` | `BufferRows` | 160 | The offset of each of the 80 buffer lines (22 bytes a line, from 22: BuildBufferRows fills it). Entry k is 22 (k + 1): one line off from what a 0-based table gives. | `BufferAddr` | `BuildBufferRows` |
| `$6947` | `PlayerVars` | 1 of 24 | Players and scores | `BigByte`, `BigPlot`, `BigPrint`, `HiCompare`, `NewGame` +15 | `BigByte`, `BigPrint`, `CheckHiScore`, `NewGame`, `ScoreUpP1` +7 |
| `$6948` | `Scores` (`PlayerVars`+1) | 5 | the two players' scores, five ASCII digits each; "03000" and "02000" in the image, cleared to "00000" by NewGame | `HiCompare`, `NewGame`, `ScoreDigit`, `ScoreUpP1`, `NameEntry` (`stage1/rec/warp`) +2 | `NewGame`, `ScoreUpP1`, `ScoreDownP1` (`stage1/rec/warp`), `ScoreDownP2` (`stage1/rec/kb`) |
| `$694D` | `ScoreP2` (`PlayerVars`+6) | 5 | player 2's five digits | `HiCompare`, `NewGame`, `CheckHiScore` (`stage1/rec/kb`), `ScoreDigit` (`stage1/rec/kb`), `ScoreDownP2` (`stage1/rec/kb`) | `NewGame`, `ScoreDownP2` (`stage1/rec/kb`) |
| `$6952` | `NameColour` (`PlayerVars`+11) | 1 | the name entry's colour (`$10` player 1, `$28` player 2) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `NameScreen` (`stage1/rec/kb`) | `CheckHiScore` |
| `$6953` | `NameRow` (`PlayerVars`+12) | 1 | the table row the name goes into | `CheckHiScore` (`stage1/rec/kb`), `HiCompare` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$6954` | `NameScorePtr` (`PlayerVars`+13) | 2 | the row's score | `NameScreen` (`stage1/rec/kb`) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$6956` | `NameTextPtr` (`PlayerVars`+15) | 2 | the row's name | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `NameScreen` (`stage1/rec/kb`), `ReadControl` (`stage1/rec/warp`), `l_7BE9` (code) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$6958` | `BigScaleX` (`PlayerVars`+17) | 1 | the big print's horizontal scale | `BigByte`, `BigPrint` | `TrailIntro`, `NameScreen` (`stage1/rec/kb`) |
| `$6959` | `BigScaleY` (`PlayerVars`+18) | 1 | its vertical scale (lines a pixel) | `BigPrint` | `TrailIntro`, `NameScreen` (`stage1/rec/kb`) |
| `$695A` | `BigRepeat` (`PlayerVars`+19) | 1 | its repeat | `BigByte` | `TrailIntro`, `NameScreen` (`stage1/rec/kb`) |
| `$695B` | `BigClear` (`PlayerVars`+20) | 1 | 0 OR the pixels, 1 clear them (the shadow) | `BigPlot` | `TrailIntro` |
| `$695C` | `CursorPos` (`PlayerVars`+21) | 2 | the name entry's cursor (y, x) | `NameCursor` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `ReadControl` (`stage1/rec/warp`), `NameSelect` (code) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$695E` | `BigMask` (`PlayerVars`+23) | 1 | the big print's current bit | `BigByte`, `BigPlot` | `BigByte`, `BigPrint` |
| `$695F` | `HiScoreTitle` | 9 of 11 | "HI SCORE\|" (the table's heading) and "A\|" (the trail intro's big digit: TrailIntro writes the trail's character over the A) | `Print`, `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `PrintAt` (`stage1/rec/fuel`), `ReadControl` (`stage1/rec/warp`) +1 | `TrailIntro`, `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$6968` | `BigChar` (`HiScoreTitle`+9) | 2 | "A\|": a one-character text the trail intro (the trail's digit) and the name entry's letter grid write over | `Print`, `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `PrintAt` (`stage1/rec/fuel`), `ReadControl` (`stage1/rec/warp`) +1 | `TrailIntro`, `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$696A` | `HiNames` | 30 | The high score table's five names, six characters and \| each | `Print`, `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `ReadControl` (`stage1/rec/warp`) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`), `ReadControl` (`stage1/rec/warp`) |
| `$6988` | `HiScores` | 30 | The five scores, five digits and \| each: 20000, 15000, 10000, 05000, 03000 | `HiCompare`, `Print`, `NameEntry` (`stage1/rec/warp`) | `CheckHiScore` (`stage1/rec/kb`), `NameEntry` (`stage1/rec/warp`) |
| `$6C9E` | `PanelP1Sprites` | 13 of 179 | Sprite lists (x, y, sprite, `$FF` the end) and attribute box lists (x1, y1, x2, y2, attribute, `$FF`) of the panels, the HUD and the intros. `$6C9E` PanelP1Sprites, `$6CAB` PanelP2Sprites, `$6CB8` HudSprites, `$6CBF` LoadIntroSprites (sprite lists); `$6CD5` LoadIntroBoxes, `$6CEF` PanelP2Boxes, `$6D18` PanelP1Boxes, `$6D41` HudBoxes (box lists). | `AttrBoxes`, `SpriteList` | - |
| `$6CAB` | `PanelP2Sprites` (`PanelP1Sprites`+13) | 13 | - | `SpriteList` (`stage1/rec/kb`) | - |
| `$6CB8` | `HudSprites` (`PanelP1Sprites`+26) | 7 | - | `SpriteList` | - |
| `$6CBF` | `LoadIntroSprites` (`PanelP1Sprites`+33) | 22 | - | `SpriteList` | - |
| `$6CD5` | `LoadIntroBoxes` (`PanelP1Sprites`+55) | 26 | - | `AttrBoxes` | - |
| `$6CEF` | `PanelP2Boxes` (`PanelP1Sprites`+81) | 41 | - | `AttrBoxes` (`stage1/rec/kb`) | - |
| `$6D18` | `PanelP1Boxes` (`PanelP1Sprites`+122) | 41 | - | `AttrBoxes` | - |
| `$6D41` | `HudBoxes` (`PanelP1Sprites`+163) | 16 | - | `AttrBoxes` | - |
| `$6E5A` | `RandomSeed` | 2 | The random generator's seed word | `Random` | `Random` |
| `$6ED7` | `TrailIntroBoxes` | 11 of 55 | The trail intro's attribute boxes and the credits' sprite and box lists. `$6ED7` TrailIntroBoxes, `$6EE2` CreditBoxes (box lists); `$6EFC` CreditSprites1, `$6F00` CreditSprites2 (sprite lists). | `AttrBoxes`, `HiScoreScreen`, `SpriteList` | `HiScoreScreen`, `Title` |
| `$6EE2` | `CreditBoxes` (`TrailIntroBoxes`+11) | 26 | - | `AttrBoxes` | - |
| `$6EFC` | `CreditSprites1` (`TrailIntroBoxes`+37) | 4 | - | `SpriteList` | - |
| `$6F00` | `CreditSprites2` (`TrailIntroBoxes`+41) | 13 | - | `SpriteList` | - |
| `$6F0D` | `HiScorePage` (`TrailIntroBoxes`+54) | 1 | 0 or 1: the high scores alternate with the credits page each time the menu times out | `HiScoreScreen` | `HiScoreScreen`, `Title` |
| `$702A` | `MenuDefs` | 16 of 128 | The menus: count, x, y, height, then for each item its text and its action (0 none). `$702A` main (START `$6DD1` ClearScreen, ONE/TWO PLAYERS MenuPlayers, CHOOSE CONTROL MenuControl), `$703A` player 1's controls (KEYBOARD, KEMPSTON, EXIT), `$704A`, `$7056` player 2's (KEYBOARD, SINCLAIR), `$7062` player 1's keys, `$707E` player 2's keys (five items each, RedefineKey), `$709A` PLAYER ONE, `$70A2` PLAYER TWO (titles). | `ItemPtr`, `MenuBox`, `MenuBoxFrame`, `MenuDispatch`, `MenuItems` | `MenuPlayers` (`stage1/rec/menu`) |
| `$703A` | `MenuControls1` (`MenuDefs`+16) | 16 | - | `ItemPtr` (`stage1/rec/turn`), `MenuBox` (`stage1/rec/turn`), `MenuBoxFrame` (`stage1/rec/turn`), `MenuDispatch` (`stage1/rec/turn`), `MenuItems` (`stage1/rec/turn`) | - |
| `$704A` | `MenuControls2a` (`MenuDefs`+32) | 12 | - | `ItemPtr` (`stage1/rec/menu`), `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuDispatch` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$7056` | `MenuControls2` (`MenuDefs`+44) | 12 | - | `ItemPtr` (`stage1/rec/menu`), `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuDispatch` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$7062` | `MenuKeys1` (`MenuDefs`+56) | 28 | - | `ItemPtr` (`stage1/rec/menu`), `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuDispatch` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$707E` | `MenuKeys2` (`MenuDefs`+84) | 28 | - | `ItemPtr` (`stage1/rec/menu`), `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuDispatch` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$709A` | `MenuPlayerOne` (`MenuDefs`+112) | 8 | - | `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$70A2` | `MenuPlayerTwo` (`MenuDefs`+120) | 8 | - | `MenuBox` (`stage1/rec/menu`), `MenuBoxFrame` (`stage1/rec/menu`), `MenuItems` (`stage1/rec/menu`) | - |
| `$70AA` | `MenuTexts` | 354 | The front end's texts: two bytes (their centring and width, written by InitTextWidths), the characters, \|. "]" moves the print to x `$78` (the key's column). `$FF` ends the list. | `Credits`, `Highlight`, `InitTextWidths`, `MenuItems`, `Print` +2 | `InitTextWidths`, `RedefineKey` (`stage1/rec/menu`) |
| `$72C5` | `LineSpacing` | 1 | The menu's line spacing (lines) | `Highlight`, `MenuItems` | `MenuBox` |
| `$757F` | `PlayerTexts` | 4 | The texts of the main menu's players item: ONE PLAYER, TWO PLAYERS | `MenuPlayers` (`stage1/rec/menu`) | - |
| `$79D4` | `TrailInks` | 6 | The playfield's attribute of each trail: `$30`, `$20`, `$78`, `$30`, `$20`, `$30` | `TrailAttrs` | - |
| `$79DA` | `TrailNamePtrs` | 12 | The six trail names' addresses | `CopyTrailName` | - |
| `$79E6` | `TrailTexts` | 10 of 88 | "TRAIL NO.\|", the slot "...........\|" (TrailNameSlot) and the six names (11 characters, no \|) | `CopyTrailName`, `Print`, `PrintAt` (`stage1/rec/fuel`) | `CopyTrailName` |
| `$79F0` | `TrailNameSlot` (`TrailTexts`+10) | 78 | - | `CopyTrailName`, `Print`, `PrintAt` (`stage1/rec/fuel`) | `CopyTrailName` |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$69F7` | `DrawModes` | 18 | The front end's draw modes: a routine each, picked by ModeVector (`$82F8` points at the word in use). +0 ModeNone (RET: measure only), +2 ModeCopyScreen, +4 ModeOrScreen (no caller), +6 ModeXorScreen, +8 ModeCopyBuffer, +10 ModeXorBuffer, +12 ModeAttrsNone (RET), +14 ModeAttrsCopy (no caller), +16 BigPrint. | `MenuSpriteAttrs`, `SpriteHeader`, `Wheels` | - |
| `$8080` | `RenderVars` | 4 of 638 | The renderer's and the controls' variables. In the image `$8080-$80B2` hold "UND\|" (the end of TrailsTextLeftover's "REGROUND\|") and an older copy of KeyChars with c, e and s for CAPS SHIFT, ENTER and SYMBOL SHIFT: SetupIm2 writes the vector, ClearKeys the key states before any read. | `AddDeferredAttr`, `AnimObject`, `AnyKey`, `AttrAddr`, `AttrAddrPlay` +110 | `AddDeferredAttr`, `AnimObject`, `AtvPhysics`, `AtvY`, `BigDigit` +100 |
| `$8084` | `AttrBase` (`RenderVars`+4) | 2 | the attribute area the attribute routines write (`$5800`, `$5821` for the top half, `$59A1` for the bottom) | `AttrAddr`, `AttrAddrPlay`, `FillAttrsBase` | `ClearScreen`, `GameEntry`, `NewGame`, `PassP1`, `TrailIntro` +2 |
| `$8086` | `KempstonOn` (`RenderVars`+6) | 1 | 1: player 1 uses the Kempston joystick | `AnyKey`, `MenuTick`, `P1UsesJoystick`, `SelectKey` (`stage1/rec/menu`) | `DetectKempston`, `Init`, `ChooseKempston` (`stage1/rec/menu`), `MenuKeys1Select` (`stage1/rec/menu`) |
| `$8087` | `Keyboard1Alt` (`RenderVars`+7) | 1 | nonzero: player 1's keys are the Sinclair keys 6-0 in a two-player game (no menu item sets it; ChooseKeys1) | `P1UsesJoystick` (`stage1/rec/menu`) | `Init`, `ChooseKeys1` (`stage1/rec/turn`), `MenuKeys1Select` (`stage1/rec/menu`) |
| `$8088` | `SinclairOn` (`RenderVars`+8) | 1 | 0: player 2 uses the keyboard, 1 the Sinclair joystick (keys 6-0) | `P2Down`, `P2Jump`, `P2Left`, `P2Right`, `P2Up` | `Init`, `ChooseSinclair` (`stage1/rec/menu`), `MenuKeys2Select` (`stage1/rec/menu`) |
| `$8089` | `JoyBits` (`RenderVars`+9) | 1 | the Kempston's five bits ORed in by ScanKeys | `AnyKey`, `P1Down`, `P1Jump`, `P1Left`, `P1Right` +3 | `ClearKeys`, `ScanKeys` |
| `$808A` | `FillByte` (`RenderVars`+10) | 1 | FillAttrs's attribute byte | `FillAttrs` | `ClearScreen`, `FillAttrs` |
| `$808B` | `KeyStates` (`RenderVars`+11) | 40 | 40 bytes, 1 for a key held: the eight half-rows from CAPS SHIFT-V to SPACE-B, five keys each, bit 0 first | `AnyKey`, `ClearKeys`, `P2Down`, `P2Jump`, `P2Left` +9 | `ClearKeys`, `ScanKeys` |
| `$80B3` | `KeyChars` (`RenderVars`+51) | 40 | the 40 keys' characters for the menus ("_" a key that cannot be chosen: CAPS SHIFT, ENTER, SYMBOL SHIFT, SPACE) | `ReadNewKey` (`stage1/rec/menu`) | - |
| `$80DB` | `SpriteX` (`RenderVars`+91) | 2 | x in pixels (a word for the trail lists: the item's distance minus the scroll) | `AttrAddr`, `AttrAddrPlay`, `AtvPhysics`, `BarNibble`, `BigPrint` +25 | `AtvPhysics`, `BigPrint`, `ClockPlace`, `ClockTick`, `DrawAtv` +38 |
| `$80DD` | `SpriteY` (`RenderVars`+93) | 2 | y, counted up from the bottom line | `AttrAddr`, `AttrAddrPlay`, `BufferAddr`, `DeferA`, `GroundScan` +10 | `AtvPhysics`, `AtvY`, `ClipY`, `ClockPlace`, `FillAttrs` +29 |
| `$80DF` | `ScreenBase` (`RenderVars`+95) | 6 | the screen's base address for ScreenAddr (`$4000`, or `$4021` / `$48A1` in play) | `ScreenAddr` | `ClearScreen`, `ClockPlace`, `Init`, `PassP1`, `ShowHud` +5 |
| `$80E5` | `DestAddr` (`RenderVars`+101) | 2 | the buffer or screen address a draw mode writes | `BigPrint`, `HiScoreScreen`, `MaskBuffer`, `MaskBufferAlt`, `MaskBufferClip` +12 | `BigPrint`, `ClipY`, `GameSpriteAt`, `HiScoreScreen`, `MenuSpriteAt` +7 |
| `$80E7` | `SpriteNum` (`RenderVars`+103) | 1 | the sprite number | `DeferA`, `GameSprite`, `LoadMask`, `MenuSprite`, `MenuSpriteAttrs` +2 | `AnimObject`, `BigDigit`, `DrawAtv`, `DrawRider`, `FlushDeferredB` +10 |
| `$80E8` | `SpriteData` (`RenderVars`+104) | 2 | the sprite's bytes | `BigPrint`, `ClipTop`, `DrawAtv`, `DrawRider`, `HiScoreScreen` +19 | `ClipTop`, `DrawAtv`, `PlaceClipped`, `SpriteHeader` |
| `$80EA` | `MaskData` (`RenderVars`+106) | 8 | a mask sprite's bytes (the masked modes) | `ClipTop`, `MaskBuffer`, `MaskBufferAlt`, `MaskBufferClip`, `MaskMirror` +1 | `ClipTop`, `DrawAtv`, `DrawRider`, `HiScoreScreen`, `LoadMask` +1 |
| `$80F2` | `SpriteWidth` (`RenderVars`+114) | 1 | width in bytes | `BigPrint`, `ClipTop`, `DrawAtv`, `MaskBuffer`, `MaskBufferAlt` +17 | `SpriteHeader` |
| `$80F3` | `SpriteHeight` (`RenderVars`+115) | 1 | height in lines | `AtvY`, `BigPrint`, `ClipTop`, `DrawAtv`, `InitList` +22 | `ClipTop`, `DrawAtv`, `SpriteHeader` |
| `$80F4` | `ShiftPtr` (`RenderVars`+116) | 2 | the address of the sprite's shift byte (header +3) | `ShiftLeftBy`, `ShiftRightBy`, `SpriteHeader` | `SpriteHeader` |
| `$80F6` | `SpriteAdvance` (`RenderVars`+118) | 1 | the sprite's advance (header +2) | `BigPrint`, `DeferA`, `InitList`, `PlaceClipped`, `PlaceItem` +5 | `BigPrint`, `FlushDeferredB`, `PlaceClipped`, `PlaceItem`, `SpriteHeader` +1 |
| `$80F7` | `AttrDest` (`RenderVars`+119) | 2 | the attribute modes' destination | `AddDeferredAttr`, `CopyAttrs`, `DeferAttrs`, `ModeAttrsCopy` (code) | `DeferAttrs`, `FlushAttrs`, `MenuSpriteAttrs` |
| `$80F9` | `AttrSrc` (`RenderVars`+121) | 2 | a picture's attributes | `AddDeferredAttr`, `CopyAttrs`, `DeferAttrs`, `ModeAttrsCopy` (code) | `DeferAttrs`, `FlushAttrs`, `MenuSpriteAttrs` |
| `$80FB` | `AttrWidth` (`RenderVars`+123) | 1 | - | `AddDeferredAttr`, `CopyAttrs`, `l_7786` (code) | `FlushAttrs`, `MenuSpriteAttrs` |
| `$80FC` | `AttrHeight` (`RenderVars`+124) | 3 | - | `AddDeferredAttr`, `CopyAttrs`, `ModeAttrsCopy` (code), `l_7786` (code) | `FlushAttrs`, `MenuSpriteAttrs` |
| `$80FF` | `LineCount` (`RenderVars`+127) | 1 | ShiftBytesRight / ShiftBytesLeft's line counter | `ShiftBytesLeft`, `ShiftBytesRight` | `ShiftBytesLeft`, `ShiftBytesRight` |
| `$8100` | `ShiftCount` (`RenderVars`+128) | 9 | ShiftLeftBy / ShiftRightBy's bit counter | `ShiftLeftBy`, `ShiftRightBy` | `ShiftLeftBy`, `ShiftRightBy` |
| `$8109` | `KeyIndexes1` (`RenderVars`+137) | 5 | player 1's five keys (KeyStates indexes: left, right, up, down, jump): S, D, F, C, Z | `P1Down` (`stage1/rec/menu`), `P1Jump` (`stage1/rec/menu`), `P1Left` (`stage1/rec/menu`), `P1Right` (`stage1/rec/menu`), `P1Up` (`stage1/rec/menu`) | `RedefineKey` (`stage1/rec/menu`) |
| `$810E` | `KeyIndexes2` (`RenderVars`+142) | 5 | player 2's: H, J, K, M, B | `P2Down` (`stage1/rec/menu`), `P2Jump` (`stage1/rec/menu`), `P2Left` (`stage1/rec/menu`), `P2Right` (`stage1/rec/menu`), `P2Up` (`stage1/rec/menu`) | `RedefineKey` (`stage1/rec/menu`) |
| `$8113` | `Controls1` (`RenderVars`+147) | 1 | player 1's control bits this pass: 4 left, 3 right, 2 up, 1 down, 0 jump | `PassP1`, `ReadP1Controls`, `ReadControlRaw` (`stage1/rec/warp`) | `Interrupt`, `NewGame`, `ReadP1Controls` |
| `$8114` | `Controls2` (`RenderVars`+148) | 1 | player 2's | `PassP2` (`stage1/rec/kb`), `ReadControlRaw` (`stage1/rec/kb`), `ReadP2Controls` (`stage1/rec/menu`) | `Interrupt`, `NewGame`, `ReadP2Controls` (`stage1/rec/menu`) |
| `$8115` | `ClipWidth` (`RenderVars`+149) | 3 | the bytes drawn of a clipped sprite | `AddDeferredAttr`, `CopyAttrs`, `MaskBufferClip`, `OrBufferClip`, `PlaceClipped` | `FlushAttrs`, `PlaceClipped` |
| `$8118` | `ClipSkip` (`RenderVars`+152) | 2 | the bytes skipped of a clipped sprite's lines | `DeferAttrs` | `PlaceClipped` |
| `$811A` | `ClipCode` (`RenderVars`+154) | 1 | PlaceItem's verdict: 0 inside, 1 beyond the right edge, 2 before the left edge, 3 cut at the right, 4 cut at the left | `DeferA`, `PlaceClipped`, `DeferB` (`stage1/rec/warp`) | `FlushDeferredB`, `PlaceItem`, `l_8F09` (code), `l_8F0E` (code), `l_8F14` (code) +2 |
| `$811B` | `ListBase` (`RenderVars`+155) | 2 | the trail list being walked | `WalkList` | `Update` |
| `$811D` | `ListIndexPtr` (`RenderVars`+157) | 2 | the address of the list's index word (DistanceIndex / ScenIndex) | `NextIndex`, `WalkList` | `Update` |
| `$811F` | `ListScroll` (`RenderVars`+159) | 2 | the list's scroll (the distance) | `PlaceItem`, `PlaceItemX` (code) | `Update` |
| `$8121` | `ItemFlags` (`RenderVars`+161) | 1 | the item's draw flags: bit 0 attributes too, bits 1-4 the mask's offset, bit 5 defer to DeferredB, bit 6 defer to DeferredA, bit 7 masked | `DeferA`, `LoadMask`, `PlaceClipped`, `PlaceItem`, `WalkList` +1 | `AnimObject`, `FlushDeferredB`, `InitList`, `PlaceItem` |
| `$8122` | `PlayerIndex` (`RenderVars`+162) | 1 | 0 player 1, 1 player 2: whose pass this is | `AnimObject`, `ScoreStep`, `FuelBarStep` (`stage1/rec/empty`), `ScoreDown` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) | `Players` |
| `$8123` | `SeenCount` (`RenderVars`+163) | 1 | the animated objects stepped this pass (AnimObject; at most 29: the 30th hangs) | `AnimObject` | `AnimObject`, `Players` |
| `$8124` | `SeenIds` (`RenderVars`+164) | 30 | their ids, reset each pass by Players: player 1 adds every id it steps without a check, player 2 skips an id already there, so an object shown in both halves moves once a pass; 30 entries at most (ListOverflow) | `AnimObject` (`stage1/rec/kb`) | `AnimObject` |
| `$8142` | `SavedSp` (`RenderVars`+194) | 2 | SP while ClearBuffer pushes zeros | `ClearBufferP1`, `ClearBufferP2` (`stage1/rec/kb`) | `ClearBufferP1`, `ClearBufferP2` (`stage1/rec/kb`) |
| `$8144` | `BufferBase` (`RenderVars`+196) | 2 | the buffer being drawn (`$F03C` or `$F71C`) | `BufferAddr` | `Credits`, `HiScoreScreen`, `MenuBoxDraw`, `MenuItems`, `PassP1` +4 |
| `$8146` | `DeferredA` (`RenderVars`+198) | 163 | deferred sprites drawn after the ATV (in front of it): the next free offset, `$8148` the count, `$8149` items of 8 bytes (x, y, advance, sprite, routine, clip code, flags) | `DeferA`, `FlushDeferredA`, `FlushDeferredB` | `DeferA`, `Update`, `DeferB` (`stage1/rec/warp`) |
| `$81E9` | `DeferredB` (`RenderVars`+361) | 163 | deferred sprites drawn before the ATV (behind it): offset, count (`$81EB`), items from `$81EC` | `FlushDeferredB`, `DeferB` (`stage1/rec/warp`) | `Update`, `DeferB` (`stage1/rec/warp`) |
| `$828C` | `DeferredAttrs` (`RenderVars`+524) | 108 | deferred attribute copies: offset, count (`$828E`), items of 7 bytes from `$828F` | `AddDeferredAttr`, `FlushAttrs` | `AddDeferredAttr`, `Update` |
| `$82F8` | `ModeVector` (`RenderVars`+632) | 2 | the draw mode word in use (DrawModes or ListModes) | `SpriteHeader` | `ClockPlace`, `Credits`, `DrawAtv`, `DrawRider`, `HiScoreLines` +18 |
| `$82FA` | `AttrModeVector` (`RenderVars`+634) | 2 | the attribute mode word in use | `MenuSpriteAttrs` | `DeferAttrs` |
| `$82FC` | `SpriteCall` (`RenderVars`+636) | 2 | the sprite routine SpriteGo calls (GameSprite, MenuSprite) | `DeferA`, `SpriteGo`, `DeferB` (`stage1/rec/warp`) | `FlushDeferredB`, `InitList`, `PlaceItem`, `AnimObject` (`stage1/rec/warp`) |
| `$836D` | `ListModes` | 12 | The trail lists' draw modes: OR, OR clipped, masked, masked mirrored, masked XOR, masked clipped. +0 OrBuffer, +2 OrBufferClip, +4 MaskBuffer, +6 MaskMirror, +8 MaskBufferAlt, +10 MaskBufferClip. PlaceClipped picks by ClipCode and ItemFlags bit 7. | `DrawAtv`, `DrawRider`, `HiScoreScreen`, `PlaceClipped`, `SpriteHeader` | - |
| `$8F26` | `GfxLeftover` | 54 | 54 bytes before the bank: code no path reaches, a leftover of an earlier build (it calls `$9475`, `$9523` and reads `$63F3`) | - | - |
| `$8F5C` | `GameGfx` | 18260 | The in-game sprite bank: 203 sprites (the ATV, the rider, the ground pieces, the obstacles, the scenery, the font, the digits). +0 the count (203), +1 the bank's length word (`$471E`: it ends at `$D67A`), +3 zero, from +4 a word a sprite: its header's offset from `$8F5C`. Headers as SpriteHeader reads them; the shift byte (+3) is 0 in the image and changes in play. Twelve gaps of two or four bytes between sprites and the 54 bytes `$D67A-$D6AF` after the last are bytes no offset reaches (the end of a sprite's bytes in an older bank). ZXDB POKE 49433,81 ("infinite fuel") writes `$51` over byte 46 of sprite 126 (`$C119`, its line 7): a pixel byte, no effect on the fuel (recording pokes). | `BigByte`, `GameSprite`, `MaskBuffer`, `MaskBufferAlt`, `MaskBufferClip` +14 | `RotateSpriteLeft`, `RotateSpriteRight`, `ShiftBytesLeft`, `ShiftBytesRight`, `ShiftLeftBy` +1 |
| `$DC0D` | `TumbleOffsets` | 6 | The tumbling ATV's height offsets (6 bytes) | `AtvY` | - |
| `$F03C` | `BufferP1` | 197 | The first player's buffer, 22 x 80 bytes (`$F03C-$F71B`), cleared before each use; in the image: `$FF` and `$C4` bytes of `$60` (leftovers), zeros, and trail 6 from `$F230` | `BigPlot`, `CopyLines`, `GroundScan`, `MaskBuffer`, `ModeXorBuffer` +3 | `BigPlot`, `FillFF`, `FrameBox`, `FrameLine`, `MaskBuffer` +4 |
| `$F101` | `BufferP1Zeros` | 303 | zeros (the buffer's middle) | `BigPlot`, `CopyLines`, `GroundScan`, `MaskBuffer`, `ModeXorBuffer` +3 | `BigPlot`, `FillFF`, `FrameBox`, `MaskBuffer`, `ModeCopyBuffer` +4 |
| `$F230` | `Trail6Image` | 650 | Trail 6 (SWAMP) as loaded: GameEntry copies `$F230-$F4B9` to `$60AC`, where its addresses point. Its record and lists; its last 147 bytes (`$F427-$F4B9`, the copy's `$62A3-$6335`) are assembler source text ("LD A,1", "JR MRIGHT", "RIGHT2:LD A,(BDIR)", "CP BOB+8"): the bytes after the trail in the developer's memory, copied along and never read. | `BigPlot`, `CopyLines`, `GameEntry`, `GroundScan`, `MaskBuffer` +8 | `BigPlot`, `FillFF`, `FrameBox`, `MaskBuffer`, `MaskBufferAlt` +10 |
| `$F4BA` | `BufferP1Byte` | 1 | one byte of the same source text after the copied range | `BigPlot`, `CopyLines`, `GroundScan`, `MaskBuffer`, `MaskBufferAlt` +7 | `BigPlot`, `FillFF`, `FrameBox`, `MaskBuffer`, `MaskBufferAlt` +7 |
| `$F4BB` | `BufferP1Rest` | 609 | zeros to BufferP2 | `BigPlot`, `CopyLines`, `GroundScan`, `MaskBuffer`, `MaskBufferAlt` +7 | `BigPlot`, `FillFF`, `FrameBox`, `FrameLine`, `MaskBuffer` +9 |
| `$F71C` | `BufferP2` | 308 | The second player's buffer, 22 x 80 bytes (`$F71C-$FDFB`): zeros in the image up to the tune player at `$F850`, which it overwrites in play | `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`), `OrBuffer` (`stage1/rec/kb`) | `MaskBuffer` (`stage1/rec/kb`), `ModeCopyBuffer` (`stage1/rec/kb`), `OrBuffer` (`stage1/rec/kb`) |

## scores

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7C91` | `TrailsLeftover` | 11 | 11 bytes before the trails' records, read by no one (`$E1` `$79` `$C9` ...: code-like leftovers) | - | - |
| `$EC4E` | `GameTexts` | 9 of 49 | "TIME OUT\|", "OUT OF FUEL\|", "EXTENDED PLAY\|", "LAP TIME     \|" (the lap time written into its blanks) | `Print` | `Update` (`stage1/rec/kb`) |
| `$EC57` | `OutOfFuelText` (`GameTexts`+9) | 12 | - | `Print` (`stage1/rec/warp`) | - |
| `$EC63` | `ExtendedText` (`GameTexts`+21) | 14 | - | `Print` (`stage1/rec/kb`) | - |
| `$EC71` | `LapText` (`GameTexts`+35) | 14 | - | `Print` (`stage1/rec/kb`) | `Update` (`stage1/rec/kb`) |
| `$EE4C` | `ScoreLeftover` | 56 | 56 bytes no code reaches: an older copy of ShowScore and the code after it, assembled one byte lower | - | - |

## trails

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7C9C` | `TrailRecords` | 24 | Trails 1-4: list A, list B, length. Read by SelectTrail (`$EC9C`) as TrailRecords + 6 x Trail (c1: trail 1; trails: trails 1-2; warp: 3-4). | `SelectTrail` | - |
| `$7CB4` | `Trail1ListA` | 128 | Trail 1's list A (the ground and obstacles) | `AnimObject`, `InitList`, `PlaceItem`, `WalkList` | `InitList` |
| `$7D34` | `Trail2ListA` | 236 | Trail 2's list A | `AnimObject` (`stage1/rec/kb`), `InitList` (`stage1/rec/kb`), `PlaceItem` (`stage1/rec/kb`), `WalkList` (`stage1/rec/kb`) | `InitList` (`stage1/rec/kb`) |
| `$7E20` | `Trail3ListA` | 224 | Trail 3's list A | `AnimObject` (`stage1/rec/warp`), `InitList` (`stage1/rec/warp`), `PlaceItem` (`stage1/rec/warp`), `WalkList` (`stage1/rec/warp`) | `AnimObject` (`stage1/rec/warp`), `InitList` (`stage1/rec/warp`) |
| `$7F00` | `Trail4ListA` | 128 | Trail 4's list A | `AnimObject` (`stage1/rec/warp`), `InitList` (`stage1/rec/warp`), `PlaceItem` (`stage1/rec/warp`), `WalkList` (`stage1/rec/warp`) | `InitList` (`stage1/rec/warp`) |
| `$7F80` | `Trail1ListB` | 50 | Trail 1's list B (the scenery) | `InitList`, `PlaceItem`, `WalkList` | `InitList` |
| `$7FB2` | `Trail2ListB` | 56 | Trail 2's list B | `InitList` (`stage1/rec/kb`), `PlaceItem` (`stage1/rec/kb`), `WalkList` (`stage1/rec/kb`) | `InitList` (`stage1/rec/kb`) |
| `$7FEA` | `Trail3ListB` | 32 | Trail 3's list B | `InitList` (`stage1/rec/warp`), `PlaceItem` (`stage1/rec/warp`), `WalkList` (`stage1/rec/warp`) | `InitList` (`stage1/rec/warp`) |
| `$800A` | `Trail4ListB` | 56 | Trail 4's list B | `InitList` (`stage1/rec/warp`), `PlaceItem` (`stage1/rec/warp`), `WalkList` (`stage1/rec/warp`) | `InitList` (`stage1/rec/warp`) |
| `$8042` | `AnimRecords` | 57 | The animation records of trails 1-4's animated objects. An item whose flags have bits 4-7 set points here: +0 the sprite, +1 the flags, +2 the object's id (AnimObject keeps a list of 30 seen ids), then the record's own bytes (the frames and the motion), up to `$FF`. | `AnimObject`, `InitList` | `AnimObject` (`stage1/rec/warp`) |
| `$807B` | `TrailsTextLeftover` | 5 | "REGROUND\|": a text no code prints (a leftover of "FOREGROUND" or "BACKGROUND") | - | - |
| `$EE84` | `Trail5` | 437 | Trail 5 (TROPICANA): its record (list A `$EE8A`, list B `$EF52`, length `$06B5`), the lists and its animation records | `AnimObject` (`stage1/rec/warp`), `InitList` (`stage1/rec/warp`), `PlaceItem` (`stage1/rec/warp`), `SelectTrail` (`stage1/rec/warp`), `WalkList` (`stage1/rec/warp`) | `AnimObject` (`stage1/rec/warp`), `InitList` (`stage1/rec/warp`) |
| `$F039` | `Trail5Tail` | 3 | 3 bytes after trail 5 (with the 33 before them, `$F018-$F038`, shaped as animation records no item points at: leftovers) | - | - |

## loop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D6B6` | `LoopVars` | 2 of 37 | The game's variables | `AtvPhysics`, `ClockTick`, `ControlLeft`, `ControlRight`, `ControlUp` +25 | `AtvPhysics`, `ClockTick`, `GameEntry`, `Init`, `Interrupt` +12 |
| `$D6B8` | `TrailListB` (`LoopVars`+2) | 2 | the trail's list B | `InitListWidths`, `Update` | `SelectTrail`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6BA` | `SavedSp0` (`LoopVars`+4) | 2 | SP at the entry | - | `GameEntry`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6BC` | `FrameCount` (`LoopVars`+6) | 2 | frames counted by Interrupt since the pass began; `$FF` in the front end (the interrupt reads the controls instead) | `Interrupt`, `NewGame` | `Init`, `Interrupt`, `NewGame`, `RotateSpriteLeft` (`stage1/rec/warp`), `AbortKey` (code) |
| `$D6BE` | `Riding` (`LoopVars`+8) | 1 | the players still in: bit 0 player 1, bit 1 player 2 | `NewGame`, `Players`, `TimeOut`, `TrailIntro` | `NewGame`, `RotateSpriteLeft` (`stage1/rec/warp`), `TrailEnd` (`stage1/rec/kb`) |
| `$D6BF` | `Trail` (`LoopVars`+9) | 1 | the trail, 0-5 | `CopyTrailName`, `SelectTrail`, `ShowMaxTime`, `TrailAttrs`, `TrailIntro` +2 | `NewGame`, `RotateSpriteLeft` (`stage1/rec/warp`), `TrailEnd` (`stage1/rec/kb`) |
| `$D6C0` | `FinishDistance` (`LoopVars`+10) | 2 | the trail's length - `$48`: a player whose distance reaches it has finished | `CopyTrailName`, `ShowMaxTime`, `TrailAttrs`, `Update` | `SelectTrail`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6C2` | `HudY` (`LoopVars`+12) | 1 | the half's HUD line (`$BE` top, 6 bottom) | `ShowBars`, `SpeedBar`, `Stop`, `UseFuel` | `PanelP1`, `PassP1`, `PanelP2` (`stage1/rec/kb`), `PassP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6C3` | `PassControls` (`LoopVars`+13) | 1 | the current player's controls this pass | `AtvPhysics`, `ControlLeft`, `ControlRight`, `ControlUp`, `JumpControl` +3 | `PassP1`, `PassP2` (`stage1/rec/kb`), `ReadControl` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6C4` | `GroundY` (`LoopVars`+14) | 5 | the ground under the ATV's wheels (GroundUnder): the higher of `$D6C5` (rear) and `$D6C6` (front); `$D6C7` under the nose, `$D6C8` the nose's line | `AtvPhysics`, `OnGround`, `Tumble` | `AtvPhysics`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6C9` | `Clock` (`LoopVars`+19) | 1 | the clock: three ASCII digits; the last one counts passes (ClockTick), not seconds | `ClockTick`, `NewGame`, `ShowClock`, `DigitsValue` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) +1 | `ClockTick`, `ShowHud`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6CA` | `ClockTens` (`LoopVars`+20) | 1 | - | `ClockTick`, `ShowClock`, `DigitsValue` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) | `ClockTick`, `ShowHud`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6CB` | `ClockUnits` (`LoopVars`+21) | 1 | - | `ClockTick`, `ShowClock`, `DigitsValue` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) | `ClockTick`, `ShowHud`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6CC` | `MaxTime` (`LoopVars`+22) | 3 | the trail's maximum: the clock's first two digits at TIME OUT ("60" = 600 passes) | `NewGame`, `ShowMaxTime`, `DigitsValue` (`stage1/rec/kb`), `l_D89E` (code) | `ShowMaxTime`, `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D6CF` | `MaxTimes` (`LoopVars`+25) | 12 | each trail's maximum: "60", "60", "60", "40", "50", "50"; "30" in the second round (ShowMaxTime) | `ShowMaxTime` | `RotateSpriteLeft` (`stage1/rec/warp`) |

## vehicle

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D70E` | `RecordP1` | 50 | Player 1's record (50 bytes, Record's fields), copied in and out each pass | `LoadRecordP1`, `RecordField`, `RecordFieldP2` | `InitRecords`, `NewGame`, `SaveRecordP1`, `MaskBufferAlt` (`stage1/rec/warp`), `OrBufferClip` (`stage1/rec/warp`) +3 |
| `$D740` | `RecordP2` | 50 | Player 2's record | `RecordField`, `RecordFieldP2`, `LoadRecordP2` (`stage1/rec/kb`) | `InitRecords`, `NewGame`, `RotateSpriteLeft` (`stage1/rec/warp`), `SaveRecordP2` (`stage1/rec/kb`) |
| `$D772` | `Record` | 1 of 50 | The current player's record | `Accelerate`, `Advance`, `AtvPhysics`, `AtvY`, `BackList` +54 | `Accelerate`, `AtvPhysics`, `BackList`, `BackScenery`, `ControlLeft` +51 |
| `$D773` | `VSpeed` (`Record`+1) | 1 | the ATV's vertical speed: `$FD-$F8` rising (negative), 1-5 falling (FallSteps) | `AtvPhysics`, `Fall`, `FastFall`, `JumpControl`, `Rise` +2 | `AtvPhysics`, `Fall`, `JumpControl`, `Landing`, `LoadRecordP1` +3 |
| `$D774` | `Mounted` (`Record`+2) | 1 | 1 the rider is on the ATV, 0 on foot | `ControlLeft`, `ControlRight`, `JumpControl`, `RiderUpdate`, `SaveRecordP1` +3 | `LoadRecordP1`, `MountCheck`, `Throw`, `ControlUp` (`stage1/rec/throwoff`), `LoadRecordP2` (`stage1/rec/kb`) +3 |
| `$D775` | `AtvFrame` (`Record`+3) | 1 | the ATV's sprite: `$38` level, `$3A-$44` nose up and `$46-$4C` nose down by steps of 2, `$5C` turning round (the head-on frame, drawn without the rider), `$7D-$87` tumbling | `AtvPhysics`, `AtvY`, `ControlLeft`, `ControlRight`, `DrawAtv` +12 | `AtvPhysics`, `LoadRecordP1`, `Tumble`, `WheelieDown`, `WheelieUp` +5 |
| `$D776` | `Facing` (`Record`+4) | 1 | 0 right, 1 left | `Advance`, `ControlRight`, `Crash`, `DrawAtv`, `FrontX` +5 | `Crash`, `LoadRecordP1`, `ControlLeft` (`stage1/rec/turn`), `ControlRight` (`stage1/rec/turn`), `LoadRecordP2` (`stage1/rec/kb`) +1 |
| `$D777` | `AtvX` (`Record`+5) | 1 | the ATV's x on screen | `DrawAtv`, `FrontX`, `MountCheck`, `RearX`, `RiderPose` +2 | `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D778` | `AtvHeight` (`Record`+6) | 1 | its height above the bottom line | `AtvPhysics`, `AtvY`, `Crash`, `Fall`, `GroundUnder` +11 | `AtvPhysics`, `Crash`, `Fall`, `LoadRecordP1`, `Rise` +3 |
| `$D779` | `PrevHeight` (`Record`+7) | 2 | the height a pass ago (`$D77A` two passes ago) | `AtvPhysics`, `Crash`, `JumpControl`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`) | `AtvPhysics`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D77B` | `Speed` (`Record`+9) | 1 | the speed level, 0-21 | `Accelerate`, `Advance`, `BackList`, `BackScenery`, `ControlRight` +15 | `Accelerate`, `LoadRecordP1`, `SlowDown`, `Stop`, `LoadRecordP2` (`stage1/rec/kb`) +1 |
| `$D77C` | `Fuel` (`Record`+10) | 2 | the fuel word (`$2000` full; empty under `$400`) | `SaveRecordP1`, `UseFuel`, `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `ShowBars`, `UseFuel`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D77E` | `SpeedBarLen` (`Record`+12) | 1 | the SPEED bar's drawn length | `SaveRecordP1`, `SpeedBar`, `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `SpeedBar`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D77F` | `FuelBar` (`Record`+13) | 1 | the FUEL bar's end x (`$90` + the length) | `SaveRecordP1`, `UseFuel`, `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `ShowBars`, `UseFuel`, `FuelBarStep` (`stage1/rec/empty`), `LoadRecordP2` (`stage1/rec/kb`) +1 |
| `$D780` | `JumpLatch` (`Record`+14) | 1 | 1 while jump is held (one jump a press) | `JumpControl`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`), `l_E415` (code) | `JumpControl`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`), `RiderJumpStart` (code) +1 |
| `$D781` | `TurnLeft` (`Record`+15) | 1 | 1 while the ATV turns round to the left | `ControlLeft`, `ControlRight`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`) | `ControlLeft`, `LoadRecordP1`, `MountCheck`, `LoadRecordP2` (`stage1/rec/kb`), `RiderOnFoot` (`stage1/rec/trail1`) +1 |
| `$D782` | `TurnRight` (`Record`+16) | 1 | 1 while it turns to the right | `SaveRecordP1`, `ControlRight` (`stage1/rec/trail1`), `SaveRecordP2` (`stage1/rec/kb`), `l_E14B` (code) | `ControlRight`, `LoadRecordP1`, `MountCheck`, `LoadRecordP2` (`stage1/rec/kb`), `RiderOnFoot` (`stage1/rec/trail1`) +1 |
| `$D783` | `RiderFrame` (`Record`+17) | 1 | the rider's sprite: 0-8 walking, `$18` jumping, `$59` riding, `$5E-$64` thrown, `$77` lying | `ControlLeft`, `ControlRight`, `DrawRider`, `JumpControl`, `SaveRecordP1` +3 | `ControlLeft`, `ControlRight`, `JumpControl`, `LoadRecordP1`, `MountCheck` +10 |
| `$D784` | `RiderFacing` (`Record`+18) | 1 | 0 right, 1 left | `ControlRight`, `DrawRider`, `MountCheck`, `RiderGround`, `RiderPose` +4 | `LoadRecordP1`, `ControlLeft` (`stage1/rec/trail1`), `ControlRight` (`stage1/rec/trails`), `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D785` | `RiderX` (`Record`+19) | 1 | the rider's x | `ControlRight`, `DrawRider`, `MountCheck`, `RiderGround`, `SaveRecordP1` +5 | `ControlRight`, `LoadRecordP1`, `RiderPose`, `Thrown`, `ControlLeft` (`stage1/rec/trail1`) +5 |
| `$D786` | `RiderHeight` (`Record`+20) | 1 | the rider's height | `DrawRider`, `JumpControl`, `MountCheck`, `RiderGround`, `RiderGroundMounted` +14 | `JumpControl`, `LoadRecordP1`, `RiderOnFoot`, `RiderPoseY`, `RiderToGround` +8 |
| `$D787` | `RiderSavedX` (`Record`+21) | 1 | the rider's x a pass ago (put back when he walks into a step) | `SaveRecordP1`, `RiderOnFoot` (`stage1/rec/trail1`), `SaveRecordP2` (`stage1/rec/kb`) | `DrawRider`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D788` | `RiderSavedHeight` (`Record`+22) | 1 | - | `SaveRecordP1`, `Update`, `SaveRecordP2` (`stage1/rec/kb`) | `DrawRider`, `LoadRecordP1`, `RiderPoseY`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D789` | `Distance` (`Record`+23) | 1 | the distance along the trail, 24 bits (`$D789` the fraction) | `BackList`, `ForwardList`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`) | `BackList`, `ForwardList`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `RotateSpriteLeft` (`stage1/rec/warp`) |
| `$D78A` | `TrackPos` (`Record`+24) | 2 | the distance's whole part: list A's scroll; FinishCheck compares it with FinishDistance | `BackList`, `ForwardList`, `SaveRecordP1`, `Update`, `SaveRecordP2` (`stage1/rec/kb`) | `BackList`, `ForwardList`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/warp`) +5 |
| `$D78C` | `DistanceIndex` (`Record`+26) | 2 | list A's index (WalkList) | `NextIndex`, `SaveRecordP1`, `WalkList`, `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `NextIndex`, `LoadRecordP2` (`stage1/rec/kb`), `WalkList` (`stage1/rec/turn`) |
| `$D78E` | `Scenery` (`Record`+28) | 1 | list B's scroll, 24 bits | `BackScenery`, `ForwardScenery`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`) | `BackScenery`, `ForwardScenery`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `BackList` (code) |
| `$D78F` | `SceneryPos` (`Record`+29) | 2 | its whole part | `BackScenery`, `ForwardScenery`, `SaveRecordP1`, `Update`, `SaveRecordP2` (`stage1/rec/kb`) | `BackScenery`, `ForwardScenery`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `BackList` (code) |
| `$D791` | `ScenIndex` (`Record`+31) | 4 | list B's index | `SaveRecordP1`, `WalkList`, `NextIndex` (`stage1/rec/kb`), `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `NextIndex` (`stage1/rec/kb`) |
| `$D795` | `WheelieTimer` (`Record`+35) | 2 | passes the nose stays up after Up or a jump | `AtvPhysics`, `ControlUp`, `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`) | `ControlUp`, `JumpControl`, `LoadRecordP1`, `FallRider` (`stage1/rec/throwoff`), `LoadRecordP2` (`stage1/rec/kb`) +1 |
| `$D797` | `TumbleCount` (`Record`+37) | 1 | passes of tumbling (0 none) | `Crash`, `Fall`, `SaveRecordP1`, `Tumble`, `SaveRecordP2` (`stage1/rec/kb`) | `Crash`, `LoadRecordP1`, `Tumble`, `LoadRecordP2` (`stage1/rec/kb`) |
| `$D798` | `FallPhase` (`Record`+38) | 1 | the rider's fall after ThrowOff (FallRider: recording throwoff) | `Controls`, `JumpControl`, `RiderUpdate`, `SaveRecordP1`, `FallRider` (`stage1/rec/throwoff`) +2 | `LoadRecordP1`, `ControlUp` (`stage1/rec/throwoff`), `FallRider` (`stage1/rec/throwoff`), `LoadRecordP2` (`stage1/rec/kb`), `l_E32D` (code) |
| `$D799` | `ThrowSpeed` (`Record`+39) | 1 | the thrown rider's flight: `$F8` - speed / 8 up, then down | `Controls`, `JumpControl`, `RiderUpdate`, `SaveRecordP1`, `Throw` +2 | `LoadRecordP1`, `Throw`, `Thrown`, `LoadRecordP2` (`stage1/rec/kb`), `l_E32D` (code) |
| `$D79A` | `EngineNote` (`Record`+40) | 1 | bit 7 the wheel flicker's phase (DrawAtv picks the wheel sprite by it), bits 0-4 the passes to the next flip (EngineTimer: 1 at speed 3 or more, 2 below) | `EngineTimer`, `SaveRecordP1`, `Wheels`, `SaveRecordP2` (`stage1/rec/kb`) | `EngineTimer`, `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`) |
| `$D79B` | `Bonus` (`Record`+41) | 2 | the time bonus, counted into the score at the trail's end | `SaveRecordP1`, `BonusDec` (`stage1/rec/kb`), `SaveRecordP2` (`stage1/rec/kb`) | `LoadRecordP1`, `BonusDec` (`stage1/rec/kb`), `LoadRecordP2` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) |
| `$D79D` | `LapTime` (`Record`+43) | 3 | the clock at the finish (three digits) | `SaveRecordP1`, `SaveRecordP2` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) | `LoadRecordP1`, `LoadRecordP2` (`stage1/rec/kb`), `Update` (`stage1/rec/kb`) |
| `$D7A0` | `GroundBelowRider` (`Record`+46) | 4 | the ground under the rider | `JumpControl`, `RiderOnFoot`, `RiderToGround`, `RiderUpdate`, `SaveRecordP1` +5 | `LoadRecordP1`, `RiderGround`, `LoadRecordP2` (`stage1/rec/kb`), `l_E442` (code) |
| `$D7A4` | `BeeperByte` | 1 of 50 | The last byte sent to port `$FE` (bit 4 the speaker), toggled by Click | `Click`, `InitRecords`, `NewGame`, `PassP1`, `ScoreStep` +9 | `Click`, `Init`, `NewGame`, `SetupIm2`, `TrailEnd` (`stage1/rec/warp`) +1 |
| `$D7A5` | `Finished` (`BeeperByte`+1) | 1 | the players past the finish: bit 0 player 1, bit 1 player 2 | `NewGame`, `PassP1`, `ScoreStep`, `TimeOut`, `BonusP1` (`stage1/rec/kb`) +6 | `Init`, `NewGame`, `Update` (`stage1/rec/kb`) |
| `$D7A6` | `SecondRound` (`BeeperByte`+2) | 1 | 1 after trail 6: the trails again with 30 as every maximum | `ShowMaxTime` | `NewGame`, `TrailEnd` (`stage1/rec/warp`) |
| `$D7A7` | `RecordTemplate` (`BeeperByte`+3) | 47 | a new record (InitRecords): frame `$38`, x `$48`, fuel `$2000`, the bars, the engine 1, lap "000"; its last three bytes are GameEntry's first instruction | `InitRecords` | - |
| `$DEEC` | `RidePoses` | 44 | The mounted rider's sprite for each ATV frame | `RiderPose` | - |
| `$E312` | `RiderJumpTable` | 7 of 13 | The rider's jump steps (`$E314` on, rising `$0A`, `$07`, `$04`, `$02`, then falling `$01`...) and FallSteps (`$E319`: 0, 1, 2, 4, 6) | `Fall`, `FlightStep`, `JumpControl`, `Rise`, `FallRider` (`stage1/rec/throwoff`) | - |
| `$E319` | `FallSteps` (`RiderJumpTable`+7) | 6 | the ATV's fall per pass by VSpeed | `Fall`, `FlightStep`, `Rise`, `FallRider` (`stage1/rec/throwoff`) | - |
| `$E61B` | `WheelOffsets` | 22 | The wheels' x and y offsets for each ATV frame from `$38` (pairs) | `AtvPhysics`, `AtvY` | - |
| `$E797` | `SlopeFrames` | 36 | The frame offset for each line of slope (0-`$14`) | `AtvPhysics`, `NoseHigh` (`stage1/rec/kb`) | - |
| `$E7EF` | `SlopeTable2` | 12 | A table of multiples of 3 no code reads (`$E7AC` is read: SlopeFrames' tail) | - | - |
| `$E86C` | `TumbleFrames` | 24 of 48 | The tumble's frames (`$7D-$87`) and heights (`$E884`) | `Tumble` | - |
| `$E884` | `TumbleHeights` (`TumbleFrames`+24) | 24 | - | `Tumble` | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F9A6` | `CommandPad` | 1 | one byte between the tables | `GameEntry`, `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`), `OrBuffer` (`stage1/rec/kb`) +1 | `Title`, `TrailEnd` (`stage1/rec/trails`) |
| `$FA3C` | `DrumPad` | 2 | two zero bytes after command 1's RET | `GameEntry`, `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`) +3 | `Title`, `TrailEnd` (`stage1/rec/trails`) |
| `$FA48` | `DrumPad2` | 2 | two zero bytes after command 5's RET | `GameEntry`, `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`) +4 | `Title`, `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`), `MaskBufferClip` (`stage1/rec/kb`), `ModeXorBuffer` (`stage1/rec/kb`) +3 |
| `$FB72` | `NoteTable` | 60 | The 60 notes' half-periods, highest first | `GameEntry`, `NoteLookup`, `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`) +5 | `Title`, `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`), `MaskBufferClip` (`stage1/rec/kb`), `ModeXorBuffer` (`stage1/rec/kb`) +3 |
| `$FBAE` | `TuneTable` | 12 | Tune 0 (the title) and tune 1 (the finish): channel A's, channel B's and the drums' sequence lists | `GameEntry`, `NextSequenceD`, `CopyLines` (`stage1/rec/kb`), `GroundScan` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`) +7 | `Title`, `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`), `MaskBufferClip` (`stage1/rec/kb`), `ModeXorBuffer` (`stage1/rec/kb`) +3 |
| `$FBBA` | `SequencesA0` | 579 | The tunes' sequence lists (pattern addresses, 0 then the restart) and the patterns | `CommandsB`, `DrumHit`, `DrumSpeed`, `Drums`, `GameEntry` +13 | `Title`, `ClearBufferP2` (`stage1/rec/kb`), `MaskBuffer` (`stage1/rec/kb`), `MaskBufferAlt` (`stage1/rec/kb`), `MaskBufferClip` (`stage1/rec/kb`) +4 |
| `$FDFD` | `TuneVector` | 3 | JP TuneInterrupt, written by TunePlay (zeros in the image) | - | `TuneKeyCheck`, `TunePlay` |
| `$FE00` | `Im2Table` | 280 | The IM 2 table: `$80` each (SetupIm2) or `$FD` (TunePlay), 257 bytes; zeros in the image | `SetupIm2` | `SetupIm2`, `TunePlay` |
| `$FF18` | `TopLeftover` | 96 | 96 bytes no code reads: system variables and stack bytes, and four glyphs of the ROM's font (A, B, C, D), from the developer's memory | - | - |
