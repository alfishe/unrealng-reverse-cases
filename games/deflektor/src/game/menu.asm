; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The title screen, the options panel, the demo, the practice levels
; --------------------------------------------------------------------------------------------------------------------

; The title screen: a 6912-byte Spectrum screen copied whole to $4000
;
; TitleScreen `$A729` copies these 6912 bytes to the screen (`LD HL,$6000`, `LD
; DE,$4000`, `LD BC,$1B00`, `LDIR` at `$A749`) before the title tune: the
; DEFLEKTOR logo, a laser beam bouncing between crystal blocks, and the credit
; line "WRITTEN BY COSTA PANAYI (c)1987 VORTEX SOFTWARE" on row 23. 6144 pixel
; bytes in the screen's own order, then 768 attributes (8 values: `$02`, `$03`,
; `$05`, `$06`, `$07`, `$1D`, `$3A`, `$42`; no FLASH).
;
; Read in every recording that showed the title (`c1g`, `controls`, `gameover`,
; `kempston`, `menu`, `mine`, `overload`), written by nothing: the image's
; bytes are the picture. The editable form is screens/title.png.
TitlePicture:
  INCBIN "res/screens/title.bin",$0000,6912

; 128 bytes of 0 between the title picture and the panel picture: no code reads
; or writes them
;
; No instruction addresses `$7B00-$7B7F` and no recording reads or writes a
; byte of it. It pads the panel picture to start at `$7B80`, so that it ends at
; `$7FFF` (1152 bytes): a leftover of the layout.
Gap7B00:
  INCBIN "res/leftovers/gap-7b00.bin",$0000,128

  ORG $9ED8

; Draw the options screen into the buffer $E200 / $E500: panels, logo, options,
; hall of fame
;
; Unpacks the screen's attributes from the run-length list `$A053` (count,
; value; `$FF` ends) into 768 bytes at `$E200`, clears the pixel buffer
; `$E500`-`$FCFF` (a linear screen, 32 bytes a row), fills every character
; whose attribute is 2 with the dither `MenuDither` `$9F41`, then prints with
; `$8E3A` (records: attribute + `$80`, column, row, text; a byte with bit 7
; starts the next record, `$FF` ends): "HALL OF FAME" (`$9F49`), the hall of
; fame's names (`$A022`) and scores (`$9FEB`), the logo and the options
; (`$9F59`). `$8B9B` or `$8C95` then copy the buffer to the screen.
;
; Called by `HallOfFame` `$9BC0` (12 runs over all recordings).
;
; Witness: L1 18 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu,
; mine, nameedit, overload, rzx344752).
DrawMenuScreen:
  LD DE,CharMap+512
  LD HL,OptionsLayout
MenuUnpack:
  LD A,(HL)
  CP $FF
  JR Z,MenuClearPixels
  LD B,A
  INC HL
  LD A,(HL)
MenuUnpackRun:
  LD (DE),A
  INC DE
  DJNZ MenuUnpackRun
  INC HL
  JR MenuUnpack
MenuClearPixels:
  LD HL,DrawMarks+512             ; clear the pixel buffer $E500-$FCFF
  LD DE,DrawMarks+513
  LD BC,$17FF
  LD (HL),$00
  LDIR
  LD DE,CharMap+512             ; 24 rows of 32 characters
  LD HL,DrawMarks+512
  LD C,$18
MenuDitherRow:
  LD B,$20
  PUSH HL
MenuDitherChar:
  LD A,(DE)               ; attribute 2: fill the character with the dither
  CP $02
  JR NZ,MenuDitherNext
  PUSH DE
  PUSH BC
  LD DE,MenuDither
  LD BC,$0020
  LD A,$08
MenuDitherRows:
  EX AF,AF'
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  EX AF,AF'
  DEC A
  JR NZ,MenuDitherRows
  DEC H
  POP BC
  POP DE
MenuDitherNext:
  INC HL
  INC DE
  DJNZ MenuDitherChar
  POP HL
  INC H
  DEC C
  JR NZ,MenuDitherRow
  LD HL,HallOfFameTitle   ; the texts
  CALL PrintFull
  LD HL,HallOfFameNames
  CALL PrintFull
  LD HL,HallOfFameScores
  CALL PrintFull
  LD HL,OptionsText
  CALL PrintFull
  RET

; The dither of the options screen's background panels: $AA, $55 alternating
;
; Eight rows put into every character of attribute 2 by `DrawMenuScreen`
; `$9ED8`.
MenuDither:
  INCBIN "res/tables/menu-dither.bin",$0000,8

; The text record "HALL OF FAME" at column $12, row 6, attribute $3B, $FF ends
;
; The records `$8E3A` prints: the first byte, bit 7 set, is the attribute +
; `$80`, then the column, the row, the characters; `$FF` ends the list.
HallOfFameTitle:
  INCBIN "res/texts/options.bin",$0000,16

