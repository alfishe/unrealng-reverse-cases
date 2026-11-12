; --------------------------------------------------------------------------------------------------------------------
; menu.asm: Title, menu, options, keys, the high-score table and its entry
;
; Intro48 $5D4F is the 48K version's intro (the 128K one is in bank 4, `$D3D0`): a script of pictures built from
; IntroGlyphs (237 eight-byte glyphs at $6313) and texts in the game font, boxed, with attribute blocks and a border
; flash. It repeats until fire is pressed. GameEntry calls it once, before the page tails are copied over its code.
; --------------------------------------------------------------------------------------------------------------------

; The 48K intro: five scenes from IntroScript, looping until fire is pressed
;
; Run only on a 48K (the 128K bootstrap removes the call at `$5CFD`). IY walks
; IntroScript `$5E4D` record by record:
;
; 1. CLS (`$8339` with A = 7); box (`$3090`, 8 x 5) round the eyes picture
; `$5E4D`, the text `$5E64` (FOR 10000 YEARS HE SLEPT ...), the text `$5EB5`
; (NOW HE HAS AWAKENED), the eye frames `$5F06`, `$5F10` (attribute `$42` at
; `$5A9C`), `$5F1A`, each with a wait of 1 x 5 frames, then 40 x 5 frames.
;
; 2. CLS; the attribute block IntroAttrsA `$6225` at `$5882` (5 rows of 3); box
; (`$0008`, 19 x 7) round the picture `$5F24` and the text `$5F56` (THE
; FIREBLADE SHATTERED ...); border white, IntroAttrsB `$6234`, a delay `$2000`,
; border black; the picture `$5FA0` and the text `$5FD2` (THEN THE SLAUGHTER
; BEGAN.).
;
; 3. CLS; IntroAttrsC `$6243` at `$5828` (13 rows of 16); box (`$0F00`, 18 x
; 15) round Havok's picture `$601E` (220 glyphs) and the text `$60FD` (NOW
; HAVOK REIGNS THE UNDERCITY.); the text `$6161` (I AM HIRO ...); a wait of 60
; x 5 frames.
;
; The waits `$831F`/`$8321` return Z when fire (`$8529`) is pressed: then it
; returns; else it starts again.
;
; Witness: L1 3 (c x1, rzx x1). Ran only in c48.
Intro48:
  LD A,$07
  CALL ClearScreen
  LD IY,IntroScript
  LD DE,$3090
  LD BC,$0805
  CALL IntroScene
  CALL IntroPrint
  CALL IntroPictureWait
  CALL IntroPictureWait
  LD A,$42                ; the second eye frame lit
  LD (Attributes+668),A
  CALL IntroPictureWait
  CALL WaitFireLong
  LD A,$07                ; scene 2: the Fireblade
  CALL ClearScreen
  LD HL,IntroAttrsA
  LD DE,Attributes+130
  LD BC,$0503
  CALL CopyAttrBlock
  LD DE,$0008
  LD BC,$0713
  CALL IntroScene
  LD A,$07
  OUT ($FE),A
  LD HL,IntroAttrsB
  LD DE,Attributes+130
  LD BC,$0503
  CALL CopyAttrBlock
  LD BC,$2000
  CALL DelayBC
  LD A,$00
  OUT ($FE),A
  CALL IntroPictureText
  LD A,$07                ; scene 3: Havok and Hiro
  CALL ClearScreen
  LD HL,IntroAttrsC
  LD DE,Attributes+40
  LD BC,$0D10
  CALL CopyAttrBlock
  LD DE,$0F00
  LD BC,$120F
  CALL IntroScene
  CALL IntroText
IntroHold:
  LD H,$3C                ; 60 x 5 frames, then again unless fire
  CALL WaitFireFrames
  JP NZ,Intro48
  RET

; A box, then the next picture and text of the script
;
; DE = the box's screen place, BC = its size: IntroBox `$5DFB`, then
; IntroPictureText.
;
; Witness: L1 9 (c x1, rzx x1). Ran only in c48.
IntroScene:
  CALL IntroBox

; The next picture and text of the script, then a wait of 40 x 5 frames
;
; Witness: L1 12 (c x1, rzx x1). Ran only in c48.
IntroPictureText:
  CALL IntroPicture

; The next text record of the script, then a wait of 40 x 5 frames ($831F)
;
; Witness: L1 15 (c x1, rzx x1). Ran only in c48.
IntroText:
  CALL IntroPrint
  JP WaitFireLong

; The next picture record, then a wait of 1 x 5 frames
;
; H = 1 and `$8321`: the eye frames' step.
;
; Witness: L1 9 (c x1, rzx x1). Ran only in c48.
IntroPictureWait:
  CALL IntroPicture
  LD H,$01
  JP WaitFireFrames

; Draw the picture record at IY with IntroGlyphs; IY to the next record
;
; HL = IY, BC = IntroGlyphs `$6313`, PrintGlyphs `$61E5`.
;
; Witness: L1 21 (c x1, rzx x1). Ran only in c48.
IntroPicture:
  PUSH IY
  POP HL
  LD BC,IntroGlyphs
  CALL PrintGlyphs
  JR IntroScriptNext

