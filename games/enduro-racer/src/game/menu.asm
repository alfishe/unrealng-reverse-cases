; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The attract loop, the main menu, the control methods, DEFINE KEYS, the text printer, the keys
;
; Attract wipes the screen and scrolls four credit lines up from the bottom (CreditList), then waits about 5 seconds
; (250 WaitKey units) for a key; with none it starts a demo race (DemoMode 8-15, the low bits of the distance) through
; NewGame. A key gives Menu: START GAME, ONE/TWO PLAYERS, CHANGE CONTROL MODE, DEFINE KEYS, chosen by MenuSelect
; (SPACE or fire picks, THROTTLE moves up, any other key down; about 23 seconds with no key go back to Attract).
;
; The control methods (ControlTable, ControlMethod): 0 KEYBOARD (the keys of DEFINE KEYS, Q A O P SPACE by default), 1
; KEMPSTON, 2 SINCLAIR RIGHT, 3 SINCLAIR LEFT, 4 CURSOR. PatchControls writes a method's five half-row bytes and masks
; into ReadControls' code (and DE = $FE20, or $1F28 for the Kempston: port $FE with JR NZ, or port $1F with JR Z);
; PAUSE (H) and RESET (R) are always keys. ReadControls returns D: bit 0 throttle, 1 wheelie, 2 left, 3 right, 4
; brakes (fire), 5 pause, 6 reset.
;
; The printer draws 8x8 characters of Font through RowTable (PrintChar: A the code, B the column, C the pixel line, E
; the attribute; B moves on), so the same code draws on the screen or, with RowTable pointing at it, into the back
; buffer.
; --------------------------------------------------------------------------------------------------------------------

  ORG $810C

; Wipe, scroll the credits up, wait for a key; none: a demo race; a key: Menu
;
; ClearScreen; ScrollPhase = 1; for each of the four CreditList records: the
; line printed centred at the bottom (pixel line 183), then ScrollUp the
; record's count of times, KeyOrFire stopping it into Menu. Then WaitKey with
; 250 units: a key gives Menu; none: DemoMode = 8 + (the distance AND 7) and
; NewGame plays a demo race.
;
; Recorded: c1: the credits from frame 11646; the demo from the attract in m128
; and c1 before the menu key.
;
; Witness: L1 5 (c1, m128, names, stages).
Attract:
  CALL ClearScreen
  LD A,$01
  LD (ScrollPhase+$0001),A
  LD IX,CreditList
  LD HL,CreditTexts
  LD A,(IX+$00)
  INC IX
l_8120:
  EX AF,AF'
  LD A,$20
  SUB (IX+$00)
  RRA
  LD B,A
  LD C,$B7
  LD D,(IX+$00)
  LD E,(IX+$01)
  CALL PrintString
  LD B,(IX+$02)
l_8136:
  PUSH HL
  PUSH BC
  CALL ScrollUp
  CALL KeyOrFire
  POP BC
  POP HL
  JR NZ,Menu
  DJNZ l_8136
  INC IX
  INC IX
  INC IX
  EX AF,AF'
  DEC A
  JR NZ,l_8120
  LD BC,$00FA
  CALL WaitKey
  JR NC,Menu
  LD A,(TrackDistance)
  AND $07
  ADD A,$08
  LD (DemoMode),A
  CALL NewGame            ; the demo race (NewGame with DemoMode set)

; After a demo: wait 200 units, show the high scores (ShowScores), wait 750
; units, Attract again
;
; A key at either wait gives Menu. Known only from the code: no recording let a
; demo end (each pressed a key during it or before it).
AttractScores:
  LD BC,$00C8
  CALL WaitKey
  JR NC,Menu
  LD C,$20
  CALL ShowScores
  LD BC,$02EE
  CALL WaitKey
  JR C,Attract