; The logo and the options: text records for $8E3A, $FF ends
;
; The logo is two rows of the font's characters `a`-`z` and the brackets
; (`$28`, `$29`): the font holds the DEFLEKTOR logo there. Then OPTIONS and the
; seven lines 1 KEYBOARD, 2 SINCLAIR, 3 KEMPSTON, 4 PROTEK-AGF, 5 DEMO, 6
; PRACTICE, 7 START GAME (rows 8-11, 13-14, 16, column 1, attributes `$38`,
; `$39`).
OptionsText:
  INCBIN "res/texts/options.bin",$0010,138

; The name entry's blinking cursor: a small diamond
;
; Put by `HallOfFame` `$9BC0` (at `$9CEC`, attribute `$3A`) at the next
; letter's place, every other 70 polls.
NameCursorGlyph:
  INCBIN "res/graphics/name-cursor.bin",$0000,8

; The hall of fame's six scores: text records of 9 bytes (attribute, column
; $18, row, six digits), $FF ends
;
; Rows 9-14 (`RenumberHallOfFame` `$9E00`), the top one in attribute `$3A`, the
; others `$38`: 090000, 075000, 060000, 045000, 030000, 015000 at the start.
; `HallOfFame` `$9BC0` moves records down and writes a new score; `RankScore`
; `$9E1F` compares with them; `PrintHighScore` `$9B53` shows the first as HIGH.
; `$A021` = `$FF` ends the list; the names follow at `$A022` (8-byte records,
; MEGA, GREAT, GOOD, SO-SO, BAD, AWFUL).
HallOfFameScores:
  INCBIN "res/texts/hall-of-fame.bin",$0000,55

  ORG $A053

; The options screen's layout: 87 runs (count, value) giving 24 x 32 cells, $FF
;
; Read by `$9ED8` (at `$9EDB`): each pair writes `count` copies of `value` to
; `$E200` on, `$FF` ends; the 87 runs fill exactly 768 cells (24 rows of 32).
; Values: `$00` empty, `$3B` and `$38` the attributes of the title box (rows
; 1-2, magenta on white) and of the two panels (rows 5-17: the OPTIONS and HALL
; OF FAME boxes; rows 20-23: the scroller's box), `$02` a shadow cell: `$9ED8`
; draws the checker pattern `$9F41` (`$AA55...`) into the pixel buffer `$E500`
; wherever a cell is `$02`, the drop shadow along the right and bottom edge of
; each box.
;
; Decoded (`.` `$00`, `b` `$3B`, `w` `$38`, `#` `$02`): rows 1-2 cols 7-23 `b`,
; its shadow on row 3; rows 5-17 two boxes cols 0-13 and 17-30 `w`, shadows in
; col 14 / 31 and row 18; rows 20-22 cols 4-26 `w`, shadow col 27 and row 23.
;
; Evidence: read 12 times (every draw of the options screen: `c1g`, `menu`,
; `controls`, `kempston`, `mine`, `overload`, `gameover`, `rzx-344752`).
OptionsLayout:
  INCBIN "res/tables/options-layout.bin",$0000,175

; One byte $FF that no recording reads or writes
;
; No instruction in the image addresses it (searched in `game.skool`); probably
; a spare end mark of the layout above.
UnusedA102:
  DEFB $FF

  ORG $A729

; The title picture and its tune, then the options panel
;
; Called by `$840C` / `$8408` at `$8416` after the menu set-up `$9BC0`. Four
; waits `$8908`, `DI`, waits until no key is held (half rows read with A = 0),
; fills the attributes with the first one's value (`$5800` copied on), copies
; TitlePicture `$6000` (6912 bytes) to the screen, and plays the title tune
; (TitleTune `$AD79`) until a key; then falls into OptionsMenu.
;
; Evidence: 10 runs (`c1g`, `controls`, `gameover`, `kempston`, `menu`, `mine`,
; `overload`).
;
; Witness: L1 14 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu,
; mine, nameedit, overload).
TitleScreen:
  CALL Delay
  CALL Delay
  CALL Delay
  CALL Delay
  DI                      ; no key held, then the picture
TitleKeyReleaseLoop:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,TitleKeyReleaseLoop
  LD HL,Attributes             ; the attributes all as $5800, then TitlePicture to
                          ; the screen
  LD DE,Attributes+1
  LD BC,$02FF
  LDIR
  LD HL,TitlePicture
  LD DE,Screen
  LD BC,$1B00
  LDIR
  CALL TitleTune          ; the title tune until a key

