; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The control and level menus, the cheat flags, the falling letters
;
; The menus are drawn in the view buffer with the font as cells (FontCellsMode): each text falls into place letter by
; letter (DropText: BuildLetters makes a record a letter, MoveLetters makes them fall and bounce, ComposeLetter puts
; them into spare cells), until all have stopped or a number key is pressed; a key during the fall stops the
; animation, and the following texts are printed at once. ReadMenuKey takes the number keys 0-5 (5 only with level 5
; open), a key only once per press.
;
; The control menu (ControlMenu) lists START GAME and the four control methods; a small Rick slides to the method
; chosen. The level menu (LevelMenu) lists levels 1-4 and level 5 when Level5Open is set (four levels done in one
; game, MainLoopPause).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7F44

; The level menu: levels 1-4, level 5 when open; Level = the key pressed
;
; FontCellsMode, $7A61, $8985, $8977, then the texts with DropText (A = $FF the
; first time, then what it returns): "PRESS KEY TO" at row $70 column 10,
; "START  LEVEL" at $78/10, the four levels at rows $90, $A0, $B0, $C0 column
; 2, and "THE FAT GUYS HEADQUARTERS" at $D0 only when Level5Open is set. A key
; 1-5 pressed during the fall is taken at once; else LevelMenuWait waits for
; one. Level = the key; LevelCellsMode's code inline; return to StartGame.
;
; Evidence: 11 runs in 10 builds; the menu after side A lists levels 1-4
; (load-l5's first frames before its POKE was added, stage 1), load-l5 with the
; POKE $8065 = $FF shows level 5 and plays it.
;
; Witness: L1 54 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
LevelMenu:
  CALL FontCellsMode
  CALL ClearScreen
  CALL ClearRedraw
  CALL BlankView
  LD A,$FF
  LD HL,LevelMenuText
  LD DE,$700A             ; D = the row in pixels, E = the column
  CALL DropText
  LD HL,StartLevelText
  LD DE,$780A
  CALL DropText
  LD HL,Level1Name
  LD DE,$9002
  CALL DropText
  LD HL,Level2Name
  LD DE,$A002
  CALL DropText
  LD HL,Level3Name
  LD DE,$B002
  CALL DropText
  LD HL,Level4Name
  LD DE,$C002
  CALL DropText
  LD C,A
  LD A,(Level5Open)
  AND A
  LD A,C
  JP Z,LevelMenuKey
  LD HL,Level5Name        ; the fifth level: only with Level5Open
  LD DE,$D002
  CALL DropText
  JP LevelMenuKey

; Wait for a level key
;
; ReadMenuKey until it gives 1-5 (0 and none go round again).
;
; Evidence: 82 475 runs in 2 builds (rzx-l1-00000-poke 37 177, rzx-l5-full 45
; 298: the RZX states sit in the level menu).
;
; Witness: L1 164950 (rzx-l1-00000-poke, rzx-l5-full).
LevelMenuWait:
  CALL ReadMenuKey
; This entry point is used by the routine at LevelMenu.
LevelMenuKey:
  CP $FF                  ; FF (none) or 0: wait; 1-5: the level
  JP Z,LevelMenuAgain
  AND A
  JP Z,LevelMenuAgain
  LD (Level),A
  JP LevelMenuDone
LevelMenuAgain:
  JP LevelMenuWait        ; no level key yet
LevelMenuDone:
  LD HL,CellGraphics             ; the level cells back (as LevelCellsMode)
  LD (DrawLevelCellBase+$0001),HL
  LD (ComposeCellBase+$0001),HL
  LD A,$FA
  LD (ComposeCellFrontTest),A
  LD HL,ComposeCellSkip
  LD (ComposeCellFrontTest+$0001),HL
  RET

; The level menu's texts (the digits stored 4 higher: "5" shows as 1)
;
; Each text ends with $FF. Read by DropText from LevelMenu; the level names are
; Rick Dangerous 2's five levels.
LevelMenuText:
  INCBIN "res/texts/level-menu.bin",$0000,13
StartLevelText:
  INCBIN "res/texts/level-menu.bin",$000D,13
Level1Name:
  INCBIN "res/texts/level-menu.bin",$001A,20
Level2Name:
  INCBIN "res/texts/level-menu.bin",$002E,30
Level3Name:
  INCBIN "res/texts/level-menu.bin",$004C,29
Level4Name:
  INCBIN "res/texts/level-menu.bin",$0069,24
Level5Name:
  INCBIN "res/texts/level-menu.bin",$0081,29

; $FF: level 5 is open in the level menu
;
; Set to $FF by MainLoopPause ($7DA6) when the fourth level of a game is done;
; never cleared, so it stays open for the next games until a reset. Read by
; LevelMenu (the fifth line), ScanNumberKeys (the key 5), MainLoopPause (level
; 4 done: level 5 or the CONGRATULATIONS end) and CheatExitsKeys. 0 in the
; image. Evidence: rzx-l4-20000-poke runs $7DA6 once; load-l5 sets it by POKE.
Level5Open:
  DEFB $00

; Not 0: lives, ammunition and detonators are not used up
;
; Toggled by the chord C+S+3 in MainLoop (CheatInfiniteKeys); read by $8A26 (a
; life lost), $9593 (a bullet), $9B27 (a detonator), $95ED and $96B4. 0 in the
; image; no recording sets it.
CheatInfinite:
  DEFB $00

; $FF: a section exit test passes (set by the chord SPACE+N+ENTER+J+Y with
; level 5 open)
;
; Set by CheatExitsKeys, read by $8993 (bit 7, at $89D9); never cleared. 0 in
; the image; no recording sets it.
CheatExits:
  DEFB $00

; A number key 0-5 once per press: A = the key, or $FF
;
; ScanNumberKeys; none: MenuKeyHeld = 0 and A = $FF. A key while MenuKeyHeld is
; set (still held from the last time): A = $FF. Else MenuKeyHeld = $FF and A =
; the key. Out: A.
;
; Evidence: 89 436 runs in 13 builds (callers LevelMenuWait, ControlMenuLoop,
; DropTextWait).
;
; Witness: L1 198492 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ReadMenuKey:
  CALL ScanNumberKeys
  CP $FF
  JP NZ,MenuKeyWasHeld
  XOR A
  LD (MenuKeyHeld),A
  DEC A
  RET
MenuKeyWasHeld:
  EX AF,AF'               ; a key: new only when MenuKeyHeld is clear
  LD A,(MenuKeyHeld)
  AND A
  JP Z,MenuKeyNew
  LD A,$FF
  RET
MenuKeyNew:
  DEC A                   ; a new press
  LD (MenuKeyHeld),A
  EX AF,AF'
  RET

; The number key held: A = 0-5 (5 only with level 5 open), else $FF
;
; Tests 0 ($71F9), 1-4 ($7201-$7219) and, when Level5Open is set, 5 ($7221);
; the first found is returned in A, with Z. None: A = $FF.
;
; Evidence: 89 436 runs in 13 builds.
;
; Witness: L1 198492 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ScanNumberKeys:
  CALL TestKey0
  LD A,$00
  RET Z
  CALL TestKey1
  LD A,$01
  RET Z
  CALL TestKey2
  LD A,$02
  RET Z
  CALL TestKey3
  LD A,$03
  RET Z
  CALL TestKey4
  LD A,$04
  RET Z
  LD A,(Level5Open)
  AND A
  JP Z,NumberKeyNone
  CALL TestKey5
  LD A,$05
  RET Z
NumberKeyNone:
  LD A,$FF                ; no key: $FF
  RET

; The control menu: START GAME or a control method; returns when 0 is pressed
;
; FontCellsMode, tune 0 ($7AAD), MenuKeyHeld = $FF (a key held from before does
; not count). The texts fall: "RICK DANGEROUS II" at row $68 column 7, "0 START
; GAME" at $80/9, "1   KEYBOARD", "2   KEMPSTON", "3   CURSOR", "4 SINCLAIR" at
; $98, $A8, $B8, $C8 (the digits stored 4 higher); the key 0 during any of them
; returns at once. Then the pointer: Rick's record gets the sprite at Sprites +
; 12 x 128 ($9BAF), x 0 ($9BAC), y $2A ($9BAD), $9BB1, $9B95-$9B97 = 0, and
; ControlMenuLoop runs.
;
; Evidence: 4 runs in 3 builds (c1 1, controls-keyboard 1, rzx-l5-full 2); c1
; chooses 2, 3, 4, 1 and 0 in turn (tests/inputs/c1.txt), the menu from about
; frame 15 000 (WALKTHROUGH 1).
;
; Witness: L1 42 (controls-keyboard, rzx-l5-full, c1, c48, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
ControlMenu:
  CALL FontCellsMode
  XOR A
  CALL StartTune
  LD A,$FF
  LD (MenuKeyHeld),A
  LD HL,TitleText
  LD DE,$6807             ; the title: row $68, column 7
  CALL DropText
  AND A
  RET Z
  LD HL,ControlMenuText
  LD DE,$8009             ; START GAME: row $80, column 9
  CALL DropText
  AND A
  RET Z
  LD HL,KeyboardText
  LD DE,$9809
  CALL DropText
  AND A
  RET Z
  LD HL,KempstonText
  LD DE,$A809
  CALL DropText
  AND A
  RET Z
  LD HL,CursorText
  LD DE,$B809
  CALL DropText
  AND A
  RET Z
  LD HL,SinclairText
  LD DE,$C809
  CALL DropText
  AND A
  RET Z
  PUSH AF
  LD HL,Sprites+12*128      ; the pointer: Rick's record gets sprite 12
  LD (RickSprite),HL
  LD A,$00
  LD (RickX),A
  LD HL,$002A
  LD (RickY),HL
  XOR A
  LD (RickFacing),A
  LD (RickDy),A
  LD (RickYFrac),A
  LD A,$00
  LD (RickDy+$0001),A
  POP AF
  AND A
  RET Z

; Choose the control method, move the pointer, until 0
;
; ReadMenuKey: 0 returns (start the game); 1-4 set the method $7252 = key - 1
; (0 keyboard, 1 Kempston, 2 cursor, 3 Sinclair). Then the composed cells from
; 2 ($77B0), MoveMenuRick toward the method's row ($94 + 16 x method), the
; sprite drawn ($7329, IX = $9BAB), a frame wait, the cells redrawn, again.
;
; Evidence: 2230 runs in 10 builds; c1 sets each method in turn, controls-*
; each one (stage 1).
;
; Witness: L1 8392 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ControlMenuLoop:
  CALL ReadMenuKey
  AND A
  RET Z
  CP $05
  JP NC,ControlMenuPointer
  DEC A
  LD (ControlMethod),A
ControlMenuPointer:
  LD A,$02                ; the pointer to the method's row
  LD (SpareCount),A
  LD A,(ControlMethod)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$94
  LD C,A
  CALL MoveMenuRick
  LD IX,RickRecord
  CALL ComposeSprite
  LD C,$01
  CALL WaitFrames
  CALL DrawChangedCells
  JP ControlMenuLoop

; The control menu's texts (the digits stored 4 higher) and the title
;
; Each text ends with $FF. Read by DropText from ControlMenu.
ControlMenuText:
  INCBIN "res/texts/control-menu.bin",$0000,15
KeyboardText:
  INCBIN "res/texts/control-menu.bin",$000F,13
KempstonText:
  INCBIN "res/texts/control-menu.bin",$001C,13
CursorText:
  INCBIN "res/texts/control-menu.bin",$0029,11
SinclairText:
  INCBIN "res/texts/control-menu.bin",$0034,15
TitleText:
  INCBIN "res/texts/control-menu.bin",$0043,18

; $FF while a menu key is held: ReadMenuKey takes a key once per press
;
; Written by ReadMenuKey (0 when no key, $FF on a new key) and ControlMenu ($FF
; at the start).
MenuKeyHeld:
  DEFB $00

  ORG $81E6

; Move every falling letter one frame and compose it into the view
;
; The composed cells from 2 ($77B0); for each 8-byte record from $7B8F until
; $FF: MoveLetter, ComposeLetter.
;
; Evidence: 4731 runs in 11 builds (from DropTextFrame).
;
; Witness: L1 25150 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MoveLetters:
  LD A,$02
  LD (SpareCount),A
  LD IX,Entry

; The next letter record
;
; Ends at a record whose +0 is $FF; IX + 8.
;
; Evidence: the loop of MoveLetters (reads $7B8F-$7C4F).
;
; Witness: L1 330002 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
MoveLettersLoop:
  LD A,(IX+$00)
  CP $FF
  RET Z
  CALL MoveLetter
  CALL ComposeLetter
  LD BC,$0008
  ADD IX,BC
  JP MoveLettersLoop

; One letter's fall: delay, gravity, a bounce at its row
;
; IX = the record (BuildLetters): +0 glyph, +1 column, +2/+3 y (+2 the pixel
; row, +3 the fraction), +4/+5 the speed (+4 low), +6 the delay in frames, +7
; the row it stops at. While the delay is not 0 it counts down (the letters
; start one after the other, 6 frames apart). Then speed + $60 (the gravity), y
; + speed; past the row: y = the row, speed = - speed / 2 (a bounce), 0 when
; its high byte is 0 or $FF (the letter stops).
;
; Evidence: 57 671 runs in 12 builds.
;
; Witness: L1 304850 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
MoveLetter:
  LD A,(IX+$06)
  AND A
  JP Z,LetterFall
  DEC (IX+$06)
  RET NZ
LetterFall:
  LD E,(IX+$04)           ; speed + gravity, y + speed
  LD D,(IX+$05)
  LD HL,$0060
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  LD E,(IX+$03)
  LD D,(IX+$02)
  LD A,(IX+$07)
  ADD HL,DE
  CP H
  JP NC,LetterStoreY
  LD H,A
  LD L,$00
  LD A,(IX+$04)
  CPL
  LD E,A
  LD A,(IX+$05)
  CPL
  LD D,A
  INC DE
  SRA D
  RR E
  LD A,D
  AND A
  JP Z,LetterStop
  CP $FF
  JP NZ,LetterBounce
LetterStop:
  LD DE,$0000             ; too slow to bounce: speed 0
LetterBounce:
  LD (IX+$04),E           ; the new speed
  LD (IX+$05),D
LetterStoreY:
  LD (IX+$02),H           ; y stored
  LD (IX+$03),L
  RET

; One falling-letter record per character of a text, from $7B8F
;
; HL = the text ($FF the end), D = the row it falls to (pixels), E = the
; column. Each non-space character: +0 the glyph (code - $34), +1 the column,
; +2/+3 y = $4000 (row 64), +4/+5 speed = $0900 (9 pixels a frame down), +6 the
; delay C (1, then 6 more for every character, spaces too), +7 the row D. The
; record after the last gets $FF at +0. Out: HL on the text's $FF.
;
; Evidence: 41 runs in 11 builds (writes $7B8F-$7C4F).
;
; Witness: L1 226 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
BuildLetters:
  LD IX,Entry
  LD C,$01
BuildLettersLoop:
  LD A,(HL)               ; the next character
  LD (IX+$00),A
  CP $FF
  RET Z
  INC HL
  CP $20
  JP Z,BuildLettersNext
  SUB $34
  LD (IX+$00),A
  LD (IX+$01),E
  LD (IX+$02),$40
  LD (IX+$03),$00
  LD (IX+$04),$00
  LD (IX+$05),$09
  LD (IX+$06),C
  LD (IX+$07),D
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
BuildLettersNext:
  INC E                   ; column + 1, delay + 6
  LD A,C
  ADD A,$06
  LD C,A
  JP BuildLettersLoop

; Put a text's glyph numbers into the view buffer, marked for redraw
;
; HL = the text, DE = the view buffer address ($6B00 + 32 x row + column). Each
; non-space character: the glyph number (code - $34) at DE and 1 at DE - $500
; (the old buffer at $6600, so the drawer sees a change).
;
; Evidence: 97 runs in 12 builds (writes $67A7-$695D and $6CA7-$6E5D).
;
; Witness: L1 639 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
PutTextCells:
  LD C,$FB
PutTextCellsLoop:
  LD A,(HL)               ; the next character
  CP $FF
  RET Z
  CP $20
  JP Z,PutTextCellsNext
  SUB $34
  LD (DE),A
  LD A,D
  ADD A,C
  LD D,A
  LD A,$01
  LD (DE),A
  LD A,D
  SUB C
  LD D,A
PutTextCellsNext:
  INC HL                  ; the next column
  INC DE
  JP PutTextCellsLoop

; Show a text in the view: A = $FF letters fall into place, else at once
;
; HL = the text, D = the row in pixels, E = the column, A = $FF to animate.
; Stores the text and its view buffer address ($6B00 + 4 x (D AND $F8) + E)
; into DropTextFinish's operands. A = $FF: BuildLetters, then DropTextWait's
; frames until every letter has stopped or a number key is pressed. Then (and
; at once when A is not $FF) DropTextFinish puts the text into the view buffer
; and redraws it. Out: A = the key pressed during the fall (ReadMenuKey: 0-5),
; $FF when none, or A as given when not animated; HL on the text's $FF (the end
; pointer of the last animated text). The callers chain A: after a key the
; later texts of the menu are put at once, and the key is the menu's choice.
;
; Evidence: 97 runs in 11 builds (callers: LevelMenu, ControlMenu, GameOver
; $7E8B, ShowEndTextLoop $8777).
;
; Witness: L1 639 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
DropText:
  PUSH AF
  LD (DropTextFinish+$0002),HL
  PUSH DE
  PUSH HL
  LD A,D
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD D,$6B
  ADD HL,DE
  LD (DropTextFinish+$0005),HL
  POP HL
  POP DE
  POP AF
  CP $FF
  JP NZ,DropTextFinish
  CALL BuildLetters
  LD (DropTextFinish+$000F),HL
; This entry point is used by the routine at DropTextWait.
DropTextFrame:
  CALL MoveLetters        ; one frame of the fall

; Wait a frame, redraw, stop at a key or when every letter has stopped
;
; Frame wait (C = 1), the cells redrawn ($76D4), ReadMenuKey: a key goes to
; DropTextFinish with A = the key. Else, a letter with a delay or a speed left
; (+6 or +5 not 0) means another frame (DropTextFrame); all still:
; DropTextFinish.
;
; Evidence: 4732 runs in 12 builds.
;
; Witness: L1 25152 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DropTextWait:
  LD C,$01
  CALL WaitFrames
  CALL DrawChangedCells
  CALL ReadMenuKey
  CP $FF
  JP NZ,DropTextFinish
  LD BC,$0008
  LD IX,Entry
DropTextCheckLoop:
  LD A,(IX+$00)           ; is any letter still moving?
  CP $FF
  JP Z,DropTextFinish
  LD A,(IX+$06)
  OR (IX+$05)
  JP NZ,DropTextFrame
  ADD IX,BC
  JP DropTextCheckLoop
; This entry point is used by the routine at DropText.
DropTextFinish:
  PUSH AF                 ; the text put in the view buffer (self-modified
                          ; operands: the text, the buffer address, HL out)
  LD HL,$0000
  LD DE,$0000
  CALL PutTextCells
  CALL DrawChangedCells
  POP AF
  LD HL,$0000
  RET

; Compose a falling letter into spare cells of the view
;
; The next spare cell is $5DF0 + 8 x $77B0 (the composed cells $5DE8 + 8n). The
; view cell under the letter (row (y AND $F8) / 8, its column) and, when y is
; not on a cell boundary, the one below are copied into spare cells by $7755
; (which puts the spare cells' numbers into the view buffer). Then the glyph
; $7080 + 8 x (+0) is ORed in from the row y AND 7 of the first spare cell on
; (eight rows over the two cells).
;
; Evidence: 57 671 runs in 12 builds (reads the glyphs $7080-$71AF, writes
; $5E00-$5F0E).
;
; Witness: L1 304850 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
ComposeLetter:
  LD A,(SpareCount)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,SpareCells+8
  ADD HL,BC
  EX DE,HL
  PUSH DE
  LD A,(IX+$02)
  LD H,$00
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD C,(IX+$01)
  LD B,$6B
  ADD HL,BC
  CALL ComposeCell
  LD A,(IX+$02)
  AND $07
  JP Z,ComposeLetterRows
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
ComposeLetterRows:
  POP HL                  ; the glyph ORed in at the letter's row
  LD A,(IX+$02)
  AND $07
  LD C,A
  LD B,$00
  ADD HL,BC
  EX DE,HL
  LD A,(IX+$00)
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,Glyphs
  ADD HL,BC
  LD B,$08
ComposeLetterLoop:
  LD A,(DE)               ; one of the eight rows
  OR (HL)
  LD (DE),A
  INC L
  INC E
  DJNZ ComposeLetterLoop
  RET

  ORG $83CE

; The control menu's Rick: y toward the row C, x swinging about 24
;
; y ($9BAD) moves 2 toward C. The x speed $9B95 (a word) gets + $30 while x
; ($9BAC) is below $18, - $30 when it is at or above; x and its fraction
; ($9B97) + speed: Rick sways sideways.
;
; Evidence: 2219 runs in 10 builds (from ControlMenuPointer).
;
; Witness: L1 8338 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MoveMenuRick:
  LD A,(RickY)
  CP C
  LD BC,$0000
  JP Z,MenuRickMoveY
  LD BC,-2
  JP NC,MenuRickMoveY
  LD BC,$0002
MenuRickMoveY:
  LD HL,(RickY)           ; y + the step
  ADD HL,BC
  LD (RickY),HL
  LD HL,(RickDy)
  LD A,(RickX)
  CP $18
  LD BC,-$30
  JP NC,MenuRickMoveX
  LD BC,$0030
MenuRickMoveX:
  ADD HL,BC               ; x + speed
  LD (RickDy),HL
  LD D,A
  LD A,(RickYFrac)
  LD E,A
  ADD HL,DE
  LD A,H
  LD (RickX),A
  LD A,L
  LD (RickYFrac),A
  RET