; The main menu: draw it, MenuSelect, then the item's action
;
; ClearScreen; DemoMode 0; MenuItem 0; the top four character rows' attributes
; $79; below them every attribute with a paper colour cleared to 0; the frame
; (FrameChars), MenuLayout's texts, ONE or TWO PLAYERS, MenuLayout2's texts.
; MenuSelect over MenuItems: timeout: Attract; 0: NewGame; 1: Players 1 <-> 2;
; 2: the method window (ControlItems, MenuSelect, ControlMethod,
; PatchControls); 3: DefineKeys.
;
; Recorded: c1, m128, ctl: every item; twoplayer: item 1.
;
; KeyItem 0; the window; DefineItems' texts; the seven keys (PrintKey) beside
; them; MenuSelect: EXIT (0) or timeout back to the menu; item n: its old key's
; three-letter place blanked (Blanks), GetKey; the key's character goes to Keys
; + n - 1, its half-row byte to ControlTable + n - 1, its mask (XOR $1F) to
; ControlTable + n + 4; the cursor moves to the next item; a key already in use
; is refused (DefineTaken); keys 6 and 7 (PAUSE, RESET) patch ReadControls'
; last two tests (DefinePauseKey). Then method 0 and PatchControls.
;
; Recorded: ctl: DEFINE KEYS, keys 1-5 set.
;
; Witness: L1 8 (c1, ctl, m128).
Menu:
  CALL ClearScreen
  XOR A
  LD (DemoMode),A
  LD (MenuItem),A
  LD HL,$5800
  LD B,$80
l_8187:
  LD (HL),$79
  INC L
  DJNZ l_8187
MenuDraw:
  LD HL,$5880             ; redraw the menu (the actions come back here)
  LD BC,$0280
l_8192:
  LD A,(HL)
  AND $38
  JR Z,l_8199
  LD (HL),$00
l_8199:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_8192
  LD (PrintOrigin+$0001),BC
  LD E,$78
  LD IX,FrameChars
  LD HL,$1E02
  CALL DrawFrame
  LD HL,MenuTexts
  LD IX,MenuLayout
  CALL PrintList
  LD BC,$0A50
  LD A,(Players)
  DEC A
  PUSH AF
  JR Z,l_81C6
  INC HL
  INC HL
  INC HL
l_81C6:
  LD DE,$0346
  CALL PrintString
  LD HL,PlayerCountTexts+$0006
  LD D,$07
  POP AF
  JR Z,l_81D5
  INC D
l_81D5:
  CALL PrintString
  LD A,$20
  CALL PrintChar
  LD HL,MenuTexts2
  CALL PrintList
MenuChoose:
  LD A,(MenuItem)         ; MenuSelect over the four items
  LD HL,MenuItems
  LD E,$08
  CALL MenuSelect
  JP C,Attract
  LD (MenuItem),A
  AND A
  JP Z,NewGame
  DEC A
  JR NZ,MenuControl
  LD A,(Players)
  XOR $03
  LD (Players),A
  JP MenuDraw
MenuControl:
  DEC A                   ; CHANGE CONTROL MODE
  JR NZ,DefineKeys
  LD BC,$0858
  LD HL,$1005
  CALL DrawWindow
  LD HL,ControlTexts
  LD IX,ControlItems
  CALL PrintList
  LD A,(ControlMethod)
  LD HL,ControlItems
  LD E,$10
  CALL MenuSelect
  JP C,MenuDraw
  LD (ControlMethod),A
  LD DE,$FE20             ; not RowTable: PatchControls' D and E, port $FE and
                          ; JR NZ
  CP $01
  JR NZ,l_8237
  LD DE,$1F28
l_8237:
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD IX,ControlTable
  ADD IX,BC
  CALL PatchControls
  JP MenuDraw
DefineKeys:
  DEC A                   ; DEFINE KEYS: the eight items (EXIT and the seven
                          ; keys); a picked key waits for a key press and
                          ; stores it
  JP NZ,MenuDraw
  LD (KeyItem),A
  LD BC,$0C68
  LD HL,$0E08
  CALL DrawWindow
  LD HL,DefineTexts
  LD IX,DefineItems
  CALL PrintList
; This entry point is used by the routine at DefinePauseKey.
l_8265:
  LD HL,Keys
  LD C,$10
l_826A:
  LD E,$57
  LD B,$0C
  LD A,(HL)
  PUSH HL
  CALL PrintKey
  POP HL
  INC HL
  LD A,C
  ADD A,$08
  LD C,A
  CP $48
  JR C,l_826A
  LD HL,DefineItems
  LD A,(KeyItem)
  LD E,$10
  CALL MenuSelect
  JP C,MenuDraw
  AND A
  JP Z,MenuDraw
  LD E,A
  INC A
  AND $07
  LD (KeyItem),A
  PUSH DE
  LD BC,(RestoreBar+$0001)
  LD B,$0C
  LD DE,$0348
  LD HL,Blanks
  CALL PrintString