; The options panel: credits on the menu line, keys 1-4 the control, 5 demo, 6
; practice, 7 start
;
; `DI`; `$8C95` (the panel's buffers to the screen); a tone (TwoTone `$465A`,
; 14 frames); waits until no key; CreditsPause = `$FE`; MessageText =
; CreditsMessage; `EI` (the menu scroller runs).
;
; OptionsHighlight: the line of the current ControlMethod `$81FD` (rows 8-11:
; `$4802` + 32 x method, attributes `$5901`): 12 attributes `$3A` (red on
; white), the marker `$9FE3` (an 8 x 8 diamond, drawn by `$9DE8` at the place
; kept in `$9B7C`).
;
; OptionsKeyLoop, until a key: the random seed `$8E32` + 1 (so the game's
; randomness depends on how long the panel stays up); 7 START GAME (`$EFFE` bit
; 3), 5 DEMO (`$F7FE` bit 4: `$8379` = `$FF`), 6 PRACTICE (`$EFFE` bit 4:
; PracticeFlag `$8407` = `$FF`): the chosen line is highlighted (row 16, 13 or
; 14), the marker drawn there, a tone (`$28A0`, 8 frames), `DI`, MenuScroller =
; 0 and return to the new game. Keys 1-4 (`$F7FE` bits 0-3): ControlMethod =
; 0-3, a tone (`$1478`, 4 frames), the old marker wiped (the space glyph
; `$D200`), the old line back to `$38`, and OptionsHighlight again.
;
; Evidence: entered 8 times (`c1g`, `controls`, `energy`, `kempston`, `menu`;
; `energy` and `kempston` start inside it). DEMO once (`menu`); the PRACTICE
; branch `$A7E3` and the practice text `$8A6E` run in `practice`
; (`work/docs/dfA/rec/practice`).
;
; Witness: L1 11 (c1, c1g, controls, energy, energy-out, kempston, menu,
; practice).
OptionsMenu:
  DI
  CALL WipeInScreen
  LD HL,$465A
  CALL TwoTone
OptionsKeyReleaseLoop:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,OptionsKeyReleaseLoop
  LD A,$FE                ; the credits on the menu line, the pause reset
  LD (CreditsPause),A
  LD HL,CreditsMessage
  LD (MessageText),HL
  EI
OptionsHighlight:
  LD A,(ControlMethod)    ; the current control method's line and marker
  LD HL,Screen+2050
  LD DE,Attributes+257
  AND A
  JR Z,OptionsMark
  LD BC,$0020
OptionsRowLoop:
  ADD HL,BC               ; 32 bytes a line per method
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,OptionsRowLoop
OptionsMark:
  LD (NameScreen),HL      ; the places kept for the marker ($9B7C) and the
                          ; attributes ($9B7A)
  LD (NamePointer),DE
  EX DE,HL
  LD (HL),$3A
  INC L
  LD B,$0A
OptionsHighlightLoop:
  INC L
  LD (HL),$3A
  DJNZ OptionsHighlightLoop
  LD HL,NameCursorGlyph   ; the marker
  CALL PutGlyph
OptionsReleaseLoop:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,OptionsReleaseLoop
OptionsKeyLoop:
  LD HL,(RandomSeed)      ; stir the random seed, then 7, 5, 6, 1-4
  INC HL
  LD (RandomSeed),HL
  LD HL,Attributes+513
  LD DE,Screen+4098
  LD A,$EF
  IN A,($FE)
  BIT 3,A
  JR Z,OptionsStart
  LD HL,Attributes+417             ; 5: DEMO
  LD DE,Screen+2210
  LD A,$F7
  IN A,($FE)
  BIT 4,A
  JR NZ,OptionsPracticeKey
  LD A,$FF
  LD (DemoFlag),A
  JR OptionsStart
OptionsPracticeKey:
  LD HL,Attributes+449             ; 6: PRACTICE
  LD DE,Screen+2242
  LD A,$EF
  IN A,($FE)
  BIT 4,A
  JR NZ,OptionsControlKeys
  LD A,$FF
  LD (PracticeFlag),A
OptionsStart:
  LD (HL),$3A             ; highlight the chosen line, the marker, a tone,
                          ; MenuScroller 0
  INC L
  LD B,$0A
OptionsStartLoop:
  INC L
  LD (HL),$3A
  DJNZ OptionsStartLoop
  EX DE,HL
  LD (NameScreen),HL
  LD HL,NameCursorGlyph
  CALL PutGlyph
  LD HL,$28A0
  CALL TwoTone
  DI
  XOR A
  LD (MenuScroller),A
  RET
OptionsControlKeys:
  LD A,$F7                ; 1-4: the control method
  IN A,($FE)
  LD B,$00
  BIT 0,A
  JR Z,OptionsSetControl
  INC B
  BIT 1,A
  JR Z,OptionsSetControl
  INC B
  BIT 2,A
  JR Z,OptionsSetControl
  INC B
  BIT 3,A
  JP NZ,OptionsKeyLoop
OptionsSetControl:
  LD A,B
  LD (ControlMethod),A
  LD HL,$1478
  CALL TwoTone
  LD HL,Font
  CALL PutGlyph
  LD HL,(NamePointer)
  LD B,$0C
OptionsUnhighlightLoop:
  LD (HL),$38             ; the old line back to $38
  INC L
  DJNZ OptionsUnhighlightLoop
  JP OptionsHighlight