; Print the text record at IY ($837B); IY to the next record
;
; Witness: L1 18 (c x1, rzx x1). Ran only in c48.
IntroPrint:
  PUSH IY
  POP HL
  CALL PrintString

; IY = HL, the record after the one just drawn
;
; Witness: L1 39 (c x1, rzx x1). Ran only in c48.
IntroScriptNext:
  PUSH HL
WeaponDefaultItem:
  POP IY                  ; run time: the item record of the default weapon
                          ; (page tail of $5D00, from the template)
  RET

; Build a box of the font's frame glyphs as a text record at $5B01 and print it
;
; DE = Y, X; B = the width, C = the height (in cells). The record: Y, X, style
; `$06` `$06`, the top row (`$22`, `$23` x (B-2), `$24`), `$FF`, C-2 side rows
; (`$25`, a skip of B-2 cells, `$25`, `$FF`), the bottom row (`$27`, `$28` x
; (B-2), `$29`), end; then `$837B` prints it.
;
; Witness: L1 9 (c x1, rzx x1). Ran only in c48.
IntroBox:
  LD (RoomObjectList),DE
  LD A,$06
  LD (RoomObjectList+2),A
  LD (RoomObjectList+3),A
  LD HL,RoomObjectList+4
  PUSH BC
  LD E,$22
  LD D,$24
  LD A,$23
  CALL IntroBoxRow
  LD (HL),$FF
  INC HL
  POP BC
  DEC C
  DEC C
IntroBoxSides:
  PUSH BC
  CALL IntroBoxSide
  POP BC
  DEC C
  JR NZ,IntroBoxSides
  LD E,$27
  LD D,$29
  LD A,$28
  CALL IntroBoxRow
  LD (HL),$00
  LD HL,RoomObjectList
  CALL PrintString
  RET