; This entry point is used by the routine at DefineTaken.
l_82A6:
  CALL GetKey
  LD B,E
  POP DE
  LD D,$00
  LD IX,ControlMethod
  ADD IX,DE
  LD (IX+$00),D
  LD D,$07
  LD HL,Keys              ; is the key one of the seven already?
; This entry point is used by the routine at DefineTaken.
l_82BB:
  CP (HL)
  JR NZ,l_82C1

; The key is in use: back to GetKey
;
; Known only from the code: ctl gave five different keys.
DefineTaken:
  PUSH DE
  JR l_82A6
; This entry point is used by the routine at Menu.
l_82C1:
  INC HL                  ; next key of the seven
  DEC D
  JR NZ,l_82BB
  LD (IX+$00),A
  LD A,B
  XOR $1F
  LD B,A
  LD A,E
  LD DE,$FE20
  CP $06
  JR C,l_82E1

; Items 6 and 7: patch ReadControls' PAUSE ($85E5) or RESET ($85EF) test
; directly
;
; Known only from the code: ctl set only the five driving keys.
DefinePauseKey:
  LD HL,TestPause+$0001
  JR Z,l_82DC
  LD HL,TestReset+$0001
l_82DC:
  CALL PatchTest
  JR l_82F2
; This entry point is used by the routine at DefineTaken.
l_82E1:
  LD (IX+$07),C           ; store the half-row byte and the mask in method 0's
                          ; row
  LD (IX+$0C),B
  XOR A
  LD (ControlMethod),A
  LD IX,ControlTable
  CALL PatchControls
l_82F2:
  CALL RestoreBar
  JP l_8265

; Write method IX's five half-row bytes and masks, with D and E, into
; ReadControls' five tests
;
; In: IX = a ControlTable row, D = the port's low byte ($FE or $1F), E = the
; jump's opcode ($20 JR NZ for the active-low keyboard, $28 JR Z for the
; active-high Kempston). Each test at $85B2 + 10n gets C (the LD A operand), D
; (the IN port), B (the AND mask), E (the JR opcode).
;
; Witness: L1 8 (c1, ctl, m128).
PatchControls:
  LD HL,ReadControls+$0003
  LD B,$05
l_82FD:
  PUSH BC
  LD C,(IX+$00)
  LD B,(IX+$05)
  CALL PatchTest
  POP BC
  DJNZ l_82FD
  RET

; One test: (HL) = C, +2 = D, +4 = B, +5 = E; HL += 10, IX += 1
;
; Witness: L1 40 (c1, ctl, m128).
PatchTest:
  LD (HL),C
  INC HL
  INC HL
  LD (HL),D
  INC HL
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  LD BC,$0005
  ADD HL,BC
  INC IX
  RET

; The control method, 0-4 (CHANGE CONTROL MODE)
ControlMethod:
  DEFB $03

; The keys of method 0: THROTTLE Q, WHEELIE A, LEFT O, RIGHT P, BRAKES SPACE
; (3), PAUSE H, RESET R
;
; Character codes as KeyMap gives them; 1-4 stand for SYMBOL SHIFT, ENTER,
; SPACE and CAPS SHIFT (KeyNames).
Keys:
  INCBIN "res/texts/keys.bin",$0000,7

; Five methods, 10 bytes each: the half-row bytes of THROTTLE, WHEELIE, LEFT,
; RIGHT, BRAKES, then their masks
;
; Row 0 is KEYBOARD (DEFINE KEYS writes it): $FB $FD $DF $DF $7F, masks 1 1 2 1
; 1 (Q A O P SPACE); 1 KEMPSTON: all 0 (the port is $1F), masks 8 4 2 1 $10; 2
; SINCLAIR RIGHT: $EF, masks 2 4 $10 8 1 (keys 9 8 7 6 0); 3 SINCLAIR LEFT:
; $F7, masks 8 4 1 2 $10 (4 3 1 2 5); 4 CURSOR: $EF $EF $F7 $EF $EF, masks 8
; $10 $10 4 1 (keys 7 6 5 8 0). The last three masks ($8352-$8354) are also the
; three bytes PrintKeyName's base KeyNamesBase (KeyNames - 3) points at; it
; never reads them (codes 1-4). src/res/tables/controls.csv.
ControlTable:
  INCBIN "res/tables/controls.bin",$0000,50

; SYM, ENT, SPC, CPS: the names of the keys 1-4, three letters each
KeyNames:
  INCBIN "res/texts/keynames.bin",$0000,12

; Print key code A (1-4) as its three-letter name
;
; Witness: L1 3 (c1, ctl).
PrintKeyName:
  LD HL,KeyNamesBase
l_8364:
  INC HL
  INC HL
  INC HL
  DEC A
  JR NZ,l_8364
  LD D,$03                ; three characters

; Print D characters from HL (B column, C line, E attribute); HL and B move on
;
; Witness: L1 41186 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
PrintString:
  LD A,(HL)
  CALL PrintChar
  INC HL
  DEC D
  JR NZ,PrintString
  RET

; A below 5: PrintKeyName; else PrintChar
;
; Witness: L1 21 (c1, ctl).
PrintKey:
  CP $05
  JR C,PrintKeyName

; Print character A at column B, pixel line C, attribute E (SetAttr), then B +
; 1
;
; The glyph is Font + 8 * (A - $20) (the code's base $7508 = Font - $100); each
; of its 8 rows goes to RowTable's line C + n, column B + PrintOrigin's column.
; Registers kept but B.
;
; Recorded: c1: the menu, the HUD.
;
; Witness: L1 57774 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
PrintChar:
  CALL SetAttr

; the glyph without the attribute (DrawScore's digits, the lap table's numbers)
;
; Witness: L1 63405 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
PrintGlyph:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
PrintOrigin:
  LD HL,$0000             ; LD HL,nn: nn = the origin (column, line) added to
                          ; BC by SetAttr and PrintGlyph; set by DrawWindow,
                          ; cleared by Menu
  ADD HL,BC
  LD B,H
  LD C,L
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD DE,Font-$100
  ADD HL,DE
  EX DE,HL
  LD L,C
  LD C,B
  LD B,$08
  LD H,$7F
  ADD HL,HL
l_8398:
  LD A,(HL)
  INC L
  PUSH HL
  LD H,(HL)
  OR C
  LD L,A
  LD A,(DE)
  INC E
  LD (HL),A
  POP HL
  INC HL
  DJNZ l_8398
  POP HL
  POP DE
  POP BC
  POP AF
  INC B
  RET

; Print A (0-255) in decimal, no leading zeros, ending at column B (it prints
; the high digits first, recursively)
;
; Witness: L1 12418 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
PrintNumber:
  CP $0A
  JR C,l_83C1
  LD D,$00
l_83B1:
  SUB $0A
  JR C,l_83B8
  INC D
  JR l_83B1
l_83B8:
  ADD A,$0A
  PUSH AF
  DEC B
  LD A,D
  CALL PrintNumber
  POP AF
l_83C1:
  ADD A,$30
  JR PrintChar

; Clear an H x L character area at PrintOrigin = BC, attribute $4F, and draw a
; frame round it (FrameChars2)
;
; Witness: L1 9 (c1, ctl, m128).
DrawWindow:
  LD E,$4F
  LD (PrintOrigin+$0001),BC
  PUSH HL
  LD C,$08
l_83CE:
  LD B,$01
  LD D,H
l_83D1:
  LD A,$20
  CALL PrintChar
  DEC D
  JR NZ,l_83D1
  LD A,C
  ADD A,$08
  LD C,A
  DEC L
  JR NZ,l_83CE
  POP HL
  LD BC,$0000
  LD IX,FrameChars2
  JR DrawFrame

; The name entry's 1 x 1 frame (IX's eight characters) round the cell at
; DrawCursor's BC operand, attribute $46
;
; Witness: L1 105 (names, stages).
DrawCursor:
  LD BC,$0000
  DEC B
  LD A,C
  SUB $08
  LD C,A
  LD E,$46
  LD HL,$0101