; Store E, then B-2 times A, then D at HL (a box's top or bottom row)
;
; Witness: L1 18 (c x1, rzx x1). Ran only in c48.
IntroBoxRow:
  DEC B
  DEC B
  LD (HL),E
  INC HL
IntroBoxRowLoop:
  LD (HL),A
  INC HL
  DJNZ IntroBoxRowLoop
  LD (HL),D
  INC HL
  RET

; Store a box side row at HL: $25, a skip of B-2 cells, $25, $FF
;
; A code below `$20` in a text record skips that many cells (`$837B`).
;
; Witness: L1 99 (c x1, rzx x1). Ran only in c48.
IntroBoxSide:
  DEC B
  DEC B
  LD (HL),$25
  INC HL
  LD (HL),B
  INC HL
  LD (HL),$25
  INC HL
  LD (HL),$FF
  INC HL
  RET

; The 48K intro's script: 8 pictures and 7 texts in the order Intro48 draws
; them
;
; A picture: Y, X (pixels / 2), glyph numbers (1-`$ED`, into IntroGlyphs),
; `$FF` a new line, 0 the end. A text: Y, X, two style bytes, the characters
; (font `$7BE5`), `$FF` a new line, 0 the end (the record of `$837B`).
;
; Its bytes are under the page tails of `$5D00-$6100` at run time (GameEntry
; copies the template over them after the intro): the labels in here from
; `$5FC0` on name those run-time contents.
IntroScript:
  INCBIN "res/texts/intro.bin",$0000,371
SetTune:
  INCBIN "res/texts/intro.bin",$0173,11
HavokRoomLeave:
  INCBIN "res/texts/intro.bin",$017E,9
HavokRoomEnter:
  INCBIN "res/texts/intro.bin",$0187,174
SizeClasses:
  INCBIN "res/texts/intro.bin",$0235,355

; Draw a picture record: B = Y, C = X, then glyph n at BC + 8(n-1), $FF a new
; line, 0 the end
;
; HL = the record, BC = the glyph set. The place is set by `$83CD`; each glyph
; is drawn by `$83F9` (8 bytes at BC + 8 (n-1)); `$FF` moves to the next line
; (`$83C6` holds the line start, `$83CD` again). Returns HL past the 0.
;
; The entries PrintGlyphsLoop to PrintGlyphsLine are split off because stage
; 2's code occupies these addresses while the tape loads, and the recordings
; mark routine entries there.
;
; Witness: L1 1141 (c x2, rzx x1). Ran only in c48.
PrintGlyphs:
  PUSH BC
  LD B,(HL)
  INC HL
  LD C,(HL)
  PUSH HL
  CALL SetPrintPosition
  POP HL
  POP BC
  INC HL

; The next byte of the record
;
; Witness: L1 1086 (c x1, rzx x1).
PrintGlyphsLoop:
  LD A,(HL)

; 0 ends the record
;
; Witness: L1 1246 (c x2, rzx x1).
PrintGlyphsNext:
  INC HL
  OR A
  RET Z
  PUSH BC

; $FF: a new line; else the glyph's address
;
; Witness: L1 1227 (c x2, rzx x1).
PrintGlyphsByte:
  PUSH HL
  INC A
  JR Z,PrintGlyphsNewLine
  DEC A
  DEC A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL

; HL = 8(n-1) + the glyph set; draw it ($83F9)
;
; Witness: L1 1122 (c x2, rzx x1).
PrintGlyphsAddress:
  ADD HL,HL
  ADD HL,BC
  CALL PrintGlyph

; The glyph is drawn: the next byte
;
; Witness: L1 1065 (c x1, rzx x1).
PrintGlyphsDone:
  POP HL

; POP BC, back to the loop
;
; Witness: L1 2295 (c x2, rzx x1).
PrintGlyphsRestore:
  POP BC
  JR PrintGlyphsLoop
; This entry point is used by the routine at PrintGlyphsByte.
PrintGlyphsNewLine:
  LD BC,(PrintStringNewline+$0001) ; BC = the line start $83C6

; Set the print place to BC ($83CD), back to the loop
;
; Witness: L1 1347 (c x2, rzx x1).
PrintGlyphsLine:
  CALL SetPrintPosition
  JR PrintGlyphsDone

; Copy B rows of C bytes from HL to the attributes at DE (DE + 32 a row)
;
; From Intro48 (IntroAttrsA/B/C).
;
; Witness: L1 1299 (c x2, rzx x1). Ran only in c48.
CopyAttrBlock:
  PUSH BC
  PUSH DE
  LD B,$00
  LDIR
  POP DE
  LD A,$20
  ADD A,E
  LD E,A
  LD A,$00

; The high byte of DE + 32
;
; Witness: L1 71 (c x2, rzx x1).
CopyAttrBlockCarry:
  ADC A,D
  LD D,A
  POP BC
  DJNZ CopyAttrBlock
  RET

; Intro scene 2's attributes: 5 rows of 3 bytes at $5882
IntroAttrsA:
  INCBIN "res/graphics/intro-attrs.bin",$0000,15

; Intro scene 2's attributes after the border flash: 5 rows of 3
IntroAttrsB:
  INCBIN "res/graphics/intro-attrs.bin",$000F,15

; Intro scene 3's attributes: 13 rows of 16 at $5828
IntroAttrsC:
  INCBIN "res/graphics/intro-attrs.bin",$001E,208

; The 48K intro's 237 glyphs (8 bytes each, glyph 1 first)
;
; Read by PrintGlyphs `$61E5` through IntroPicture (BC = `$6313`). A graphics
; resource (237 x 8 = 1896 bytes, to `$6A7A`).
;
; At run time these bytes are under the actor pages `$6300-$6600` (with their
; page tails, the globals at `$6642`) and the room planes `$6700-$6A7A`: the
; labels inside name those run-time contents (the rows are cut there).
IntroGlyphs:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0000,475
WeaponTemplate:
  INCBIN "res/graphics/intro-glyphs-1.bin",$01DB,18
ActorPage9:
  INCBIN "res/graphics/intro-glyphs-1.bin",$01ED,184
SharedEnemyTemplate:
  INCBIN "res/graphics/intro-glyphs-1.bin",$02A5,18
HiroTemplate:
  INCBIN "res/graphics/intro-glyphs-1.bin",$02B7,18
TitlePieceTemplate:
  INCBIN "res/graphics/intro-glyphs-1.bin",$02C9,18
TitleWhiteRows:
  INCBIN "res/graphics/intro-glyphs-1.bin",$02DB,18
WeaponActor:
  INCBIN "res/graphics/intro-glyphs-1.bin",$02ED,66
Vitality:
  INCBIN "res/graphics/intro-glyphs-1.bin",$032F,1
VitalityShown:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0330,1
ChargeStep:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0331,1
Charge:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0332,1
ChargeShown:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0333,1
ChargeReset:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0334,1
FirePrevious:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0335,1
WeaponCount:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0336,1
WeaponCountShown:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0337,1
Weapon:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0338,1
PauseFlag:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0339,1
Lives:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033A,1
Fragments:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033B,1
FragmentsShown:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033C,1
FireRequest:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033D,1
Invulnerable:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033E,1
EndFlags:
  INCBIN "res/graphics/intro-glyphs-1.bin",$033F,1
Score:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0340,4
ScoreLine:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0344,4
ScoreDigits:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0348,9
LivesDigits:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0351,3
StatusLine:
  INCBIN "res/graphics/intro-glyphs-1.bin",$0354,10
WeaponIcon:
  INCBIN "res/graphics/intro-glyphs-1.bin",$035E,17
PauseGame:
  INCBIN "res/graphics/intro-glyphs-1.bin",$036F,52
PendingMessage:
  INCBIN "res/graphics/intro-glyphs-1.bin",$03A3,7
RunBanner:
  INCBIN "res/graphics/intro-glyphs-1.bin",$03AA,11
ShowMessage:
  INCBIN "res/graphics/intro-glyphs-1.bin",$03B5,5

; Not code: IntroGlyphs bytes that the kit must list as instructions
;
; These are bytes of IntroGlyphs (`$66CD-$66F6`, glyphs 120-125). At run time
; the page tail of `$6600` puts ShowMessage's `RRA` at `$66CD`, and the image
; holds the same byte `$1F` there, so the recordings count a ran instruction at
; this address and the disassembly goes on through the glyph bytes to `$66F6`.
; Nothing jumps here in the image.
;
; Witness: L1 12 (gameover, menu, opt x3, rzx x5).
GlyphBytesAsCode:
  RRA
GlyphBytesTail:
  RRA                     ; the rest of the glyph bytes, as data
  RLCA
  DAA
  LD DE,PanelWeaponClear+$0002
  RST $38
  DEFB $FD
  RST $38
  OR L
  RST $38
  LD D,L
  RST $38
  RST $38
  RST $38
  LD D,L
  RST $38
  LD D,L
  RST $38
  LD D,L
  JP PE,PanelAttrsRoomEnd
  LD D,L
  RST $38
  LD D,L
  RST $38
  LD B,B
  SUB L
  PUSH AF
  RST $38
  LD D,L
  RST $38
  LD D,L
  RLCA
  AND C
  LD H,H
  LD C,A
  RST $28
  LD D,L
  RST $38

; IntroGlyphs continued; at run time $66F7-$66FF is the cell colour table (page
; tail of $6600)
;
; At run time (after BuildPageTails) the nine bytes are `07 47 46 07 46 05 47
; 06 45`: the render's `$88BA` takes the attribute of a revealed cell from here
; by the high nibble of its plane byte; TitleSequence `$A754` reads the last
; six (TitleColours `$66FA`) as the title's colours. In the image the entry is
; the rest of IntroGlyphs, to `$6A7A`.
CellColours:
  INCBIN "res/graphics/intro-glyphs-2.bin",$0000,3
TitleColours:
  INCBIN "res/graphics/intro-glyphs-2.bin",$0003,482
EnemySlots:
  INCBIN "res/graphics/intro-glyphs-2.bin",$01E5,256
HiroFallScript:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02E5,1
BoxClip:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02E6,2
MapRow:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02E8,1
MapColumn:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02E9,1
Strike:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02EA,2
FireHeld:
  INCBIN "res/graphics/intro-glyphs-2.bin",$02EC,152

; The control menu: keys 1-4 choose joystick 1, joystick 2, Kempston or Protek
; / cursor; patch the input code
;
; CLS (A = 0), print ControlMenuText `$6ACB` (`$836E`), wait for one of the
; keys 1-4 (`$F7FE`, read until one is held; key 1 first). HL = ControlRecords
; `$6B0A` + 14 x (key - 1); the record patches the input read:
;
; - +0 the fire mask, to `$84CA` and to FirePrevious's start value `$5C06`;
;
; - +1 the direction mask, to `$850F` and `$8511`;
;
; - +2 `RRA` or `NOP`, to `$8513`;
;
; - +3..+6 the opcodes `DEC E` / `INC E` / `INC D` / `DEC D` in the record's
; direction order, to `$851A`, `$851E`, `$8522`, `$8526`;
;
; - +7 on: 18 bytes of code copied to `$8529`, the fire test (Z when fire).
;
; Called from GameEntry once (the menu is not shown again).
;
; Witness: L1 2 (c x2). Ran in c1 and c48.
ControlMenu:
  XOR A
  CALL ClearScreen
  LD HL,ControlMenuText
  CALL PrintStringTall
  LD DE,$000E
; This entry point is used by the routine at ControlMenuKey.
ControlMenuWait:
  LD A,$F7
  IN A,($FE)
  LD HL,ControlRecords
  LD B,$04

; The next key (bit) of 1-4
;
; Witness: L1 9813576 (deaths, gameover, menu, c x2, opt x3, rzx x1).
ControlMenuKey:
  RRA
  JR NC,ControlMenuPatch
  ADD HL,DE
ControlMenuNext:
  DJNZ ControlMenuKey     ; the next key bit (a return point of the key test)
  JR ControlMenuWait
ControlMenuPatch:
  LD A,(HL)               ; HL = the chosen record
  INC HL
  LD (TickInput+$000B),A
  LD (GlobalsInit+$0006),A
  LD A,(HL)
  LD (DecodeDirection+$0001),A
  LD (DecodeDirection+$0003),A
  INC HL
  LD A,(HL)
  LD (DecodeDirection+$0005),A
  INC HL
  LD A,(HL)
  LD (DecodeDirection+$000C),A
  INC HL
  LD A,(HL)
  LD (DirectionBit2+$0003),A
  INC HL
  LD A,(HL)
  LD (DirectionBit3+$0003),A
  INC HL
  LD A,(HL)
  LD (DirectionBit4+$0003),A
  INC HL
  LD DE,ReadInput         ; the fire test code
  LD BC,$0012
  LDIR
  RET

; The control menu as a text record ($836E): Y $34, X $0E, style $07 $47, four
; lines
ControlMenuText:
  INCBIN "res/texts/control-menu.bin",$0000,17
ItemCount:
  INCBIN "res/texts/control-menu.bin",$0011,1
EnemyCount:
  INCBIN "res/texts/control-menu.bin",$0012,1
EnemyListPtr:
  INCBIN "res/texts/control-menu.bin",$0013,2
ZoneCount:
  INCBIN "res/texts/control-menu.bin",$0015,1
ZoneRecords:
  INCBIN "res/texts/control-menu.bin",$0016,41

; The four control records (14 bytes): fire mask, direction mask, RRA/NOP, four
; direction opcodes, the fire test
;
; Keys 1 and 2 are the Sinclair joysticks (keys 6-0, fire 0; keys 1-5, fire 5),
; 3 the Kempston port `$1F` (bits inverted by CPL, so the `RRA` slot is a
; `NOP`), 4 the Protek / cursor keys 5-8 and 0.
;
; The last record's fire test is 18 bytes (`$6B3B-$6B4C`); the others' 7 bytes
; are followed by the next record (18 bytes are always copied, the rest is
; never reached). The cursor test reads `$F7FE` (key 5) and `$EFFE` and ANDs
; them, but only bit 0 (key 0) is tested.
ControlRecords:
  DEFB $01,$1E,$1F,$1D,$1C,$14,$15 ; 1: Sinclair 1 (row $EFFE)
  DEFB $3E,$EF,$DB,$FE,$CB,$47,$C9 ; LD A,$EF; IN A,($FE); BIT 0,A; RET
  DEFB $10,$0F,$00,$15,$14,$1C,$1D ; 2: Sinclair 2 (row $F7FE)
  DEFB $3E,$F7,$DB,$FE,$CB,$67,$C9 ; LD A,$F7; IN A,($FE); BIT 4,A; RET
  DEFB $10,$0F,$00,$14,$15,$1C,$1D ; 3: Kempston
  DEFB $DB,$1F,$2F,$CB,$67,$C9,$00 ; IN A,($1F); CPL; BIT 4,A; RET; NOP
  DEFB $01,$1E,$1F,$15,$14,$1D,$1C ; 4: Protek / cursor
  DEFB $3E,$F7,$DB,$FE,$F6,$EF,$0F ; the 18-byte cursor fire test
  DEFB $0F,$0F,$4F,$3E,$EF,$DB,$FE
  DEFB $A1,$CB,$47,$C9

; Zeros between the menu (end of block 5) and the template (block 4)
ControlGap:
  INCBIN "res/leftovers/control-gap.bin",$0000,15

  ORG $A6EC

; Hold the finished logo 4 s, then show the high-score table 4 s
;
; Reached from TitleSequence (`JP` at `$A7CA`) when the second wave of pieces
; is in. 40 times: the fire test (the hook `$A6EF`) and WaitFire `$8321` with H
; = 1 (5 frames); fire returns to the caller of TitleSequence (`$5C55`: the
; game starts).
;
; Then the screen is cleared black and printed (`$837B` / `$836E`): the header
; `$80FB` "RANK SCORE NAME"; ten rank lines "NO.1" to "NO.10" from the record
; `$810F` (Y from `$14` in steps of 16, X 2), its two digits written at `$8116`
; / `$8117` (`" 1"`... `" 9"`, then `"10"` printed as E = '1', D = '0'); the
; table `$8119` (ten lines of score and name, the tall font) and the copyright
; line `$81F0`. WaitFire `$831F` (40 x 5 frames) returns on fire, else falls
; into TitleSequence.
;
; 26 runs (c48, gameover, menu).
;
; Witness: L1 29 (gameover, menu, c x1, rzx x2, rzxroom x1).
ShowHighScores:
  LD B,$28
ShowHighScoresHold:
  PUSH BC
  CALL ReadInput          ; hook: 48K CALL $8529 (fire: Z); the 128K bootstrap
                          ; writes CALL $859E (fire, and left / right pick
                          ; music or effects)
  EI
  LD H,$01
  CALL WaitFireFrames     ; 5 frames
  POP BC
  RET Z
  DJNZ ShowHighScoresHold
  XOR A                   ; clear the screen: black
  CALL ClearScreen
  LD HL,HiScoreHeading    ; "RANK     SCORE       NAME"
  CALL PrintString
  LD HL,$0214             ; the first rank line: Y $14, X 2; D E = " 1"
  LD D,$20
ShowHighScoresRank:
  LD E,$31
ShowHighScoresRankLoop:
  LD (HiScoreRankText+$0007),DE ; the digits into "NO.", the position into the
                                ; record, print
  LD (HiScoreRankText),HL
  PUSH DE
  PUSH HL
  LD HL,HiScoreRankText
  CALL PrintString
  POP HL
  LD DE,$0010
  ADD HL,DE
  POP DE
  LD A,$30                ; just printed NO.10?
  CP D
  JR Z,ShowHighScoresTable
  INC E
  LD A,$3A
  CP E
  JR NZ,ShowHighScoresRankLoop
  LD D,$30                ; after "9": D = '0', E = '1' prints "10"
  JR ShowHighScoresRank
ShowHighScoresTable:
  LD HL,HiScoreTableHead  ; the table and the copyright line, the tall font
  CALL PrintStringTall
  CALL PrintStringTall
  CALL WaitFireLong       ; 200 frames, fire returns
  RET Z

; The title: the SWITCHBLADE logo assembled from flying pieces, until fire is
; pressed
;
; Called from `$5C52` (after the controls menu and after every game). Returns
; when fire is pressed (Z), to `$5C55`, which starts a game.
;
; `$76D0` = `$B6` (the low byte of the pointer into the piece order `$76B6`),
; `$76D1` = 0 (the stage); the handler flag `$845F` = 1 (no game tick). The
; screen is cleared with the next attribute of the six at `$66FA-$66FF` (the
; operand of `LD HL,n` at `$A74A` steps through them and wraps): the logo's
; colour changes every cycle. The hook `$A75C` (128K: CALL `$85B3`, print the
; music or effects sign). LoadTitlePieces `$A7D7` sets up the first wave: 15
; pieces from `$7600` into the pages `$5D00-$6B00`.
;
; TitleStep `$A766`, once a pass: from the fourth piece on, the fire test (the
; hook `$A76F`; Z returns). IY = the page of the moving piece (`$76B6` +
; stage); its timer +`$3F` counts down; at 0 the effect `$0B` is asked
; (`$8454`) and the next piece moves (`$76D0`, `$76D1` + 1). The piece moves by
; its +`$40` (Y) and +`$41` (X) (`$9B71`), `$8F3B` places it, the rows of its
; area are cleared, and the pieces are drawn (`$8A79` with B = the piece count,
; `$8C68`).
;
; Stage `$0F` (15 pieces in): the stage becomes `$10` and the second wave of 11
; pieces is loaded from `$7669`. Stage `$1A`: `$65EE` (code put there at run
; time: the attributes `$59E0-$5ADF` = `$47`) on each pass. Stage `$1B`:
; ShowHighScores `$A6EC`.
;
; 38 runs; TitleStep 8666 (c1, c48, deaths, gameover, menu, opt2-4).
;
; Witness: L1 41 (deaths, gameover, menu, c x2, opt x3, rzx x2, rzxroom x1).
TitleSequence:
  LD HL,TitleSceneIndex
  LD (HL),$B6
  INC L
  XOR A
  LD (HL),A
  INC A
  LD (InterruptHandler+$0009),A ; the handler flag $845F = 1: the tick does not
                                ; run
  LD HL,TitleColours      ; the operand steps through the six colours
                          ; $66FA-$66FF
  LD A,L
  CP $00
  JR NZ,TitleColour
  LD L,$FA
TitleColour:
  LD A,(HL)
  INC L
  LD (TitleSequence+$000D),HL
  CALL ClearScreen        ; clear the screen with this cycle's attribute
  NOP                     ; hook: 48K three NOPs; the 128K bootstrap writes
                          ; CALL $85B3 (the music / effects sign)
  NOP
  NOP
  LD HL,TitleActors       ; the first wave: 15 pieces from $7600
  LD A,$0F
  JR LoadTitlePieces
TitleStep:
  LD A,(TitleSceneIndex)  ; the piece order pointer: three pieces in yet?
  LD L,A
  CP $B9
  JR C,TitleMovePiece
  PUSH HL
  CALL ReadInput          ; hook: 48K CALL $8529 (fire: Z); the 128K bootstrap
                          ; writes CALL $859E
  EI
  POP HL
  RET Z
TitleMovePiece:
  LD H,$76                ; IY = the moving piece's page; its timer
  LD H,(HL)
  LD L,$00
  PUSH HL
  POP IY
  LD L,$3F
  DEC (HL)
  JR NZ,TitleMove
  LD A,$0B                ; arrived: effect $0B, the next piece
  LD (EffectRequest),A
  EXX
  LD HL,TitleSceneIndex
  INC (HL)
  INC L
  INC (HL)
  EXX
TitleMove:
  INC L                   ; DE = the step: +$40 Y, +$41 X
  LD E,(HL)
  INC L
  LD D,(HL)
  CALL AddMove
  CALL ActorBoxStore
TitleMoveDraw:
  LD A,(BlitWindowWidth+$0002) ; the piece at its new place: the window width
  LD C,A
  EX DE,HL
  LD E,$00
  JR NC,TitleClearArea
  LD E,$08
TitleClearArea:
  LD A,(PackRowLines+$0001) ; clear the rows of the piece's area
  ADD A,E
TitleClearRow:
  PUSH HL
  LD B,A
TitleClearByte:
  LD (HL),$00
  INC L
  DJNZ TitleClearByte
  POP HL
  INC H
  DEC C
  JR NZ,TitleClearRow
  LD B,$00                ; B = the pieces of the wave (the operand $A7B5, set
                          ; by LoadTitlePieces)
  LD DE,$A001             ; D = $A0, E = 1: the active bit, for $8A79 (not an
                          ; address)
  CALL DrawActors
  CALL BlitWindow
  LD HL,TitleSceneStep    ; the stage: $1A colour pass, $1B the high scores,
                          ; $0F the second wave
  LD A,(HL)
  CP $1A
  CALL Z,TitleWhiteRows
  CP $1B
  JP Z,ShowHighScores
  CP $0F
  JR NZ,TitleStep
  INC A                   ; stage $0F: the second wave, 11 pieces from $7669
  LD (HL),A
  LD L,$69
  LD A,$0B
LoadTitlePieces:
  LD (TitleClearByte+$000B),A ; A pieces of 7 bytes at HL into the pages from
                              ; $5D00
  LD B,A
  LD D,$5D
LoadTitlePiecesLoop:
  PUSH BC                 ; Y, X, frame (the template's last byte $65ED),
                          ; InitActor with $65DC
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,(HL)
  LD (TitlePieceTemplate+$0011),A
  INC L
  LD E,$00
  PUSH HL
  PUSH DE
  LD HL,TitlePieceTemplate
  EX DE,HL
  CALL InitActor
  POP DE
  POP HL
  LD E,$3F                ; timer, Y step, X step to +$3F-+$41
  LD BC,$0003
  LDIR
  LD E,$0A                ; byte 6 to +$0A
  LDI
  INC D
  POP BC
  DJNZ LoadTitlePiecesLoop
  JP TitleStep

; Put the score into the high-score table and ask for the name
;
; Called from `$5C45` (the game's end; the game over `$5C42` comes in there
; too). The score's 8 ASCII digits `$665B-$6662` are compared with each entry's
; 8 digits (`$811D` + 21 i), from the top: an 8-byte subtraction with borrow
; from the last digit; the first entry the score is not below is the place (a
; tie goes above). Below the tenth: return.
;
; Entries i to 8 move down one place (LDDR of 21 x (9 - i) bytes ending at
; `$81EE`; C counts it from `$BD` = 189 and ends at `$EB`), the digits go in,
; the name position `$A8C9` = 0, the handler flag `$845F` = 1, the screen is
; cleared black, EnterName `$A861`; the typed name (`$82C2-$82CB`, '-' turned
; into spaces) is copied into the entry's 10 name bytes.
;
; 1 run (gameover: the score was not high enough, `$A826` returned). The entry
; ran in the RZX run (rzx-c, frame 142 000), which has no L1 yet.
;
; Witness: L1 6 (gameover, rzx x5).
InsertHighScore:
  LD C,$BD
  LD HL,HiScoreEntries+$0008
InsertHighScoreEntry:
  LD B,$08
  LD DE,ScoreDigits+$0008 ; DE: one past the score's 8 ASCII digits
  XOR A
  LD (EnterNamePut+$0001),A
InsertHighScoreCompare:
  DEC HL                  ; score - entry, digit by digit with borrow
  DEC DE
  LD A,(DE)
  SBC A,(HL)
  DJNZ InsertHighScoreCompare
  JR NC,InsertHighScorePlace
  LD DE,$001D             ; below this entry: the next one (HL - 8 + 29 = + 21)
  ADD HL,DE
  LD A,C
  SUB $15
  LD C,A
  CP $EB                  ; past the tenth: no entry
  RET Z
  JR InsertHighScoreEntry
InsertHighScorePlace:
  PUSH HL                 ; move the entries below down one place
  LD A,C
  OR A
  JR Z,InsertHighScoreDigits
  LD HL,HiScoreEntries+$00BC
  LD DE,HiScoreEntries+$00D1
  LDDR
InsertHighScoreDigits:
  LD HL,ScoreDigits       ; the score's digits into the entry
  POP DE
  LD C,$08
  LDIR
  INC DE                  ; DE = the entry's name
  PUSH DE
  LD A,$01                ; the handler flag $845F = 1
  LD (InterruptHandler+$0009),A
  XOR A
  CALL ClearScreen
  CALL EnterName
NameEntered:
  LD HL,NameEntryLetters+$000A ; the typed name: '-' (empty) becomes a space
  LD A,$2D
  LD B,$0A
InsertHighScoreBlank:
  DEC HL
  CP (HL)
  JR NZ,InsertHighScoreBlankNext
  LD (HL),$20
InsertHighScoreBlankNext:
  DJNZ InsertHighScoreBlank
  POP DE                  ; the 10 name bytes into the entry
  LD C,$0A
  LDIR
  RET

; Name entry: a grid of letters, a box moved with the controls, fire types
;
; The name buffer `$82C2-$82CB` = ten '-' (the empty-slot glyph, an
; underscore). Hiro's Y and X bytes are the cursor: `$5D00` the row (0-4),
; `$5D01` the column (0-5), set to 4, 5 (the END sign). The underline record
; `$82CD` = Y `$A0`, X `$12`. Printed: "WELL DONE! YOU HAVE A HIGH SCORE" /
; "PLEASE ENTER YOUR NAME" (`$822C`, the tall font), the grid `$826A` (A-Z,
; '!', a blank, '<' delete, '+' END, 6 x 5) and the box `$82AE`; ten delays
; `$8330` (about 2 s, so the fire that ended the game does not type).
;
; The loop: the name `$82BE` (tall) and the underline `$82CD` (" / ": the '/'
; glyph is a bar under the next letter); then `$8529` (the chosen control's
; reader: Z = fire, A = the direction bits) and `$850E` (E = the row step, D =
; the column step, carry when one is pressed) until fire; a direction moves the
; box (MoveNameBox `$A8E2`).
;
; Fire (`$A8A1`): a short delay; NameLetterIndex `$A91B`: 0-25 types 'A'-'Z',
; 26 '!', 27 a space, 28 deletes ('-' at the position and one back), 29 (END)
; returns. Typing writes at the position `$A8C9` (the operand of `LD A,n` at
; `$A8C8`) and moves on, at most to the tenth (the tenth can be typed over);
; the underline's X (`$82CE`) moves 2 a letter.
;
; Not run in the keyed recordings (the gameover score did not reach the table);
; the RZX run enters a name (rzx-c, frame 142 000; the screen in
; docs/img/play/screens.png).
;
; Witness: L1 5 (rzx x5).
EnterName:
  LD B,$0A
  LD HL,NameEntryLetters
EnterNameClear:
  LD (HL),$2D
  INC HL
  DJNZ EnterNameClear
  LD HL,$0504             ; the cursor: row 4, column 5 (END), in Hiro's Y and
                          ; X bytes
  LD (Hiro),HL
  LD HL,$12A0             ; the underline: Y $A0, X $12
  LD (NameEntryMark),HL
  LD HL,HighScoreMessage  ; the two lines, the letter grid, the box
  CALL PrintStringTall
  CALL PrintString
  CALL PrintString
  LD L,$0A                ; ten delays
EnterNameDelay:
  CALL PauseLong
  DEC L
  JR NZ,EnterNameDelay
EnterNameRedraw:
  LD HL,NameEntryText     ; the name and the underline
  CALL PrintStringTall
  CALL PrintString
EnterNameWait:
  CALL ReadInput          ; fire? else a direction moves the box
  JR Z,EnterNameFire
  CALL DecodeDirection
  CALL C,MoveNameBox
  JR EnterNameWait
EnterNameFire:
  LD BC,$8000             ; the box's sign: a letter, '!', space, delete or END
  CALL DelayBC
  CALL NameLetterIndex
  CP $1A
  JR C,EnterNameLetter
  LD C,$21                ; 26: '!'
  JR Z,EnterNameForward
  DEC C                   ; 27: a space
  CP $1B
  JR Z,EnterNameForward
  CP $1C                  ; 28: delete; 29: END returns
  RET NZ
EnterNameDelete:
  LD C,$2D                ; '-' at the position, one back, not below 0
  LD E,$FF
  LD D,E
  JR EnterNamePut
EnterNameLetter:
  ADD A,$41               ; 0-25: 'A' + n
  LD C,A
EnterNameForward:
  LD E,$01                ; one on, not past the tenth
  LD D,$0A
EnterNamePut:
  LD A,$01                ; A = the position (the operand $A8C9)
  LD B,A
  LD HL,NameEntryLetters
  ADD A,L
  LD L,A
  LD (HL),C
  LD A,B
  ADD A,E
  CP D
  JR Z,EnterNameRedraw    ; at the limit: the position stays
  LD (EnterNamePut+$0001),A
  LD HL,NameEntryMark+$0001 ; the underline's X += 2 x step
  LD A,E
  ADD A,A
  ADD A,(HL)
  LD (HL),A
  JR EnterNameRedraw

; Move the name-entry box by E rows and D columns, inside the 6 x 5 grid
;
; A step out of the grid is ignored. The box is erased at its old place (its Y
; and X copied from `$82AE` into the blank record `$80EB`, printed), the new Y
; and X come from the word table `$700C` (2 bytes a sign, by NameLetterIndex)
; and the box is printed (`$82AE`); then a delay (`$8330`). Not run in the
; keyed recordings.
;
; Witness: L1 17924 (rzx x5).
MoveNameBox:
  LD HL,Hiro
  LD A,E
  ADD A,(HL)
  RET M
  CP $05
  RET Z
  LD E,A
  INC L
  LD A,D
  ADD A,(HL)
  RET M
  CP $06
  RET Z
  LD (HL),A
  DEC L
  LD (HL),E
  LD HL,(NameCursorText)  ; erase the box at its old place
  LD (CursorEraseText),HL
  LD HL,CursorEraseText
  CALL PrintString
  CALL NameLetterIndex    ; the new place from the table $700C
  ADD A,A
  ADD A,$0C
  LD L,A
  LD H,$70
  LD E,(HL)
  INC L
  LD D,(HL)
  LD (NameCursorText),DE
  LD HL,NameCursorText
  CALL PrintString
  JP PauseLong

; A = row x 6 + column of the name-entry box (0-29)
;
; BC = (`$5D00`): C the row, B the column; `$8EDD` gives 6 x row. Not run in
; the keyed recordings.
;
; Witness: L1 73 (rzx x5).
NameLetterIndex:
  LD BC,(Hiro)
  LD H,C
  LD E,$06
  CALL Multiply8
  LD A,B
  ADD A,L
  RET