; A frame of IX's eight characters (corners, edges) round an H x L area at
; column B, line C, attribute E
;
; Witness: L1 183 (c1, crash, ctl, fall5, m128, names, stages, truck,
; twoplayer).
DrawFrame:
  LD A,(IX+$00)
  PUSH BC
  CALL PrintChar
  LD D,H
  LD A,(IX+$01)
l_8402:
  CALL PrintChar
  DEC D
  JR NZ,l_8402
  LD A,(IX+$02)
  CALL PrintChar
  POP BC
l_840F:
  LD A,C
  ADD A,$08
  LD C,A
  PUSH BC
  LD A,(IX+$03)
  CALL PrintChar
  LD A,B
  ADD A,H
  LD B,A
  LD A,(IX+$04)
  CALL PrintChar
  POP BC
  DEC L
  JR NZ,l_840F
  LD A,C
  ADD A,$08
  LD C,A
  LD A,(IX+$05)
  CALL PrintChar
  LD A,(IX+$06)
l_8434:
  CALL PrintChar
  DEC H
  JR NZ,l_8434
  LD A,(IX+$07)
  JP PrintChar

; The attribute of column B, pixel line C (plus PrintOrigin) = E
;
; Witness: L1 59717 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
SetAttr:
  PUSH HL
  PUSH BC
  PUSH AF
  LD HL,(PrintOrigin+$0001)
  ADD HL,BC
  LD B,H
  LD A,L
  AND $F8
  LD L,A
  LD H,$16
  ADD HL,HL
  ADD HL,HL
  LD A,L
  OR B
  LD L,A
  LD (HL),E
  POP AF
  POP BC
  POP HL
  RET

; The timer (Timer, BCD) in big digits at column 13, line 24: tens (blank when
; 0) and units
;
; Witness: L1 502 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
PrintTimer:
  LD DE,$0D18
  LD A,(Timer)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  JR NZ,l_847B
  LD HL,Blanks
  LD B,D
  LD C,E
  LD DE,$0269
  CALL PrintString
  LD BC,$0D20
  LD D,$02
  CALL PrintString
  JR l_847E
l_847B:
  CALL BigDigit
l_847E:
  LD DE,$0F18             ; units
  LD A,(Timer)
  AND $0F

; Digit A (0-9) of BigDigits at column D, line E: 15 rows of two bytes through
; RowTable, SP as the pointer
;
; SavedSp ($7C38) keeps SP; SP = RowTable + 2 * line; each POP gives a line's
; address. An interrupt during it is repaired by Interrupt (the pops read
; RowTable).
;
; Witness: L1 1013 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
BigDigit:
  LD B,A
  INC B
  LD A,$F1
l_848A:
  ADD A,$0F
  DJNZ l_848A
  LD C,A
  LD HL,BigDigits
  ADD HL,BC
  ADD HL,BC
  LD C,D
  LD B,$0F
  EX DE,HL
  LD H,$7F
  ADD HL,HL
  LD (SavedSp),SP
  LD SP,HL
l_84A0:
  POP HL
  LD A,L
  OR C
  LD L,A
  LD A,(DE)
  INC E
  LD (HL),A
  INC L
  LD A,(DE)
  INC DE
  LD (HL),A
  DJNZ l_84A0
  LD SP,(SavedSp)
  RET

; The credits' scroll: every pixel line one line up (through RowTable); every
; eighth call the attributes one row up
;
; Witness: L1 820 (c1, m128, names, stages).
ScrollUp:
  LD HL,RowTable+$0001
  LD DE,$4000
  EXX
  LD B,$BF
l_84BB:
  EXX
  INC HL
  LD A,(HL)
  INC L
  PUSH HL
  LD H,(HL)
  LD L,A
  PUSH HL
  LD A,$01
  CALL Copy32
  POP DE
  POP HL
  EXX
  DJNZ l_84BB
ScrollPhase:
  LD A,$00                ; LD A,n: n counts 1-7, 0 moves the attributes
  INC A
  AND $07
  LD (ScrollPhase+$0001),A
  RET NZ
  LD HL,$5820
  LD DE,$5800
  LD A,$16
  JP Copy32

; NZ when a key is pressed (or, for the Kempston, fire)
;
; Witness: L1 665534 (c1, ctl, m128, names, stages).
KeyOrFire:
  CALL ScanKeys
  INC A
  RET NZ
  LD A,(ControlMethod)
  DEC A
  JR NZ,l_84F1

; Kempston: A = port $1F AND $1F (NZ: a direction or fire)
;
; Known only from the code: the attract and the menus were left by keys in
; every recording.
KempstonFire:
  IN A,($1F)
  AND $1F
  RET
; This entry point is used by the routine at KeyOrFire.
l_84F1:
  XOR A                   ; no key: Z
  RET

; A = the character of the first key down (KeyMap), $FF none; B, D: its half
; row and bit
;
; The eight half rows from port $FEFE up, five bits each; the character is
; KeyMap's (5 * row + bit), the code's base $851A = KeyMap - 6.
;
; Witness: L1 690526 (c1, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).
ScanKeys:
  LD BC,$08FE
l_84F6:
  LD DE,$051E
l_84F9:
  LD A,C
  IN A,($FE)
  AND $1F
  CP E
  JR Z,ScanFound
  SLL E
  RES 5,E
  DEC D
  JR NZ,l_84F9
  RLC C
  DJNZ l_84F6
  LD A,$FF
  RET
ScanFound:
  LD A,B                  ; the character
  ADD A,A
  ADD A,A
  ADD A,B
  ADD A,D
  PUSH HL
  LD HL,KeyMap-6
  ADD A,L
  LD L,A
  JR NC,l_851D

; INC H: not reached (KeyMap does not cross a page)
;
; Known only from the code.
KeyMapCarry:
  INC H
; This entry point is used by the routine at ScanKeys.
l_851D:
  LD A,(HL)               ; A = the character
  POP HL
  RET

; The key at each half row and bit as ScanKeys finds it: B N M 1 3 H J K L 2 Y
; U I O P 6-0 5-1 T-Q G-A V-Z 4
;
; 40 characters, the half rows $7F, $BF, $DF, $EF, $F7, $FB, $FD, $FE, bit 4 to
; bit 0. Codes 1 SYMBOL SHIFT, 2 ENTER, 3 SPACE, 4 CAPS SHIFT.
KeyMap:
  INCBIN "res/texts/keymap.bin",$0000,40

; WaitKey with no timeout (B = $FF)
;
; Witness: L1 8 (c1, ctl, tech-brake-bend, tech-cheat, tech-land-wheelie,
; tech-ramp-wheelie, twoplayer).
GetKey:
  LD B,$FF

; Wait for every key up, then for a key: NC and A = its character ($40 on the
; Kempston method: any stick bit, a direction or fire, at port $001F), or C
; after BC units
;
; In: BC = the timeout (B = $FF: none). Each unit is a DelayBC($9A13) and a
; scan; the count is WaitCount. Used by the menus, the credits, the lap table,
; between turns.
;
; Witness: L1 307 (c1, ctl, m128, names, stages, tech-brake-bend, tech-cheat,
; tech-land-wheelie, tech-ramp-wheelie, twoplayer).
WaitKey:
  LD (WaitCount),BC
l_854E:
  LD BC,$9A13
  CALL DelayBC
  CALL ScanKeys
  INC A
  JR NZ,l_8566
  LD A,(ControlMethod)
  DEC A
  JR NZ,WaitPress
  IN A,($1F)
  AND $1F
  JR Z,WaitPress
l_8566:
  LD BC,(WaitCount)
  LD A,B
  INC A
  JR Z,l_854E
  DEC BC
  LD A,B
  OR C
  JR NZ,WaitKey

; The keys stayed down for the whole timeout: C
;
; Known only from the code: every wait in the recordings saw the keys released
; in time.
WaitKeyTimeout:
  SCF
  RET
; This entry point is used by the routine at WaitKey.
WaitPress:
  LD BC,$9A13             ; wait for a key
  CALL DelayBC
  CALL ScanKeys
  CP $FF
  CCF
  RET NC
  LD A,(ControlMethod)
  DEC A
  JR NZ,l_858F
  IN A,($1F)
  AND $1F
  LD A,$40
  RET NZ
l_858F:
  LD BC,(WaitCount)
  LD A,B
  INC A
  JR Z,WaitPress
  DEC BC
  LD A,B
  OR C
  LD (WaitCount),BC
  JR NZ,WaitPress
  SCF
  RET

; About 2 s: 5 x 53 846 turns of DEC BC / LD A,B / OR C / JR NZ
;
; Witness: L1 5 (c1, names, stages, twoplayer).
Delay:
  LD D,$05
l_85A4:
  LD BC,$D256
l_85A7:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_85A7
  DEC D
  JR NZ,l_85A4
  RET

; D = the controls: 0 throttle, 1 wheelie, 2 left, 3 right, 4 brakes, 5 pause
; (H), 6 reset (R)
;
; Seven tests: LD A,half row / IN A,(port) / AND mask / JR NZ (JR Z for the
; Kempston) / SET n,D. The first five are patched by PatchControls (the image
; holds method 3's SINCLAIR LEFT tests, half row $F7).
;
; Recorded: c1, ctl: every method; ctl's Kempston run sets DE = $1F28.
;
; Witness: L1 10165 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
ReadControls:
  LD D,$00
  LD A,$F7
  IN A,($FE)
  AND $08
  JR NZ,l_85BC
  SET 0,D
l_85BC:
  LD A,$F7
  IN A,($FE)
  AND $04
  JR NZ,l_85C6
  SET 1,D
l_85C6:
  LD A,$F7
  IN A,($FE)
  AND $01
  JR NZ,l_85D0
  SET 2,D
l_85D0:
  LD A,$F7
  IN A,($FE)
  AND $02
  JR NZ,l_85DA
  SET 3,D
l_85DA:
  LD A,$F7
  IN A,($FE)
  AND $10
  JR NZ,TestPause
  SET 4,D
TestPause:
  LD A,$BF                ; H
  IN A,($FE)
  AND $10
  JR NZ,TestReset
  SET 5,D
TestReset:
  LD A,$FB                ; R
  IN A,($FE)
  AND $08
  JR NZ,l_85F8
  SET 6,D
l_85F8:
  RET

; Highlight item A of menu HL, colour E, until SPACE or fire picks it (NC, A)
; or about 22 s pass (C)
;
; HL = a list: the count, then four bytes an item (line, column, attribute,
; length), the PrintList layout of the same texts. The item's bar (column - 1,
; length + 2) gets attribute (attr AND $47) OR E (PaintAttrs; RestoreBar puts
; it back). WaitKey $04E2: SPACE (3) or ReadControls = brakes only picks;
; THROTTLE moves up (MenuUp), any other key down, wrapping.
;
; Recorded: c1, m128, ctl.
;
; Witness: L1 29 (c1, ctl, m128, twoplayer).
MenuSelect:
  LD (KeyItem),A
  LD A,E
  LD (MenuColour+$0001),A
; This entry point is used by the routine at MenuUp.
l_8600:
  PUSH HL
  INC HL
  LD DE,$0004
  LD A,(KeyItem)
  AND A
  JR Z,l_860F
l_860B:
  ADD HL,DE
  DEC A
  JR NZ,l_860B
l_860F:
  LD C,(HL)
  INC HL
  LD B,(HL)
  DEC B
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC D
  INC D
  LD (RestoreBar+$0001),BC
  LD (RestoreBar+$0004),DE
  LD A,E
  AND $47
MenuColour:
  OR $00                  ; OR n: n = the highlight colour E
  LD E,A
  CALL PaintAttrs
  POP HL
  LD BC,$04E2
  CALL WaitKey
  RET C
  CP $03
  JR Z,l_863C
  CALL ReadControls
  LD A,D
  XOR $10
l_863C:
  LD A,(KeyItem)
  RET Z
  BIT 0,D
  JR Z,MenuDown

; THROTTLE: the item before (wrapping)
;
; Known only from the code: the recordings moved down only.
MenuUp:
  SUB $01
  JR NC,l_8650
  ADD A,(HL)
  JR l_8650
; This entry point is used by the routine at MenuSelect.
MenuDown:
  INC A                   ; the next item, wrapping to 0
  CP (HL)
  JR C,l_8650
  XOR A
l_8650:
  LD (KeyItem),A
  CALL RestoreBar
  JR l_8600

; PaintAttrs with the bar's saved BC and DE (the operands at $8659 and $865C,
; written by MenuSelect)
;
; Witness: L1 61 (c1, ctl, m128, twoplayer).
RestoreBar:
  LD BC,$0000
  LD DE,$0000

; D attributes E from column B on pixel line C
;
; Witness: L1 1943 (c1, ctl, m128, twoplayer).
PaintAttrs:
  CALL SetAttr
  INC B
  DEC D
  JR NZ,PaintAttrs
  RET

; Border black; a wipe: 32 times every pixel line and attribute row one byte to
; the left
;
; Witness: L1 28 (c1, ctl, m128, names, stages, twoplayer).
ClearScreen:
  XOR A
  OUT ($FE),A
  LD A,$20
l_866B:
  EX AF,AF'
  LD IX,RowTable
  LD HL,$5801
  LD DE,$5800
  EXX
  LD B,$18
l_8679:
  PUSH BC
  EXX
  LD B,$08
l_867D:
  EXX
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD L,E
  LD H,D
  INC L
  LD A,$01
  CALL Copy32
  DEC DE
  LD (DE),A
  INC IX
  INC IX
  EXX
  DJNZ l_867D
  LD C,$1F
  LDIR
  LD (DE),A
  INC HL
  INC DE
  EXX
  POP BC
  DJNZ l_8679
  EX AF,AF'
  DEC A
  JR NZ,l_866B
  RET

; DJNZ / DEC C: B x C turns
;
; Witness: L1 119007349 (c1, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).
DelayBC:
  DJNZ DelayBC
  DEC C
  JR NZ,DelayBC
  RET

; Print IX's list of texts from HL: the count, then (line, column, attribute,
; length) each
;
; Witness: L1 72 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
PrintList:
  LD B,(IX+$00)
  INC IX
l_86B0:
  PUSH BC
  LD C,(IX+$00)
  LD B,(IX+$01)
  LD E,(IX+$02)
  LD D,(IX+$03)
  CALL PrintString
  LD DE,$0004
  ADD IX,DE
  POP BC
  DJNZ l_86B0
  RET

; Add the 7 digits ending at HL to Score (ASCII, leading blanks), then
; DrawScore; not in a demo
;
; The digits are 0-9 values (ScoreAdd's, $7C3D-$7C41, and the time bonus); the
; score's leading zeros (up to six) become blanks.
;
; Witness: L1 4850 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
AddScore:
  LD A,(DemoMode)
  AND A
  RET NZ
  LD BC,$0700
  LD DE,Score+$0006
l_86D4:
  LD A,(DE)
  CP $20
  JR NZ,l_86DB
  LD A,$30
l_86DB:
  ADD A,(HL)
  ADD A,C
  LD C,$00
  CP $3A
  JR C,l_86E6
  INC C
  SUB $0A
l_86E6:
  LD (DE),A
  DEC HL
  DEC DE
  DJNZ l_86D4
  LD HL,Score
  LD A,$30
  LD B,$06
l_86F2:
  CP (HL)
  JR NZ,DrawScore
  LD (HL),$20
  INC HL
  DJNZ l_86F2

; Score's 7 characters at column 25, line 8, attribute $69
;
; Witness: L1 4572 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawScore:
  LD HL,Score
  LD BC,$1908
  LD DE,$0769
  JP PrintString

; The time at HL (seconds BCD with $60 a minute, hundredths BCD) into
; TimeText's digits
;
; Witness: L1 31 (c1, names, stages).
FormatTime:
  LD D,(HL)
  INC HL
  LD A,(HL)
  CALL BcdToText
  LD (TimeText+$0005),HL
  LD A,D
  SUB $60
  LD L,$30
  JR C,l_8718
  LD D,A
  INC L
l_8718:
  LD A,L
  LD (TimeText),A
  LD A,D
  CALL BcdToText
  LD (TimeText+$0002),HL
  RET

; A (BCD) to two digit characters: L the tens, H the units
;
; Witness: L1 62 (c1, names, stages).
BcdToText:
  LD H,A
  RRA
  RRA
  RRA
  RRA
  AND $0F
  ADD A,$30
  LD L,A
  LD A,H
  AND $0F
  ADD A,$30
  LD H,A
  RET

; TOTAL, RECORD, PLAYER (the lap table), LAPTIME (the stage end's line) and the
; time text that FormatTime fills
LapTexts:
  INCBIN "res/texts/lap.bin",$0000,25
TimeText:
  INCBIN "res/texts/lap.bin",$0019,7
